import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/rewards/presentation/providers/reward_provider.dart';
import 'package:botleji/features/rewards/presentation/providers/reward_shop_provider.dart';
import 'package:botleji/features/rewards/presentation/widgets/tier_upgrade_popup.dart';
import 'package:botleji/features/rewards/presentation/widgets/reward_shop_widget.dart';
import 'package:botleji/features/rewards/presentation/widgets/order_history_widget.dart';
import 'package:botleji/features/rewards/data/models/reward_models.dart';
import 'package:botleji/features/rewards/data/services/reward_service.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/l10n/app_localizations.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  RewardStats? _previousStats;
  late TabController _tabController;
  bool _hasRefreshedOnVisible = false;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    
    // Only refresh reward data if it's not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rewardStats = ref.read(rewardStatsProvider);
      if (rewardStats.hasError) {
        ref.invalidate(rewardStatsProvider);
      }
      
      // Refresh when screen first becomes visible
      _refreshDataIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshDataIfNeeded();
    }
  }

  void _refreshDataIfNeeded() {
    // Refresh if we haven't refreshed yet, or if it's been more than 30 seconds
    final now = DateTime.now();
    if (!_hasRefreshedOnVisible || 
        _lastRefreshTime == null || 
        now.difference(_lastRefreshTime!).inSeconds > 30) {
      _hasRefreshedOnVisible = true;
      _lastRefreshTime = now;
      
      // Refresh user data to get latest reward history and points
      final authNotifier = ref.read(authNotifierProvider.notifier);
      authNotifier.refreshUserData().catchError((e) {
        debugPrint('Error refreshing user data on rewards screen: $e');
      });
      
      // Refresh reward stats
      ref.invalidate(rewardStatsProvider);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible (tab is tapped)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDataIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userMode = ref.watch(userModeControllerProvider);
    final rewardStats = ref.watch(rewardStatsProvider);
    final tierUpgradeState = ref.watch(tierUpgradeProvider);
    
    // Check for tier upgrades
    rewardStats.whenData((stats) {
      if (_previousStats != null && _previousStats!.currentTier < stats.currentTier) {
        // Tier upgrade detected!
        ref.read(tierUpgradeProvider.notifier).showTierUpgrade(
          TierInfo(
            tier: stats.currentTier,
            name: _getTierName(stats.currentTier),
            dropsRequired: _getDropsRequired(stats.currentTier),
            pointsPerDrop: _getPointsPerDrop(stats.currentTier),
          ),
          stats.currentPoints - (_previousStats?.currentPoints ?? 0),
        );
      }
      _previousStats = stats;
    });
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Main content
          userMode.when(
            data: (mode) => rewardStats.when(
              data: (stats) => _buildRewardsContent(context, mode, stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load rewards',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(rewardStatsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading user mode: $error'),
            ),
          ),
          
          // Tier Upgrade Popup
          if (tierUpgradeState.showPopup && tierUpgradeState.newTier != null)
            TierUpgradePopup(
              newTier: tierUpgradeState.newTier!,
              pointsAwarded: tierUpgradeState.pointsAwarded ?? 0,
              onDismiss: () {
                ref.read(tierUpgradeProvider.notifier).dismissPopup();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRewardsContent(BuildContext context, UserMode mode, RewardStats stats) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(rewardStatsProvider);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        slivers: [
          // Points & Tier Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPointsCard(context, stats),
                  const SizedBox(height: 16),
                  _buildTierCard(context, mode, stats),
                  const SizedBox(height: 16),
                  _buildInfoCard(context, mode),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          
          // Reward Shop Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildRewardShopHeader(context),
            ),
          ),
          
          // Shop Items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildRewardShop(context, mode),
            ),
          ),
          
          // Order History Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: const Color(0xFF00695C),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).orderHistory,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00695C),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Order History Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildOrderHistoryContent(context),
            ),
          ),
          
          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabContent(BuildContext context, UserMode mode) {
    if (_tabController.index == 0) {
      // Shop Tab
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildRewardShopHeader(context),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildRewardShop(context, mode),
          ),
        ),
      ];
    } else {
      // Order History Tab
      return [
        const SliverFillRemaining(
          child: OrderHistoryWidget(),
        ),
      ];
    }
  }

  Widget _buildPointsCard(BuildContext context, RewardStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00695C),
            Color(0xFF004D40),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context).yourPoints,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showRewardHistory(context),
                        child: Icon(
                          Icons.history,
                          color: Colors.white.withOpacity(0.8),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stats.currentPoints.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(stats),
        ],
      ),
    );
  }

  Widget _buildProgressBar(RewardStats stats) {
    final currentPoints = stats.currentPoints;
    final nextTierPoints = _getNextTierPoints(stats.currentTier);
    final progress = nextTierPoints > 0 ? currentPoints / nextTierPoints : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).progressToNextTier,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              AppLocalizations.of(context).pointsToGo((nextTierPoints - currentPoints).clamp(0, nextTierPoints)),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTierCard(BuildContext context, UserMode mode, RewardStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00695C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Color(0xFF00695C),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTierName(stats.currentTier),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00695C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mode == UserMode.collector 
                    ? AppLocalizations.of(context).earnPointsPerDropCollected(_getPointsPerDrop(stats.currentTier))
                    : AppLocalizations.of(context).earnPointsWhenDropsCollected((_getPointsPerDrop(stats.currentTier) * 0.5).round()),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Info Icon
          GestureDetector(
            onTap: () => _showTiersInfoDialog(context, mode, stats),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, UserMode mode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).howRewardsWork,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mode == UserMode.collector
              ? AppLocalizations.of(context).howRewardsWorkCollector
              : AppLocalizations.of(context).howRewardsWorkHousehold,
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardShopHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.store,
          color: const Color(0xFF00695C),
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          AppLocalizations.of(context).rewardShop,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00695C),
          ),
        ),
        const Spacer(),
        Consumer(
          builder: (context, ref, child) {
            return IconButton(
              onPressed: () => ref.read(rewardShopProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              color: const Color(0xFF00695C),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRewardShop(BuildContext context, UserMode mode) {
    return const RewardShopWidget();
  }

  // Helper methods for tier calculations
  String _getTierName(int tier) {
    final l10n = AppLocalizations.of(context);
    switch (tier) {
      case 1:
        return l10n.bronzeCollector;
      case 2:
        return l10n.silverCollector;
      case 3:
        return l10n.goldCollector;
      case 4:
        return l10n.platinumCollector;
      case 5:
        return l10n.diamondCollector;
      default:
        return 'Tier $tier';
    }
  }

  int _getPointsPerDrop(int tier) {
    switch (tier) {
      case 1:
        return 10;
      case 2:
        return 20;
      case 3:
        return 30;
      case 4:
        return 40;
      case 5:
        return 50;
      default:
        return 10;
    }
  }

  int _getDropsRequired(int tier) {
    switch (tier) {
      case 1:
        return 0;
      case 2:
        return 1000;
      case 3:
        return 2000;
      case 4:
        return 3000;
      case 5:
        return 4000;
      default:
        return 0;
    }
  }

  int _getNextTierPoints(int currentTier) {
    switch (currentTier) {
      case 1:
        return 1000;
      case 2:
        return 2000;
      case 3:
        return 3000;
      case 4:
        return 4000;
      case 5:
        return 5000; // Max tier
      default:
        return 1000;
    }
  }

  void _showTiersInfoDialog(BuildContext context, UserMode mode, RewardStats stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFF00695C)),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).tierSystem),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current Tier Highlight
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00695C)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFF00695C), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context).current}: ${_getTierName(stats.currentTier)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00695C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // All Tiers List
              ...List.generate(5, (index) {
                final tier = index + 1;
                final isCurrentTier = tier == stats.currentTier;
                final isUnlocked = tier <= stats.currentTier;
                final dropsRequired = _getDropsRequired(tier);
                final pointsPerDrop = _getPointsPerDrop(tier);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentTier 
                        ? const Color(0xFF00695C).withOpacity(0.1)
                        : isUnlocked 
                            ? Colors.green[50]
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrentTier 
                          ? const Color(0xFF00695C)
                          : isUnlocked 
                              ? Colors.green
                              : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCurrentTier 
                            ? Icons.star
                            : isUnlocked 
                                ? Icons.check_circle
                                : Icons.lock,
                        color: isCurrentTier 
                            ? const Color(0xFF00695C)
                            : isUnlocked 
                                ? Colors.green
                                : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTierName(tier),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCurrentTier 
                                    ? const Color(0xFF00695C)
                                    : isUnlocked 
                                        ? Colors.green[700]
                                        : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mode == UserMode.collector
                                ? '${AppLocalizations.of(context).earnPointsPerDrop(pointsPerDrop)} • ${dropsRequired == 0 ? AppLocalizations.of(context).start : AppLocalizations.of(context).dropsRequired(dropsRequired)}'
                                : '${AppLocalizations.of(context).earnPointsPerDrop((pointsPerDrop * 0.5).round())} • ${dropsRequired == 0 ? AppLocalizations.of(context).start : AppLocalizations.of(context).dropsRequired(dropsRequired)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authNotifierProvider);
        final user = authState.value;
        
        if (user == null) {
          return const Center(
            child: Text('Please log in to view order history'),
          );
        }
        
        return FutureBuilder<List<RewardRedemption>>(
          future: RewardService.getUserRedemptions(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error loading orders: ${snapshot.error}'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Trigger rebuild
                        setState(() {});
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            final redemptions = snapshot.data ?? [];
            
            if (redemptions.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context).noOrdersYet, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context).yourOrderHistoryWillAppearHere, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            
            return Column(
              children: redemptions.map((redemption) => 
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                redemption.rewardItemName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(redemption.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(context, redemption.status),
                                style: TextStyle(
                                  color: _getStatusColor(redemption.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${AppLocalizations.of(context).pointsLabel} ${redemption.pointsSpent}'),
                        if (redemption.selectedSize != null) ...[
                          const SizedBox(height: 4),
                          Text('${AppLocalizations.of(context).sizeLabel} ${redemption.selectedSize} (${redemption.sizeType})'),
                        ],
                        const SizedBox(height: 4),
                        Text('${AppLocalizations.of(context).orderDateLabel} ${_formatDate(redemption.createdAt)}'),
                      ],
                    ),
                  ),
                ),
              ).toList(),
            );
          },
        );
      },
    );
  }

  String _getStatusText(BuildContext context, RedemptionStatus status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case RedemptionStatus.pending:
        return l10n.pending;
      case RedemptionStatus.approved:
        return l10n.approved;
      case RedemptionStatus.processing:
        return l10n.processing;
      case RedemptionStatus.shipped:
        return l10n.shipped;
      case RedemptionStatus.delivered:
        return l10n.delivered;
      case RedemptionStatus.cancelled:
        return l10n.cancelled;
      case RedemptionStatus.rejected:
        return l10n.rejected;
    }
  }

  Color _getStatusColor(RedemptionStatus status) {
    switch (status) {
      case RedemptionStatus.pending:
        return Colors.orange;
      case RedemptionStatus.approved:
        return Colors.blue;
      case RedemptionStatus.processing:
        return Colors.purple;
      case RedemptionStatus.shipped:
        return Colors.indigo;
      case RedemptionStatus.delivered:
        return Colors.green;
      case RedemptionStatus.cancelled:
        return Colors.grey;
      case RedemptionStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showRewardHistory(BuildContext context) async {
    final userMode = ref.read(userModeControllerProvider).valueOrNull;
    
    if (userMode == null) {
      return;
    }
    
    // Use existing user data without refreshing (to avoid page refresh effect)
    final userData = ref.read(authNotifierProvider).value;
    if (userData == null) {
      return;
    }
    
    // Get reward history from user data
    final rewardHistory = userData.rewardHistory ?? [];
    
    debugPrint('📊 _showRewardHistory - User data: ${userData.id}');
    debugPrint('📊 _showRewardHistory - Reward history from user data: ${rewardHistory.length} items');
    debugPrint('📊 _showRewardHistory - Reward history type: ${rewardHistory.runtimeType}');
    debugPrint('📊 _showRewardHistory - Raw reward history: $rewardHistory');
    if (rewardHistory.isNotEmpty) {
      debugPrint('📊 _showRewardHistory - First item: ${rewardHistory.first}');
      debugPrint('📊 _showRewardHistory - First item keys: ${rewardHistory.first.keys}');
    }
    
    // Filter based on current mode
    // Fetch entire reward history, then filter to show only rewards relevant to current mode
    // Also filter out null/empty objects
    List<Map<String, dynamic>> filteredHistory;
    if (userMode == UserMode.household) {
      // Household mode: show only rewards with type === "household_drop_collected"
      filteredHistory = rewardHistory.where((item) {
        // Skip null/empty objects
        if (item.isEmpty || item['dropId'] == null) {
          debugPrint('📊 Household mode - skipping empty/null item: $item');
          return false;
        }
        final hasType = item['type'] == 'household_drop_collected';
        debugPrint('📊 Household mode - item type: ${item['type']}, dropId: ${item['dropId']}, matches: $hasType');
        return hasType;
      }).toList();
    } else {
      // Collector mode: show only rewards without type field (collector rewards don't have type)
      filteredHistory = rewardHistory.where((item) {
        // Skip null/empty objects
        if (item.isEmpty || item['dropId'] == null) {
          debugPrint('📊 Collector mode - skipping empty/null item: $item');
          return false;
        }
        // Collector rewards: no type field, or type is null/empty string
        final hasNoType = item['type'] == null || item['type'] == '';
        debugPrint('📊 Collector mode - item type: ${item['type']}, dropId: ${item['dropId']}, matches: $hasNoType');
        return hasNoType;
      }).toList();
    }
    
    debugPrint('📊 Filtered history for ${userMode.name} mode: ${filteredHistory.length} items (from ${rewardHistory.length} total)');
    
    // Sort by date (newest first)
    filteredHistory.sort((a, b) {
      final dateA = a['collectedAt'] != null 
          ? (a['collectedAt'] is String 
              ? DateTime.parse(a['collectedAt']) 
              : a['collectedAt'] is DateTime
                  ? a['collectedAt'] as DateTime
                  : DateTime.now())
          : DateTime(1970);
      final dateB = b['collectedAt'] != null
          ? (b['collectedAt'] is String
              ? DateTime.parse(b['collectedAt'])
              : b['collectedAt'] is DateTime
                  ? b['collectedAt'] as DateTime
                  : DateTime.now())
          : DateTime(1970);
      return dateB.compareTo(dateA);
    });
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).rewardHistory,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // History list
              if (filteredHistory.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).noRewardHistoryYet,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = filteredHistory[index];
                      final pointsAwarded = item['pointsAwarded'] ?? 0;
                      final tier = item['tier'] ?? 1;
                      final tierUpgraded = item['tierUpgraded'] ?? false;
                      final collectedAt = item['collectedAt'] != null
                          ? (item['collectedAt'] is String
                              ? DateTime.parse(item['collectedAt'])
                              : item['collectedAt'] as DateTime)
                          : DateTime.now();
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00695C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.stars,
                                color: Color(0xFF00695C),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '+$pointsAwarded ${AppLocalizations.of(context).points}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00695C),
                                        ),
                                      ),
                                      if (tierUpgraded) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context).tierUp,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${AppLocalizations.of(context).tier} $tier • ${_formatDate(collectedAt)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
