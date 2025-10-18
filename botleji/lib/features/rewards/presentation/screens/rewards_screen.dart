import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/rewards/presentation/providers/reward_provider.dart';
import 'package:botleji/features/rewards/presentation/widgets/tier_upgrade_popup.dart';
import 'package:botleji/features/rewards/data/models/reward_models.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  RewardStats? _previousStats;

  @override
  void initState() {
    super.initState();
    // Refresh reward data every time the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(rewardStatsProvider);
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
        // Refresh reward data when user pulls down
        ref.invalidate(rewardStatsProvider);
        await Future.delayed(const Duration(milliseconds: 500)); // Small delay for better UX
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
                    _buildRewardShopHeader(context),
                    const SizedBox(height: 16),
                  ],
                ),
            ),
          ),

          // Reward Shop Items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildRewardShop(context, mode),
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
                  const Text(
                    'Your Points',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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
            const Text(
              'Progress to Next Tier',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              '${(nextTierPoints - currentPoints).clamp(0, nextTierPoints)} points to go',
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
                    ? 'Earn ${_getPointsPerDrop(stats.currentTier)} points per drop collected'
                    : 'Earn ${(_getPointsPerDrop(stats.currentTier) * 0.5).round()} points when your drops are collected',
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
                'How Rewards Work',
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
              ? '• Collect drops to earn points\n• Higher tiers = more points per drop\n• Use points in the reward shop\n• Track your progress and achievements'
              : '• Create drops to contribute to recycling\n• Earn points when collectors pick up your drops\n• Higher tiers = more points per collected drop\n• Use points in the reward shop',
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
          'Reward Shop',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00695C),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardShop(BuildContext context, UserMode mode) {
    return Column(
      children: [
        Text(
          mode == UserMode.collector
            ? 'Collector Rewards - Coming Soon!'
            : 'Household Rewards - Coming Soon!',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.store_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Reward Shop Coming Soon',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Exciting rewards and items will be available soon!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods for tier calculations
  String _getTierName(int tier) {
    switch (tier) {
      case 1:
        return 'Bronze Collector';
      case 2:
        return 'Silver Collector';
      case 3:
        return 'Gold Collector';
      case 4:
        return 'Platinum Collector';
      case 5:
        return 'Diamond Collector';
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
            const Text('Tier System'),
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
                      'Current: ${_getTierName(stats.currentTier)}',
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
                                ? 'Earn $pointsPerDrop points per drop • ${dropsRequired == 0 ? "Start" : "$dropsRequired drops required"}'
                                : 'Earn ${(pointsPerDrop * 0.5).round()} points per drop • ${dropsRequired == 0 ? "Start" : "$dropsRequired drops required"}',
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
