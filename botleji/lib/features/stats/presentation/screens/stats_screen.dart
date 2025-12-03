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
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/collection/presentation/providers/collection_attempts_provider.dart';
import 'package:botleji/features/collection/data/models/collection_attempt.dart';
import 'package:botleji/features/stats/presentation/widgets/stats_chart_carousel.dart';
import 'package:botleji/features/stats/presentation/widgets/household_stats_chart_carousel.dart';
import 'package:botleji/core/services/timezone_service.dart';
import 'package:botleji/features/drops/domain/utils/drop_value_calculator.dart';
import 'package:botleji/l10n/app_localizations.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  TimeRange _selectedTimeRange = TimeRange.week;
  
  String _getLocalizedTimeRange(TimeRange timeRange) {
    final l10n = AppLocalizations.of(context);
    switch (timeRange) {
      case TimeRange.week:
        return l10n.thisWeek;
      case TimeRange.month:
        return l10n.thisMonth;
      case TimeRange.year:
        return l10n.thisYear;
      case TimeRange.allTime:
        return l10n.allTime;
    }
  }

  @override
  void initState() {
    super.initState();
    // Load history data for the stats screen - only today's interactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyController = ref.read(historyControllerProvider.notifier);
      historyController.loadHistory(status: null, timeRange: 'today');
      
      // Refresh collection attempts for charts - ensure this happens first
      final attemptsController = ref.read(collectionAttemptsProvider.notifier);
      attemptsController.refresh();
      
      // Only load user drops if in household mode
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
                AppLocalizations.of(context).myStats,
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
          
          HouseholdStatsChartCarousel(
            drops: drops,
            timeRange: _selectedTimeRange.apiValue,
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
            drops: drops,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).timeRange,
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
                  label: Text(_getLocalizedTimeRange(timeRange)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      _selectedTimeRange = timeRange;
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

  Widget _buildHouseholdTimeRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).timeRange,
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
                  label: Text(_getLocalizedTimeRange(timeRange)),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
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
            AppLocalizations.of(context).totalDrops,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // Status breakdown
          _buildStatusRow(AppLocalizations.of(context).active, pendingDrops, totalDrops, Colors.orange),
          const SizedBox(height: 8),
          _buildStatusRow(AppLocalizations.of(context).collected, collectedDrops, totalDrops, Colors.green),
          const SizedBox(height: 8),
          _buildStatusRow(AppLocalizations.of(context).flagged, flaggedDrops, totalDrops, Colors.red),
          const SizedBox(height: 8),
          _buildStatusRow(AppLocalizations.of(context).stale, staleDrops, totalDrops, Colors.brown),
          const SizedBox(height: 8),
          _buildStatusRow(AppLocalizations.of(context).censored, censoredDrops, totalDrops, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildHouseholdRecyclingOverviewCard({
    required int totalBottles,
    required int totalCans,
    required int totalItems,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
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
            AppLocalizations.of(context).totalItemsRecycled,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    required List<Drop> drops,
  }) {
    final theme = Theme.of(context);
    
    // Calculate total estimated value from all drops
    double totalEstimatedValue = 0.0;
    for (final drop in drops) {
      totalEstimatedValue += drop.estimatedValue;
    }
    totalEstimatedValue = double.parse(totalEstimatedValue.toStringAsFixed(2));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).dropStatusDistribution,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00695C),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Total Drops with Estimated Value
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        total.toString(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).totalDrops,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DropValueCalculator.formatEstimatedValue(totalEstimatedValue),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).estimatedValue,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Status breakdown rows
              _buildStatusRow(AppLocalizations.of(context).pending, pending, total, Colors.orange),
              const SizedBox(height: 8),
              _buildStatusRow(AppLocalizations.of(context).collected, collected, total, Colors.green),
              const SizedBox(height: 8),
              _buildStatusRow(AppLocalizations.of(context).flagged, flagged, total, Colors.red),
              const SizedBox(height: 8),
              _buildStatusRow(AppLocalizations.of(context).stale, stale, total, Colors.brown),
              const SizedBox(height: 8),
              _buildStatusRow(AppLocalizations.of(context).censored, censored, total, Colors.purple),
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
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).recyclingImpact,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00695C),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
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
                          AppLocalizations.of(context).plasticBottles,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context).recycledBottles(_formatLargeNumber(totalBottles)),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatLargeNumber(totalBottles),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
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
                          AppLocalizations.of(context).aluminumCans,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context).recycledCans(_formatLargeNumber(totalCans)),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatLargeNumber(totalCans),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.recycling,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).totalItemsRecycled,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _formatLargeNumber(totalItems),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
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
              AppLocalizations.of(context).recentDrops,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00695C),
              ),
            ),
            TextButton(
              onPressed: () {
                print('Stats: View All button pressed for recent drops');
                // Set the initial filter to "Active" and navigate to Drops tab (index 1)
                final l10n = AppLocalizations.of(context);
                ref.read(dropsInitialFilterProvider.notifier).state = l10n.active;
                ref.read(tabControllerProvider.notifier).setTab(1);
              },
              child: Text(AppLocalizations.of(context).viewAll),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentDrops.isEmpty)
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_location_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No drops yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first drop to start recycling',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        else
          Column(
            children: recentDrops.map((drop) => _buildRecentDropCard(drop)).toList(),
          ),
      ],
    );
  }

  Widget _buildRecentDropCard(Drop drop) {
    final itemsText = AppLocalizations.of(context).items;
    final itemCount = drop.numberOfBottles + drop.numberOfCans;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
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
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
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
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
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
                  '$itemCount $itemsText',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  drop.bottleType.localizedDisplayName(context),
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
              drop.status.localizedDisplayName(context),
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
                AppLocalizations.of(context).myStats,
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
                  ref.read(collectionAttemptsProvider.notifier).refresh();
                },
                color: const Color(0xFF00695C), // Green color
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeRangeSelector(),
          const SizedBox(height: 24),
          _buildOverviewCards(stats),
          
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
          AppLocalizations.of(context).overview,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00695C), // Green color
          ),
        ),
        
        // Use the new chart carousel instead of static cards
        StatsChartCarousel(stats: stats, timeRange: _selectedTimeRange.apiValue),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              AppLocalizations.of(context).performanceMetrics,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00695C), // Green color
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              AppLocalizations.of(context).collectionRate,
              '${stats.collectionRate.toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              AppLocalizations.of(context).avgCollectionTime,
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
              AppLocalizations.of(context).cancellationReasons,
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
    // Use collection attempts directly
    final recentCollectionsAsync = ref.watch(collectionAttemptsProvider);

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
                  AppLocalizations.of(context).recentCollections,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00695C), // Green color
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // For collector mode: navigate to History page
                    Navigator.pushNamed(context, AppRoutes.history);
                  },
                  child: Text(AppLocalizations.of(context).viewAll),
                ),
              ],
            ),
            const SizedBox(height: 16),
            recentCollectionsAsync.when(
              data: (response) {
                // Filter for completed collections and sort by completion date
                final completedAttempts = response.attempts
                    .where((attempt) => attempt.outcome == 'collected')
                    .toList()
                  ..sort((a, b) {
                    final aTime = a.completedAt ?? a.updatedAt;
                    final bTime = b.completedAt ?? b.updatedAt;
                    return bTime.compareTo(aTime);
                  });
                
                if (completedAttempts.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context).noCompletedCollectionsYet,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                
                // Show the 3 most recent collections
                return Column(
                  children: completedAttempts.take(3).map((attempt) {
                    return _buildRecentCollectionCardFromCollectionAttempt(attempt);
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) {
                return Center(
                  child: Text(
                    'Error loading collections: ${error.toString()}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              },
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
                      DropValueCalculator.formatEstimatedValue(
                        DropValueCalculator.calculateEstimatedValue(
                          plasticBottleCount: dropSnapshot.numberOfBottles,
                          cansCount: dropSnapshot.numberOfCans,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
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
                      '${AppLocalizations.of(context).collected} ${_formatDate(attempt.completedAt ?? attempt.updatedAt)}',
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
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
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
                      DropValueCalculator.formatEstimatedValue(
                        DropValueCalculator.calculateEstimatedValue(
                          plasticBottleCount: dropoff.numberOfBottles,
                          cansCount: dropoff.numberOfCans,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
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
                  '${AppLocalizations.of(context).collected} ${_formatDate(interaction.interactionTime)}',
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
              color: const Color(0xFF00695C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00695C),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'COLLECTED',
                  style: TextStyle(
                    color: Color(0xFF00695C),
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
                              '${AppLocalizations.of(context).cancelled}: ${_formatCancellationReason(interaction.cancellationReason!)}',
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    switch (interactionType) {
      case 'collected':
        return theme.colorScheme.primary;
      case 'cancelled':
        return theme.colorScheme.error;
      case 'accepted':
        return theme.colorScheme.tertiary;
      case 'expired':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
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
    final l10n = AppLocalizations.of(context);
    // Convert to German timezone
    final germanDate = TimezoneService.toGermanTime(date);
    
    final now = TimezoneService.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(germanDate.year, germanDate.month, germanDate.day);
    
    // Format time as HH:mm
    final timeString = '${germanDate.hour.toString().padLeft(2, '0')}:${germanDate.minute.toString().padLeft(2, '0')}';
    
    if (dateOnly == today) {
      return '${l10n.todayAt(timeString)}';
    } else if (dateOnly == yesterday) {
      return '${l10n.yesterdayAt(timeString)}';
    } else {
      final difference = today.difference(dateOnly).inDays;
      
      if (difference < 7) {
        // Show day name for recent dates
        final dayNames = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun];
        final dayName = dayNames[germanDate.weekday - 1];
        return '$dayName ${l10n.at} $timeString';
      } else if (difference < 30) {
        // Show "X days ago" for older dates
        return '${l10n.daysAgoShort(difference)} ${l10n.at} $timeString';
      } else {
        // Show full date for very old dates
        final monthNames = [l10n.jan, l10n.feb, l10n.mar, l10n.apr, l10n.may, l10n.jun, 
                           l10n.jul, l10n.aug, l10n.sep, l10n.oct, l10n.nov, l10n.dec];
        final monthName = monthNames[germanDate.month - 1];
        return '$monthName ${germanDate.day} ${l10n.at} $timeString';
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
    final l10n = AppLocalizations.of(context);
    switch (reason) {
      case 'noAccess':
        return l10n.noAccess;
      case 'notFound':
        return l10n.notFound;
      case 'alreadyCollected':
        return l10n.alreadyCollected;
      case 'wrongLocation':
        return l10n.wrongLocation;
      case 'unsafe':
        return l10n.unsafeLocation;
      case 'other':
        return l10n.other;
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
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Pin overlay - using same green/white pin as drop cards
                          Center(
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00695C), // Green color to match drop cards
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
                            color: _getStatusColor(interaction.interactionType),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
                                  color: Theme.of(context).colorScheme.onSurface,
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
                                  color: _getStatusColor(interaction.interactionType),
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
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildRecentCollectionCardFromCollectionAttempt(CollectionAttempt attempt) {
    final dropSnapshot = attempt.dropSnapshot;
    final completedAt = attempt.completedAt ?? attempt.updatedAt;
    

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drop image and map side by side
            Row(
              children: [
                // Drop image
                if (dropSnapshot.imageUrl != null && dropSnapshot.imageUrl!.isNotEmpty)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        dropSnapshot.imageUrl!,
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
                              size: 60,
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
                
                // Small map with pin - always show map
                const SizedBox(width: 4), // Small gap between image and map
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          // Static map image - using same approach as history page
                          if (dropSnapshot.location.isNotEmpty && 
                              dropSnapshot.location.containsKey('lat') && 
                              dropSnapshot.location.containsKey('lng')) ...[
                            Builder(
                              builder: (context) {
                                final latLng = LatLng(
                                  dropSnapshot.location['lat']!,
                                  dropSnapshot.location['lng']!,
                                );
                                final mapUrl = _getStaticMapUrl(latLng);
                                return Image.network(
                                  mapUrl,
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.map,
                                          size: 24,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ]
                          else
                            Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.map,
                                  size: 24,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          // Custom pin overlay (always visible) - using same green/white pin as drop cards
                          Positioned(
                            left: 0,
                            top: 0,
                            right: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00695C), // Green color to match drop cards
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
                                child: const Center(
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Location coordinates in bottom right (if available)
                          if (dropSnapshot.location.isNotEmpty && 
                              dropSnapshot.location.containsKey('lat') && 
                              dropSnapshot.location.containsKey('lng'))
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${dropSnapshot.location['lat']!.toStringAsFixed(4)}, ${dropSnapshot.location['lng']!.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Drop information under image and map
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                // Plastic bottles count
                if (dropSnapshot.numberOfBottles > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/water-bottle.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatLargeNumber(dropSnapshot.numberOfBottles),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                // Cans count
                if (dropSnapshot.numberOfCans > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/can.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatLargeNumber(dropSnapshot.numberOfCans),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                // Total amount
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DropValueCalculator.formatEstimatedValue(
                        DropValueCalculator.calculateEstimatedValue(
                          plasticBottleCount: dropSnapshot.numberOfBottles,
                          cansCount: dropSnapshot.numberOfCans,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                // Date
                Text(
                  _formatDate(completedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00695C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF00695C),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context).collected.toUpperCase(),
                        style: TextStyle(
                          color: Color(0xFF00695C),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to parse DateTime from various types
  DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is String) {
      return DateTime.parse(dateValue);
    } else {
      return DateTime.parse(dateValue.toString());
    }
  }



} 

