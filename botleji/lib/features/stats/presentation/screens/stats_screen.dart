import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/stats/controllers/stats_controller.dart';
import 'package:botleji/features/stats/data/models/collector_stats.dart';
import 'package:botleji/features/stats/data/models/user_drop_stats.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/history/presentation/controllers/history_controller.dart';
import 'package:botleji/core/navigation/app_routes.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'package:botleji/features/drops/controllers/drops_controller.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/collection/presentation/providers/collection_attempts_provider.dart';
import 'package:botleji/features/collection/data/models/collection_attempt.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  TimeRange _selectedTimeRange = TimeRange.allTime;

  @override
  void initState() {
    super.initState();
    // Load history data for the stats screen - only today's interactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyController = ref.read(historyControllerProvider.notifier);
      historyController.loadHistory(status: null, timeRange: 'today');
      
      // Only load user drops if in household mode
      final userMode = ref.read(userModeControllerProvider);
      userMode.whenData((mode) {
        if (mode == UserMode.household) {
          print('🔍 Stats: Auth state: ${ref.read(authNotifierProvider)}');
          ref.read(authNotifierProvider).whenData((user) {
            print('🔍 Stats: User: $user');
            if (user?.id != null) {
              print('🔍 Stats: Loading drops for household user: ${user!.id}');
              final dropsController = ref.read(dropsControllerProvider.notifier);
              dropsController.loadUserDrops(user!.id!);
            } else {
              print('🔍 Stats: No user ID found');
            }
          });
        } else {
          print('🔍 Stats: In collector mode, not loading user drops');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userMode = ref.watch(userModeControllerProvider);
    
    return userMode.when(
      data: (mode) {
        if (mode == UserMode.household) {
          return _buildHouseholdStats();
        } else {
          return _buildCollectorStats();
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildHouseholdStats() {
    final userDropStatsState = ref.watch(userDropStatsProvider(_selectedTimeRange.name));
    
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(userDropStatsProvider(_selectedTimeRange.name).notifier).refresh();
      },
      child: userDropStatsState.when(
        data: (stats) => _buildHouseholdStatsContent(stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error.toString()),
      ),
    );
  }

  Widget _buildHouseholdStatsContent(UserDropStats stats) {
    // Use stats from the API
    final totalDrops = stats.total;
    final pendingDrops = stats.pending;
    final collectedDrops = stats.collected;
    final flaggedDrops = stats.flagged ?? 0;
    final staleDrops = stats.stale ?? 0;
    final censoredDrops = stats.censored ?? 0;
    
    // Get drops data to calculate actual bottle and can counts
    final dropsState = ref.watch(dropsControllerProvider);
    final drops = dropsState.maybeWhen(
      data: (drops) => drops,
      orElse: () => <Drop>[],
    );
    
    // Calculate actual bottle and can counts from collected drops only
    int totalBottles = 0;
    int totalCans = 0;
    for (final drop in drops) {
      if (drop.status == DropStatus.collected) {
        totalBottles += drop.numberOfBottles;
        totalCans += drop.numberOfCans;
      }
    }
    final totalItems = totalBottles + totalCans;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with reload button
          Row(
            children: [
              Text(
                'My Stats',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00695C),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.read(userDropStatsProvider(_selectedTimeRange.name).notifier).refresh();
                },
                color: const Color(0xFF00695C),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Time range selector
          _buildHouseholdTimeRangeSelector(),
          const SizedBox(height: 24),
          
          // Overview section - empty for now
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text(
                'Overview section\n(To be designed)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Status breakdown
          _buildHouseholdStatusBreakdown(
            pending: pendingDrops,
            collected: collectedDrops,
            flagged: flaggedDrops,
            stale: staleDrops,
            censored: censoredDrops,
            total: totalDrops,
          ),
          const SizedBox(height: 24),
          
          // Recycling impact
          _buildHouseholdRecyclingImpact(
            totalBottles: totalBottles,
            totalCans: totalCans,
            totalItems: totalItems,
          ),
          const SizedBox(height: 24),
          
          // Recent drops
          _buildHouseholdRecentDropsSection(),
          
          // Bottom padding to prevent bottom nav bar interference
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 100, // Bottom nav height + extra padding
          ),
        ],
      ),
    );
  }

  List<Drop> _filterDropsByTimeRange(List<Drop> drops) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedTimeRange) {
      case TimeRange.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case TimeRange.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case TimeRange.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case TimeRange.allTime:
        return _filterActiveDrops(drops); // Filter active drops for all time
    }
    
    final timeFilteredDrops = drops.where((drop) => drop.createdAt.isAfter(startDate)).toList();
    return _filterActiveDrops(timeFilteredDrops);
  }

  List<Drop> _filterActiveDrops(List<Drop> drops) {
    // Only show active drops: not flagged, not censored, not stale
    return drops.where((drop) {
      return !drop.isSuspicious && 
             !drop.isCensored && 
             drop.status != DropStatus.stale;
    }).toList();
  }

  Widget _buildTimeRangeSelector() {
    return GestureDetector(
      onTap: _showTimeRangeDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              _selectedTimeRange.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showTimeRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Time Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TimeRange.values.map((timeRange) {
            return ListTile(
              title: Text(timeRange.displayName),
              trailing: _selectedTimeRange == timeRange
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  _selectedTimeRange = timeRange;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHouseholdTimeRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Range',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TimeRange.values.map((timeRange) {
              final isSelected = _selectedTimeRange == timeRange;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(timeRange.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTimeRange = timeRange;
                    });
                    
                    // Refresh drops when time range changes (only for household mode)
                    final userMode = ref.read(userModeControllerProvider);
                    userMode.whenData((mode) {
                      if (mode == UserMode.household) {
                        ref.read(authNotifierProvider).whenData((user) {
                          if (user?.id != null) {
                            final dropsController = ref.read(dropsControllerProvider.notifier);
                            dropsController.loadUserDrops(user!.id!);
                          }
                        });
                      }
                    });
                  },
                  selectedColor: const Color(0xFF00695C).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF00695C),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF00695C) : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }



  Widget _buildHouseholdStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdDropsOverviewCard({
    required int totalDrops,
    required int pendingDrops,
    required int collectedDrops,
    required int flaggedDrops,
    required int staleDrops,
    required int censoredDrops,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_location, color: Color(0xFF00695C), size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            totalDrops.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00695C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Drops',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          // Status breakdown
          _buildStatusRow('Active', pendingDrops, totalDrops, Colors.orange),
          const SizedBox(height: 8),
          _buildStatusRow('Collected', collectedDrops, totalDrops, Colors.green),
          const SizedBox(height: 8),
          _buildStatusRow('Flagged', flaggedDrops, totalDrops, Colors.red),
          const SizedBox(height: 8),
          _buildStatusRow('Stale', staleDrops, totalDrops, Colors.brown),
          const SizedBox(height: 8),
          _buildStatusRow('Censored', censoredDrops, totalDrops, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildHouseholdRecyclingOverviewCard({
    required int totalBottles,
    required int totalCans,
    required int totalItems,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.recycling, color: Colors.green, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatLargeNumber(totalItems),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Items Recycled',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          // Item breakdown
          _buildItemCountWithCustomIcon(
            'Bottles',
            totalBottles,
            'assets/icons/water-bottle.png',
          ),
          const SizedBox(height: 8),
          _buildItemCountWithCustomIcon(
            'Cans',
            totalCans,
            'assets/icons/can.png',
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdStatusBreakdown({
    required int pending,
    required int collected,
    required int flagged,
    required int stale,
    required int censored,
    required int total,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drop Status',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00695C),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatusRow('Pending', pending, total, Colors.orange),
              const SizedBox(height: 8),
              _buildStatusRow('Collected', collected, total, Colors.green),
              const SizedBox(height: 8),
              _buildStatusRow('Flagged', flagged, total, Colors.red),
              const SizedBox(height: 8),
              _buildStatusRow('Stale', stale, total, Colors.brown),
              const SizedBox(height: 8),
              _buildStatusRow('Censored', censored, total, Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String status, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            status,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '(${percentage.toStringAsFixed(1)}%)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHouseholdRecyclingImpact({
    required int totalBottles,
    required int totalCans,
    required int totalItems,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recycling Impact',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00695C),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/icons/water-bottle.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plastic Bottles',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Recycled ${_formatLargeNumber(totalBottles)} bottles',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatLargeNumber(totalBottles),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Image.asset(
                    'assets/icons/can.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aluminum Cans',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Recycled ${_formatLargeNumber(totalCans)} cans',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatLargeNumber(totalCans),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.recycling, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Total Items Recycled',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _formatLargeNumber(totalItems),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHouseholdRecentDrops(List<Drop> drops) {
    // Sort drops by creation date (most recent first) and take the first 3
    final sortedDrops = List<Drop>.from(drops)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentDrops = sortedDrops.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Drops',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00695C),
              ),
            ),
            TextButton(
              onPressed: () {
                print('Stats: View All button pressed for recent drops');
                Navigator.pushNamed(context, AppRoutes.history);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentDrops.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.add_location_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No drops yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first drop to start recycling',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: recentDrops.map((drop) => _buildRecentDropCard(drop)).toList(),
          ),
      ],
    );
  }

  Widget _buildRecentDropCard(Drop drop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drop image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: drop.imageUrl.isNotEmpty
                  ? Image.network(
                      drop.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 24,
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Drop details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${drop.numberOfBottles + drop.numberOfCans} items',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  drop.bottleType.name.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(drop.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(drop.status.name).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              drop.status.name.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(drop.status.name),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectorStats() {
    final statsAsync = ref.watch(collectorStatsProvider(_selectedTimeRange.apiValue));

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh both stats and history
        await ref.read(collectorStatsProvider(_selectedTimeRange.apiValue).notifier).refresh();
        await ref.read(historyControllerProvider.notifier).refresh();
      },
      child: statsAsync.when(
        data: (stats) => _buildStatsContent(stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error.toString()),
      ),
    );
  }

  Widget _buildStatsContent(CollectorStats stats) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with reload button
          Row(
            children: [
              Text(
                'My Stats',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00695C), // Green color
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Refresh both stats and history
                  ref.read(collectorStatsProvider(_selectedTimeRange.apiValue).notifier).refresh();
                  ref.read(historyControllerProvider.notifier).refresh();
                },
                color: const Color(0xFF00695C), // Green color
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeRangeSelector(),
          const SizedBox(height: 24),
          _buildOverviewCards(stats),
          const SizedBox(height: 24),
          _buildPerformanceMetrics(stats),
          const SizedBox(height: 24),
          _buildCancellationReasons(stats),
          const SizedBox(height: 24),
          _buildCollectionHistory(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(CollectorStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00695C), // Green color
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Accepted',
              stats.accepted.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Collected',
              stats.collected.toString(),
              Icons.recycling,
              Colors.blue,
            ),
            _buildStatCard(
              'Cancelled',
              stats.cancelled.toString(),
              Icons.cancel,
              Colors.red,
            ),
            _buildStatCard(
              'Expired',
              stats.expired.toString(),
              Icons.timer_off,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics(CollectorStats stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00695C), // Green color
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Collection Rate',
              '${stats.collectionRate.toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Avg Collection Time',
              _formatDuration(stats.averageCollectionTime),
              Icons.access_time,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCancellationReasons(CollectorStats stats) {
    if (stats.cancellationReasons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancellation Reasons',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00695C), // Green color
              ),
            ),
            const SizedBox(height: 16),
            ...stats.cancellationReasons.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatCancellationReason(entry.key),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.value.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionHistory() {
    final recentCollectionsAsync = ref.watch(recentCompletedCollectionsProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Collections',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00695C), // Green color
                  ),
                ),
                TextButton(
                  onPressed: () {
                    print('Stats: View All button pressed for collection history');
                    Navigator.pushNamed(context, AppRoutes.history);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            recentCollectionsAsync.when(
              data: (collections) {
                if (collections.isEmpty) {
                  return const Center(
                    child: Text(
                      'No completed collections yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                
                // Show the 3 most recent collections
                return Column(
                  children: collections.take(3).map((attempt) {
                    return _buildRecentCollectionAttemptCard(attempt);
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading collections: ${error.toString()}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCollectionAttemptCard(CollectionAttempt attempt) {
    final dropSnapshot = attempt.dropSnapshot;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drop image placeholder (since DropSnapshot doesn't have imageUrl)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.recycling,
              color: Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Collection details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item counts
                Row(
                  children: [
                    if (dropSnapshot.numberOfBottles > 0) ...[
                      Image.asset(
                        'assets/icons/water-bottle.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dropSnapshot.numberOfBottles}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (dropSnapshot.numberOfCans > 0) ...[
                      Image.asset(
                        'assets/icons/can.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dropSnapshot.numberOfCans}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      'Total: ${dropSnapshot.totalItems}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Bottle type and special instructions
                Row(
                  children: [
                    Text(
                      dropSnapshot.bottleType.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (dropSnapshot.notes?.contains('leave outside') == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Leave Outside',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                
                // Collection date and duration
                Row(
                  children: [
                    Text(
                      'Collected ${_formatDate(attempt.completedAt ?? attempt.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (attempt.durationMinutes != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${attempt.durationDisplay})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'COLLECTED',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCollectionCard(CollectorInteraction interaction) {
    final dropoff = interaction.dropoff;
    
    if (dropoff == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drop image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: dropoff.imageUrl != null && dropoff.imageUrl!.isNotEmpty
                  ? Image.network(
                      dropoff.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 24,
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Collection details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item counts
                Row(
                  children: [
                    if (dropoff.numberOfBottles > 0) ...[
                      Image.asset(
                        'assets/icons/water-bottle.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dropoff.numberOfBottles}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (dropoff.numberOfCans > 0) ...[
                      Image.asset(
                        'assets/icons/can.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dropoff.numberOfCans}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      'Total: ${dropoff.numberOfBottles + dropoff.numberOfCans}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Bottle type and special instructions
                Row(
                  children: [
                    Text(
                      dropoff.bottleType.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (dropoff.leaveOutside) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Leave Outside',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                
                // Collection date
                Text(
                  'Collected ${_formatDate(interaction.interactionTime)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'COLLECTED',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(CollectorInteraction interaction) {
    final dropoff = interaction.dropoff;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and date
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(interaction.interactionType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(interaction.interactionType),
                        color: _getStatusColor(interaction.interactionType),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(interaction.interactionType),
                        style: TextStyle(
                          color: _getStatusColor(interaction.interactionType),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(interaction.interactionTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Drop details
          if (dropoff != null) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image and basic info row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drop image
                      if (dropoff.imageUrl != null && dropoff.imageUrl!.isNotEmpty)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              dropoff.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 32,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                          ),)
                      else
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                      
                      const SizedBox(width: 12),
                      
                      // Drop information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Item counts
                            Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                if (dropoff.numberOfBottles > 0) ...[
                                  _buildItemCountWithCustomIcon('Bottles', dropoff.numberOfBottles, 'assets/icons/water-bottle.png'),
                                ],
                                if (dropoff.numberOfCans > 0) ...[
                                  _buildItemCountWithCustomIcon('Cans', dropoff.numberOfCans, 'assets/icons/can.png'),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Bottle type
                            _buildDetailRow('Type', dropoff.bottleType),
                            
                            // Status
                            _buildDetailRow('Status', dropoff.status),
                            
                            // Special instructions
                            if (dropoff.leaveOutside || dropoff.isSuspicious) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (dropoff.leaveOutside)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Leave Outside',
                                        style: TextStyle(
                                          color: Colors.orange[700],
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  if (dropoff.isSuspicious)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Suspicious',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Notes and additional info
                  if (dropoff.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 16,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dropoff.notes!,
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Interaction notes
                  if (interaction.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.comment,
                            size: 16,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              interaction.notes!,
                              style: TextStyle(
                                color: Colors.green[800],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Cancellation reason
                  if (interaction.cancellationReason?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cancel,
                            size: 16,
                            color: Colors.red[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cancelled: ${interaction.cancellationReason}',
                              style: TextStyle(
                                color: Colors.red[800],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),);
  }


  Widget _buildItemCountWithCustomIcon(String label, int count, String iconPath) {
    // Format large numbers with K, M suffixes
    String formattedCount = _formatLargeNumber(count);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: 12,
            height: 12,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$formattedCount $label',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLargeNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String interactionType) {
    switch (interactionType) {
      case 'collected':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'accepted':
        return Colors.blue;
      case 'expired':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String interactionType) {
    switch (interactionType) {
      case 'collected':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'accepted':
        return Icons.assignment_turned_in;
      case 'expired':
        return Icons.timer_off;
      default:
        return Icons.history;
    }
  }

  String _getStatusText(String interactionType) {
    switch (interactionType) {
      case 'collected':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'accepted':
        return 'Accepted';
      case 'expired':
        return 'Expired';
      default:
        return 'Activity';
    }
  }

  String _formatDate(DateTime date) {
    // Convert UTC to local timezone if needed
    final localDate = date.isUtc ? date.toLocal() : date;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(localDate.year, localDate.month, localDate.day);
    
    // Format time as HH:mm
    final timeString = '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    
    if (dateOnly == today) {
      return 'Today at $timeString';
    } else if (dateOnly == yesterday) {
      return 'Yesterday at $timeString';
    } else {
      final difference = today.difference(dateOnly).inDays;
      
      if (difference < 7) {
        // Show day name for recent dates
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final dayName = dayNames[localDate.weekday - 1];
        return '$dayName at $timeString';
      } else if (difference < 30) {
        // Show "X days ago" for older dates
        return '${difference}d ago at $timeString';
      } else {
        // Show full date for very old dates
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthName = monthNames[localDate.month - 1];
        return '$monthName ${localDate.day} at $timeString';
      }
    }
  }

Widget _buildErrorWidget(String error) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.red,
        ),
        const SizedBox(height: 16),
        Text(
          'Error loading stats',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            ref
                .read(collectorStatsProvider(_selectedTimeRange.apiValue).notifier)
                .refresh();
          },
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}


  String _formatDuration(int milliseconds) {
    if (milliseconds == 0) return 'N/A';
    
    final minutes = milliseconds ~/ (1000 * 60);
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }

  String _formatCancellationReason(String reason) {
    switch (reason) {
      case 'noAccess':
        return 'No Access';
      case 'notFound':
        return 'Not Found';
      case 'alreadyCollected':
        return 'Already Collected';
      case 'wrongLocation':
        return 'Wrong Location';
      case 'unsafe':
        return 'Unsafe Location';
      case 'other':
        return 'Other';
      default:
        return reason;
    }
  }

  // Helper to group interactions by dropoffId and create pairs
  List<List<CollectorInteraction>> _groupInteractionsByDrop(List<CollectorInteraction> interactions) {
    final Map<String, List<CollectorInteraction>> grouped = {};
    
    print('🔍 Grouping ${interactions.length} interactions...');
    
    for (final interaction in interactions) {
      // Try to get a unique identifier for the drop
      String dropKey = '';
      
      // First try to use the dropoff object's id if available (this is the most reliable)
      if (interaction.dropoff?.id.isNotEmpty == true) {
        dropKey = interaction.dropoff!.id;
        print('  📍 Using dropoff.id: $dropKey');
      } else if (interaction.dropoffId.isNotEmpty) {
        // Check if dropoffId is actually a string ID or if it's an object
        dropKey = interaction.dropoffId;
        print('  📍 Using interaction.dropoffId: $dropKey');
      } else {
        // If no dropoffId, use the interaction id as fallback
        dropKey = interaction.id;
        print('  📍 Using interaction.id as fallback: $dropKey');
      }
      
      if (dropKey.isNotEmpty) {
        grouped.putIfAbsent(dropKey, () => []).add(interaction);
        print('  ✅ Added interaction ${interaction.interactionType} to group $dropKey');
      } else {
        print('  ❌ No dropKey found for interaction ${interaction.id}');
      }
    }
    
    print('🔍 Created ${grouped.length} groups:');
    grouped.forEach((key, interactions) {
      print('  📦 Group $key: ${interactions.length} interactions');
      interactions.forEach((interaction) {
        print('    - ${interaction.interactionType} at ${interaction.interactionTime}');
      });
    });
    
    // Sort each group by interaction time
    for (final group in grouped.values) {
      group.sort((a, b) => a.interactionTime.compareTo(b.interactionTime));
    }
    
    // Now create pairs from each group
    List<List<CollectorInteraction>> pairs = [];
    
    for (final group in grouped.values) {
      // Find all accepted interactions
      final acceptedInteractions = group.where((i) => i.interactionType == 'accepted').toList();
      
      for (int i = 0; i < acceptedInteractions.length; i++) {
        final accepted = acceptedInteractions[i];
        
        // Find the next interaction after this accepted one
        CollectorInteraction? nextInteraction;
        
        // Look for expired, collected, or cancelled interactions that come after this accepted one
        final subsequentInteractions = group.where((interaction) {
          return (interaction.interactionType == 'expired' || 
                  interaction.interactionType == 'collected' || 
                  interaction.interactionType == 'cancelled') &&
                 interaction.interactionTime.isAfter(accepted.interactionTime);
        }).toList();
        
        if (subsequentInteractions.isNotEmpty) {
          // Sort by time and take the first one (closest to accepted)
          subsequentInteractions.sort((a, b) => a.interactionTime.compareTo(b.interactionTime));
          nextInteraction = subsequentInteractions.first;
        }
        
        // Create a pair: [accepted, nextInteraction] (if nextInteraction exists)
        if (nextInteraction != null) {
          pairs.add([accepted, nextInteraction]);
          print('  🔗 Created pair: ${accepted.interactionType} → ${nextInteraction.interactionType}');
        } else {
          // If no subsequent interaction, just show the accepted one
          pairs.add([accepted]);
          print('  🔗 Created single: ${accepted.interactionType}');
        }
      }
    }
    
    // Sort pairs by the most recent interaction time (descending order)
    pairs.sort((a, b) => b.last.interactionTime.compareTo(a.last.interactionTime));
    
    print('🔍 Final result: ${pairs.length} pairs');
    
    return pairs;
  }

  // Helper to build a timeline for a single drop
  
Widget _buildDropTimeline(List<CollectorInteraction> interactions) {
  final firstInteraction = interactions.first;

  return Card(
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropoff details
          Row(
            children: [
              // Drop image
              if (firstInteraction.dropoff?.imageUrl != null &&
                  firstInteraction.dropoff!.imageUrl!.isNotEmpty)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      firstInteraction.dropoff!.imageUrl!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 60,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 60,
                  ),
                ),

              // Map placeholder
              if (firstInteraction.dropoff?.location != null) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Image.network(
                            _getStaticMapUrl(LatLng(
                              firstInteraction.dropoff!.location.coordinates[1],
                              firstInteraction.dropoff!.location.coordinates[0],
                            )),
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.map,
                                    size: 24,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                          // Pin overlay
                          Center(
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Drop info (bottles, cans, total, date, special instructions)
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (firstInteraction.dropoff?.numberOfBottles != null &&
                  firstInteraction.dropoff!.numberOfBottles > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icons/water-bottle.png', width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatLargeNumber(firstInteraction.dropoff!.numberOfBottles),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[600],
                          ),
                    ),
                  ],
                ),
              if (firstInteraction.dropoff?.numberOfCans != null &&
                  firstInteraction.dropoff!.numberOfCans > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icons/can.png', width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatLargeNumber(firstInteraction.dropoff!.numberOfCans),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[600],
                          ),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total ${_formatLargeNumber((firstInteraction.dropoff?.numberOfBottles ?? 0) + (firstInteraction.dropoff?.numberOfCans ?? 0))}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[600],
                        ),
                  ),
                ],
              ),
              Text(
                _formatDate(firstInteraction.dropoff!.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
              ),
              if (firstInteraction.dropoff?.leaveOutside == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Leave Outside',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Timeline steps
          Column(
            children: interactions.asMap().entries.map((entry) {
              final index = entry.key;
              final interaction = entry.value;
              final isLast = index == interactions.length - 1;
              final isAccepted = interaction.interactionType == 'accepted';
              final isCollected = interaction.interactionType == 'collected';
              final isCancelled = interaction.interactionType == 'cancelled';
              final isExpired = interaction.interactionType == 'expired';

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCollected
                                ? Colors.green
                                : isCancelled
                                    ? Colors.red
                                    : isExpired
                                        ? Colors.purple
                                        : isAccepted
                                            ? Colors.blue
                                            : Colors.grey,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(interaction.interactionTime),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusText(interaction.interactionType),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isCollected
                                      ? Colors.green
                                      : isCancelled
                                          ? Colors.red
                                          : isExpired
                                              ? Colors.purple
                                              : isAccepted
                                                  ? Colors.blue
                                                  : Colors.grey,
                                ),
                          ),
                          if (interaction.notes?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              interaction.notes!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ),
  );
}






  String _getStaticMapUrl(LatLng location) {
    // Use the same API key that works in the drops tab
    const apiKey = "AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E";
    const baseUrl = 'https://maps.googleapis.com/maps/api/staticmap';
    
    // Use the same format as the drops tab
    final parameters = {
      'center': '${location.latitude},${location.longitude}',
      'zoom': '16',
      'size': '600x400',
      'maptype': 'roadmap',
      'key': apiKey,
    };
    final queryParameters = Uri.parse(baseUrl).replace(queryParameters: parameters);
    return queryParameters.toString();
  }

  Widget _buildHouseholdRecentDropsSection() {
  // Watch the drops controller to get the user's drops
  final dropsState = ref.watch(dropsControllerProvider);

  print('🔍 Stats: Drops state: $dropsState');

  return dropsState.when(
    data: (drops) {
      // Filter drops by the selected time range
      final filteredDrops = _filterDropsByTimeRange(drops);
      print('🔍 Stats: Total drops: ${drops.length}, Filtered drops: ${filteredDrops.length}, Time range: ${_selectedTimeRange.name}');
      return _buildHouseholdRecentDrops(filteredDrops);
    },
    loading: () {
      print('🔍 Stats: Drops loading...');
      return const Center(child: CircularProgressIndicator());
    },
    error: (error, stack) {
      print('🔍 Stats: Drops error: $error');
      return Center(
        child: Text('Error loading drops: $error'),
      );
    },
  );
}

} 
