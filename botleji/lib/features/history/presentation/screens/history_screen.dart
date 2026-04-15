import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:botleji/features/stats/data/models/collector_stats.dart';
import 'package:botleji/features/history/presentation/controllers/history_controller.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/drops/controllers/drops_controller.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'package:botleji/core/services/timezone_service.dart';
import 'package:botleji/features/drops/domain/utils/drop_value_calculator.dart';
import 'package:botleji/l10n/app_localizations.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String? selectedStatus;
  String? selectedTimeRange;
  String? selectedItemType;
  String? selectedBottleType;
  String selectedViewType = 'Collections'; // Default to 'Collections', can be 'Earnings'
  String? selectedEarningsTimeRange = 'Daily'; // Default to 'Daily' (Today), can be 'Weekly', 'Monthly', 'All Time', or null
  final ScrollController _scrollController = ScrollController();

  // Filter options
  final List<String> viewTypeOptions = [
    'Collections',
    'Earnings',
  ];

  final List<String> statusOptions = [
    'All',
    'collected',
    'cancelled',
    'pending',
  ];

  final List<String> timeRangeOptions = [
    'All Time',
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last 6 Months',
    'This Year',
  ];

  final List<String> itemTypeOptions = [
    'All Items',
    'Bottles Only',
    'Cans Only',
    'Mixed',
  ];

  final List<String> bottleTypeOptions = [
    'All Types',
    'plastic',
    'glass',
    'aluminum',
    'mixed',
  ];

  // Earnings-specific time range options (Daily is default)
  final List<String> earningsTimeRangeOptions = [
    'Daily',
    'Weekly',
    'Monthly',
    'All Time',
  ];

  String _getLocalizedTimeRangeOption(String option) {
    final l10n = AppLocalizations.of(context);
    switch (option) {
      case 'All Time':
        return l10n.allTime;
      case 'Today':
        return l10n.today;
      case 'Last 7 Days':
        return l10n.last7Days;
      case 'Last 30 Days':
        return l10n.last30Days;
      case 'Last 3 Months':
        return l10n.last3Months;
      case 'Last 6 Months':
        return l10n.last6Months;
      case 'This Year':
        return l10n.thisYear;
      default:
        return option;
    }
  }

  String _getLocalizedItemTypeOption(String option) {
    final l10n = AppLocalizations.of(context);
    switch (option) {
      case 'All Items':
        return l10n.allItems;
      case 'Bottles Only':
        return l10n.bottlesOnly;
      case 'Cans Only':
        return l10n.cansOnly;
      case 'Mixed':
        return l10n.mixed;
      default:
        return option;
    }
  }

  String _getLocalizedBottleTypeOption(String option) {
    final l10n = AppLocalizations.of(context);
    switch (option) {
      case 'All Types':
        return l10n.allTypes;
      case 'plastic':
        return l10n.plastic;
      case 'glass':
        return l10n.glass;
      case 'aluminum':
        return l10n.aluminum;
      case 'mixed':
        return l10n.mixed;
      default:
        return option;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final controller = ref.read(historyControllerProvider.notifier);
    controller.loadHistory(status: selectedStatus, timeRange: selectedTimeRange);
    
    // Only load user drops when in household mode to avoid overwriting collector map state
    final modeAsync = ref.read(userModeControllerProvider);
    final authState = ref.read(authNotifierProvider);
    modeAsync.whenData((mode) {
      if (mode == UserMode.household) {
        authState.whenData((user) {
          if (user?.id != null && user!.id!.isNotEmpty) {
            final dropsController = ref.read(dropsControllerProvider.notifier);
            dropsController.loadUserDrops(user.id!);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      selectedStatus = null;
      selectedTimeRange = null;
      selectedItemType = null;
      selectedBottleType = null;
    });
    // No need to reload data since we're using client-side filtering
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final controller = ref.read(historyControllerProvider.notifier);
      if (!controller.isLoading) {
        controller.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
  final userModeAsync = ref.watch(userModeControllerProvider);

  return userModeAsync.when(
    data: (userMode) {
      final isHousehold = userMode == UserMode.household;

      if (isHousehold) {
        return _buildHouseholdHistory();
      } else {
        return _buildCollectorHistory(context);
      }
    },
    loading: () => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
    error: (error, stack) => Scaffold(
      body: Center(child: Text('Error loading user mode: $error')),
    ),
  );
}


 Widget _buildHouseholdHistory() {
  final userModeAsync = ref.watch(userModeControllerProvider);
  final authState = ref.watch(authNotifierProvider);

  return userModeAsync.when(
    data: (userMode) {
      return authState.when(
        data: (userData) {
          if (userData?.id == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('My Drops'),
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: Text(AppLocalizations.of(context).pleaseLoginToViewYourDrops),
              ),
            );
          }

          return WillPopScope(
            onWillPop: () async {
              _clearAllFilters();
              return true;
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('My Drops'),
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _clearAllFilters();
                    Navigator.of(context).pop();
                  },
                ),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showFilterDialog,
                      ),
                      if (_hasActiveFilters())
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              body: _buildHouseholdDropsList(userData!.id!),
            ),
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(child: Text(AppLocalizations.of(context).errorLoadingUserData(error.toString()))),
        ),
      );
    },
    loading: () => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
    error: (error, stack) => Scaffold(
      body: Center(child: Text('Error loading user mode: $error')),
    ),
  );
}

Widget _buildHouseholdDropsList(String userId) {
  final dropsAsync = ref.watch(dropsControllerProvider);

  return RefreshIndicator(
    onRefresh: () async {
      final controller = ref.read(dropsControllerProvider.notifier);
      await controller.loadUserDrops(userId);
    },
    child: dropsAsync.when(
      data: (drops) {
        if (drops.isEmpty) {
          return _buildEmptyState();
        }

        // Apply filters to drops
        final filteredDrops = _applyFiltersToDrops(drops);

        if (filteredDrops.isEmpty) {
          return _buildNoResultsState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: filteredDrops.length + 1 + (_hasActiveFilters() ? 1 : 0),
          itemBuilder: (context, index) {
            // Show active filters summary
            if (_hasActiveFilters() && index == 0) {
              return _buildActiveFiltersSummary();
            }

            // Adjust index for active filters summary
            final adjustedIndex = _hasActiveFilters() ? index - 1 : index;

            if (adjustedIndex == filteredDrops.length) {
              return const SizedBox.shrink();
            }

            final drop = filteredDrops[adjustedIndex];
            return _buildDropCard(drop);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    ),
  );
}

  
Widget _buildCollectorHistory(BuildContext context) {
  final historyAsync = ref.watch(historyControllerProvider);

  return WillPopScope(
    onWillPop: () async {
      _clearAllFilters();
      return true;
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).history),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _clearAllFilters();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (selectedViewType == 'Earnings') {
            // Refresh user data to get latest earnings
            ref.invalidate(authNotifierProvider);
          } else {
            final controller = ref.read(historyControllerProvider.notifier);
            await controller.refresh();
          }
        },
        child: Column(
          children: [
            // Filter chips and action buttons
            _buildFilterChipsAndActions(),
            // Content
            Expanded(
              child: selectedViewType == 'Earnings'
                  ? _buildEarningsView()
                  : historyAsync.when(
                data: (history) {
                  if (history.interactions.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Apply filters
                  final filteredInteractions = _applyFilters(history.interactions);

                  if (filteredInteractions.isEmpty) {
                    return _buildNoResultsState();
                  }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _getGroupedItemsCount(filteredInteractions) +
                  1 +
                  (_hasActiveFilters() ? 1 : 0),
              itemBuilder: (context, index) {
                // Show active filters summary
                if (_hasActiveFilters() && index == 0) {
                  return _buildActiveFiltersSummary();
                }

                // Adjust index for active filters summary
                final adjustedIndex =
                    _hasActiveFilters() ? index - 1 : index;

                if (adjustedIndex ==
                    _getGroupedItemsCount(filteredInteractions)) {
                  // Show loading indicator for pagination
                  final controller =
                      ref.read(historyControllerProvider.notifier);
                  if (controller.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return const SizedBox.shrink();
                }

                // Get grouped interactions
                final groupedInteractions =
                    _groupInteractionsByDrop(filteredInteractions);
                final dropGroup = groupedInteractions[adjustedIndex];
                return _buildDropTimeline(dropGroup, context);
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildFilterChipsAndActions() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        // View type filter chips
        Row(
          children: [
            Expanded(
              child: _buildViewTypeChip('Collections', Icons.inventory_2, AppLocalizations.of(context).collections),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildViewTypeChip('Earnings', Icons.account_balance_wallet, AppLocalizations.of(context).earnings),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Filter chips (different for Collections vs Earnings)
        if (selectedViewType == 'Earnings')
          _buildEarningsFilterChips()
        else
          _buildCollectionsFilterChips(),
      ],
    ),
  );
}

Widget _buildViewTypeChip(String label, IconData icon, String displayText) {
  final isSelected = selectedViewType == label;
  return GestureDetector(
    onTap: () {
      final previousViewType = selectedViewType;
      setState(() {
        selectedViewType = label;
      });
      
      // If switching to Collections tab, reload history with current filters
      if (label == 'Collections' && previousViewType != 'Collections') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final controller = ref.read(historyControllerProvider.notifier);
          // Load history with current Collections filters (not Earnings filters)
          controller.loadHistory(status: selectedStatus, timeRange: selectedTimeRange);
        });
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF00695C)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00695C)
              : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            displayText,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildEarningsView() {
  final userDataAsync = ref.watch(authNotifierProvider);
  
  return userDataAsync.when(
    data: (userData) {
      final earningsHistory = userData?.earningsHistory ?? [];
      
      if (earningsHistory.isEmpty) {
        return Column(
          children: [
            // Overview card even when no history
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildEarningsOverviewCard(0.0, selectedEarningsTimeRange ?? 'All Time'),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).noEarningsHistoryYet,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).earningsWillAppearHere,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }

      // Apply time range filter
      List<Map<String, dynamic>> filteredHistory = List<Map<String, dynamic>>.from(earningsHistory);
      
      if (selectedEarningsTimeRange != null && selectedEarningsTimeRange != 'All Time') {
        final now = TimezoneService.now();
        DateTime? startDate;

        switch (selectedEarningsTimeRange) {
          case 'Daily':
            startDate = DateTime(now.year, now.month, now.day);
            break;
          case 'Weekly':
            startDate = now.subtract(const Duration(days: 7));
            break;
          case 'Monthly':
            startDate = DateTime(now.year, now.month - 1, now.day);
            break;
        }

        if (startDate != null) {
          filteredHistory = filteredHistory.where((item) {
            final date = item['date'] != null
                ? (item['date'] is String
                    ? DateTime.parse(item['date'])
                    : item['date'] is DateTime
                        ? item['date'] as DateTime
                        : DateTime.now())
                : DateTime(1970);
            return date.isAfter(startDate!);
          }).toList();
        }
      }

      // Group earnings by session date
      final groupedEarnings = <String, List<Map<String, dynamic>>>{};
      final locale = Localizations.localeOf(context);
      final dateFormat = locale.languageCode == 'ar'
          ? DateFormat('dd MMM yyyy', 'en')
          : DateFormat('MMM dd, yyyy', locale.toString());

      for (var item in filteredHistory) {
        final date = item['date'] != null
            ? (item['date'] is String
                ? DateTime.parse(item['date'])
                : item['date'] is DateTime
                    ? item['date'] as DateTime
                    : DateTime.now())
            : DateTime.now();
        
        String groupKey;
        if (selectedEarningsTimeRange == 'Daily') {
          groupKey = dateFormat.format(date);
        } else if (selectedEarningsTimeRange == 'Weekly') {
          // Group by week (start of week)
          final weekStart = date.subtract(Duration(days: date.weekday - 1));
          groupKey = 'Week of ${dateFormat.format(weekStart)}';
        } else if (selectedEarningsTimeRange == 'Monthly') {
          // Group by month
          final monthFormat = locale.languageCode == 'ar'
              ? DateFormat('MMM yyyy', 'en')
              : DateFormat('MMM yyyy', locale.toString());
          groupKey = monthFormat.format(date);
        } else {
          // Default: group by date
          groupKey = dateFormat.format(date);
        }

        if (!groupedEarnings.containsKey(groupKey)) {
          groupedEarnings[groupKey] = [];
        }
        groupedEarnings[groupKey]!.add(item);
      }

      // Sort groups by date (newest first)
      final sortedGroups = groupedEarnings.entries.toList()
        ..sort((a, b) {
          // Get the first item's date from each group for sorting
          final dateA = a.value.first['date'] != null
              ? (a.value.first['date'] is String
                  ? DateTime.parse(a.value.first['date'])
                  : a.value.first['date'] is DateTime
                      ? a.value.first['date'] as DateTime
                      : DateTime.now())
              : DateTime(1970);
          final dateB = b.value.first['date'] != null
              ? (b.value.first['date'] is String
                  ? DateTime.parse(b.value.first['date'])
                  : b.value.first['date'] is DateTime
                      ? b.value.first['date'] as DateTime
                      : DateTime.now())
              : DateTime(1970);
          return dateB.compareTo(dateA);
        });

      // Calculate total from filtered list
      double filteredTotal = 0;
      for (var item in filteredHistory) {
        filteredTotal += (item['earnings'] ?? 0).toDouble();
      }

      if (sortedGroups.isEmpty) {
        return Column(
          children: [
            // Overview card even when no filtered results
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildEarningsOverviewCard(filteredTotal, selectedEarningsTimeRange ?? 'All Time'),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).noEarningsHistoryYet,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: sortedGroups.length + 1, // +1 for overview card
        itemBuilder: (context, index) {
          // Show overview card at the top
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildEarningsOverviewCard(filteredTotal, selectedEarningsTimeRange ?? 'All Time'),
            );
          }

          // Adjust index for groups
          final groupIndex = index - 1;
          final group = sortedGroups[groupIndex];
          final groupItems = group.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add spacing between groups (no header with date/total)
              if (groupIndex > 0)
                const SizedBox(height: 16),
              // Group items
              ...groupItems.map((item) => _buildEarningsHistoryItem(context, item)),
            ],
          );
        },
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) {
      return Center(
        child: Text(
          AppLocalizations.of(context).errorLoadingEarnings(error.toString()),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    },
  );
}

Widget _buildEarningsFilterChips() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppLocalizations.of(context).timeRange,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: earningsTimeRangeOptions.map((option) {
            final isSelected = (selectedEarningsTimeRange == option) || 
                (selectedEarningsTimeRange == null && option == 'All Time');
            String displayText = option;
            if (option == 'Daily') {
              displayText = AppLocalizations.of(context).today;
            } else if (option == 'Weekly') {
              displayText = AppLocalizations.of(context).thisWeek;
            } else if (option == 'Monthly') {
              displayText = AppLocalizations.of(context).thisMonth;
            } else {
              displayText = AppLocalizations.of(context).allTime;
            }
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(displayText),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    selectedEarningsTimeRange = option == 'All Time' ? null : option;
                  });
                },
                selectedColor: const Color(0xFF00695C).withOpacity(0.2),
                checkmarkColor: const Color(0xFF00695C),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? const Color(0xFF00695C) 
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

Widget _buildCollectionsFilterChips() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Status filter chips
      Text(
        AppLocalizations.of(context).status,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statusOptions.map((option) {
            final isSelected = selectedStatus == option || 
                (selectedStatus == null && option == 'All');
            String displayText = option == 'All' 
                ? AppLocalizations.of(context).all
                : option == 'collected'
                    ? AppLocalizations.of(context).collected
                    : option == 'cancelled'
                        ? AppLocalizations.of(context).cancelled
                        : AppLocalizations.of(context).pending;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(displayText),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    selectedStatus = option == 'All' ? null : option;
                  });
                },
                selectedColor: const Color(0xFF00695C).withOpacity(0.2),
                checkmarkColor: const Color(0xFF00695C),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? const Color(0xFF00695C) 
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 12),
      // Time range filter chips
      Text(
        AppLocalizations.of(context).timeRange,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: timeRangeOptions.map((option) {
            final isSelected = selectedTimeRange == option || 
                (selectedTimeRange == null && option == 'All Time');
            final displayText = _getLocalizedTimeRangeOption(option);
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(displayText),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    selectedTimeRange = option == 'All Time' ? null : option;
                  });
                },
                selectedColor: const Color(0xFF00695C).withOpacity(0.2),
                checkmarkColor: const Color(0xFF00695C),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? const Color(0xFF00695C) 
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

Widget _buildEarningsHistoryItem(BuildContext context, Map<String, dynamic> item) {
  final locale = Localizations.localeOf(context);
  // Use locale-aware date formatting but force Western numerals
  final dateFormat = locale.languageCode == 'ar'
      ? DateFormat('dd MMM yyyy', 'en') // Use 'en' locale to force Western numerals: "22 Nov 2025"
      : DateFormat('MMM dd, yyyy', locale.toString()); // English format: "Nov 22, 2025"
  // Use locale-aware time formatting but force Western numerals
  final timeFormat = locale.languageCode == 'ar'
      ? DateFormat('HH:mm', 'en') // Use 'en' locale to force Western numerals: 24-hour format
      : DateFormat('h:mm a', locale.toString()); // English: 12-hour with AM/PM
  
  final earnings = (item['earnings'] ?? 0).toDouble();
  final collectionCount = item['collectionCount'] ?? 0;
  final date = item['date'] != null
      ? (item['date'] is String
          ? DateTime.parse(item['date'])
          : item['date'] as DateTime)
      : DateTime.now();
  final startTime = item['startTime'] != null
      ? (item['startTime'] is String
          ? DateTime.parse(item['startTime'])
          : item['startTime'] as DateTime)
      : date;
  final lastCollectionTime = item['lastCollectionTime'] != null
      ? (item['lastCollectionTime'] is String
          ? DateTime.parse(item['lastCollectionTime'])
          : item['lastCollectionTime'] as DateTime)
      : date;
  
  // Only show active if it's today AND there's an active session
  final now = TimezoneService.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final isToday = date.isAfter(todayStart.subtract(const Duration(days: 1))) && 
                  date.isBefore(todayEnd);
  final hasActiveSession = item['isActive'] ?? false;
  final isActive = isToday && hasActiveSession;

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF00695C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(date),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$collectionCount ${collectionCount == 1 ? AppLocalizations.of(context).collection : AppLocalizations.of(context).collections}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? AppLocalizations.of(context).active : AppLocalizations.of(context).completed,
                  style: TextStyle(
                    color: isActive ? Colors.green : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).totalEarnings,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DropValueCalculator.formatEstimatedValue(earnings),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF00695C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppLocalizations.of(context).sessionTime,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${timeFormat.format(startTime)} - ${timeFormat.format(lastCollectionTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildEarningsOverviewCard(double total, String filterType) {
  // Get label and icon based on filter type
  String label;
  IconData icon;
  Color color;
  
  final l10n = AppLocalizations.of(context);
  
  switch (filterType) {
    case 'Daily':
      label = l10n.today;
      icon = Icons.today;
      color = Colors.blue;
      break;
    case 'Weekly':
      label = l10n.thisWeek;
      icon = Icons.calendar_view_week;
      color = Colors.orange;
      break;
    case 'Monthly':
      label = l10n.thisMonth;
      icon = Icons.calendar_month;
      color = Colors.green;
      break;
    default:
      label = l10n.allTime;
      icon = Icons.all_inclusive;
      color = const Color(0xFF00695C);
  }
  
  return Card(
    elevation: 4,
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00695C).withOpacity(0.1),
            const Color(0xFF00695C).withOpacity(0.05),
          ],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Color(0xFF00695C),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).earningsOverview,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildOverviewStat(
            label,
            total,
            icon,
            color,
          ),
        ],
      ),
    ),
  );
}

Widget _buildOverviewStat(String label, double amount, IconData icon, Color color) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          DropValueCalculator.formatEstimatedValue(amount),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

 

  List<CollectorInteraction> _applyFilters(List<CollectorInteraction> interactions) {
    List<CollectorInteraction> filtered = interactions;
    
    // Apply status filter
    if (selectedStatus != null && selectedStatus != 'All') {
      filtered = filtered.where((interaction) {
        final interactionType = interaction.interactionType.toLowerCase();
        final selectedStatusLower = selectedStatus!.toLowerCase();
        return interactionType == selectedStatusLower;
      }).toList();
    }

    // Apply time range filter
    if (selectedTimeRange != null && selectedTimeRange != 'All Time') {
      final now = TimezoneService.now();
      DateTime? startDate;

      switch (selectedTimeRange) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'Last 7 Days':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Last 30 Days':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case 'Last 3 Months':
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case 'Last 6 Months':
          startDate = DateTime(now.year, now.month - 6, now.day);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          break;
      }

      if (startDate != null) {
        filtered = filtered.where((interaction) {
          return interaction.interactionTime.isAfter(startDate!);
        }).toList();
      }
    }

    // Apply item type filter
    if (selectedItemType != null && selectedItemType != 'All Items') {
      filtered = filtered.where((interaction) {
        final dropoff = interaction.dropoff;
        if (dropoff == null) return false;

        switch (selectedItemType) {
          case 'Bottles Only':
            return dropoff.numberOfBottles > 0 && dropoff.numberOfCans == 0;
          case 'Cans Only':
            return dropoff.numberOfCans > 0 && dropoff.numberOfBottles == 0;
          case 'Mixed':
            return dropoff.numberOfBottles > 0 && dropoff.numberOfCans > 0;
          default:
            return true;
        }
      }).toList();
    }

    // Apply bottle type filter
    if (selectedBottleType != null && selectedBottleType != 'All Types') {
      filtered = filtered.where((interaction) {
        final dropoff = interaction.dropoff;
        if (dropoff == null) return false;
        return dropoff.bottleType.toLowerCase() == selectedBottleType!.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  List<Drop> _applyFiltersToDrops(List<Drop> drops) {
    // My Drops: show censored drops too, but mark them; do not hide here
    List<Drop> filtered = drops;

    // Apply status filter
    if (selectedStatus != null && selectedStatus != 'All') {
      filtered = filtered.where((drop) {
        return drop.status.name.toLowerCase() == selectedStatus!.toLowerCase();
      }).toList();
    }

    // Apply time range filter
    if (selectedTimeRange != null && selectedTimeRange != 'All Time') {
      final now = TimezoneService.now();
      DateTime? startDate;

      switch (selectedTimeRange) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'Last 7 Days':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Last 30 Days':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case 'Last 3 Months':
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case 'Last 6 Months':
          startDate = DateTime(now.year, now.month - 6, now.day);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          break;
      }

      if (startDate != null) {
        filtered = filtered.where((drop) {
          return drop.createdAt.isAfter(startDate!);
        }).toList();
      }
    }

    // Apply item type filter
    if (selectedItemType != null && selectedItemType != 'All Items') {
      filtered = filtered.where((drop) {
        return drop.numberOfBottles > 0 && drop.numberOfCans == 0; // Assuming 'collected' status means bottles only
      }).toList();
    }

    // Apply bottle type filter
    if (selectedBottleType != null && selectedBottleType != 'All Types') {
      filtered = filtered.where((drop) {
        return drop.bottleType.name.toLowerCase() == selectedBottleType!.toLowerCase();
      }).toList();
    }

    // Sort drops by creation date (most recent first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  Widget _buildHistoryCard(CollectorInteraction interaction) {
    final dropoff = interaction.dropoff;

    return InkWell(
      onTap: () => _showInteractionDetails(interaction),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropoff details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drop image and map side by side
                  Row(
                    children: [
                      // Drop image
                      if (dropoff?.imageUrl != null && dropoff!.imageUrl!.isNotEmpty)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              dropoff.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    size: 60,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            size: 60,
                          ),
                        ),
                      
                      // Small map with pin
                      if (dropoff?.location != null) ...[
                        const SizedBox(width: 4), // Small gap between image and map
                        Expanded(
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                // Static map image - using simple static map like drops tab
                                Image.network(
                                  _getStaticMapUrl(
                                    LatLng(
                                      dropoff!.location.coordinates[1],
                                      dropoff.location.coordinates[0],
                                    ),
                                    isDark: Theme.of(context).brightness == Brightness.dark,
                                  ),
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Drop information under image and map
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      // Plastic bottles count
                      if (dropoff?.numberOfBottles != null && dropoff!.numberOfBottles > 0)
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
                              _formatLargeNumber(dropoff.numberOfBottles),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      // Cans count
                      if (dropoff?.numberOfCans != null && dropoff!.numberOfCans > 0)
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
                              _formatLargeNumber(dropoff.numberOfCans),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[600],
                              ),
                            ),
                          ],
                        ),
                      // Item count
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatItemCount(dropoff?.numberOfBottles ?? 0, dropoff?.numberOfCans ?? 0),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00695C),
                            ),
                          ),
                        ],
                      ),
                      // Date
                      Text(
                        _formatDate(interaction.interactionTime),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      // Special instructions
                      if (dropoff?.leaveOutside == true) ...[
                        const SizedBox(width: 12),
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
                ],
              ),
              const SizedBox(height: 16),
              // Timeline steps (single interaction)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline column with dot
                    Column(
                      children: [
                        // Dot
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
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(interaction.interactionTime),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusText(interaction.interactionType),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(interaction.interactionType),
                            ),
                          ),
                          if (interaction.notes?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              _translateInteractionNote(interaction.notes!),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropCard(Drop drop) {
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
      child: InkWell(
        onTap: () => _showDropDetails(drop),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map and drop image side by side
              Row(
                children: [
                  // Drop image
                  if (drop.imageUrl.isNotEmpty)
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
                  
                  // Small map with pin
                  if (drop.location != null) ...[
                    const SizedBox(width: 4), // Small gap between image and map
                    Expanded(
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              // Static map image
                              Image.network(
                                _getStaticMapUrl(
                                  LatLng(
                                    drop.location.latitude,
                                    drop.location.longitude,
                                  ),
                                  isDark: Theme.of(context).brightness == Brightness.dark,
                                ),
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.map,
                                        size: 24,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Custom pin overlay (always visible) - using same green/white pin as drop cards
                              Positioned(
                                left: 0,
                                top: 0,
                                right: 0,
                                bottom: 0,
                                child: Center(
                                  child: Container(
                                    width: 20,
                                    height: 20,
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Bottle/can icons and counts
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (drop.numberOfBottles > 0)
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
                          _formatLargeNumber(drop.numberOfBottles),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[600],
                              ),
                        ),
                      ],
                    ),
                  if (drop.numberOfCans > 0)
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
                          _formatLargeNumber(drop.numberOfCans),
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
                        _formatItemCount(drop.numberOfBottles, drop.numberOfCans),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00695C),
                            ),
                      ),
                    ],
                  ),
                  Text(
                    _formatDate(drop.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Collection Timeline
              _buildCollectionTimeline(drop),
              const SizedBox(height: 8),
              // Status and Notes
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(drop.status.name).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(drop.status.name),
                          color: _getStatusColor(drop.status.name),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(drop.status.name),
                          style: TextStyle(
                            color: _getStatusColor(drop.status.name),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (drop.notes != null && drop.notes!.isNotEmpty)
                    Flexible(
                      child: Text(
                        drop.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[800],
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionTimeline(Drop drop) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Live Status Header
      Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getLiveStatusColor(drop.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          if (drop.status == DropStatus.pending) ...[
            _buildAnimatedSandClock(size: 24, color: Colors.orange),
            const SizedBox(width: 8),
          ],
          Text(
            _getLiveStatusText(drop.status),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _getLiveStatusColor(drop.status),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            _getLastUpdateText(drop),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      // Live Timeline
      Row(
        children: [
          // Step 1: Created
          Expanded(
            child: _buildLiveTimelineStep(
              icon: Icons.add_location,
              title: AppLocalizations.of(context).created,
              subtitle: _formatDate(drop.createdAt),
              isCompleted: true,
              isActive: false,
              isLive: false,
              color: Colors.blue,
            ),
          ),
          // Connector between step 1 and 2
          Container(
            width: 2,
            height: 36,
            margin: const EdgeInsets.only(bottom: 30),
            decoration: BoxDecoration(
              color: (drop.status == DropStatus.accepted || drop.status == DropStatus.collected)
                  ? Colors.green.withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          // Step 2: Accepted (shows as "Collector on his way" for household)
          Expanded(
            child: _buildLiveTimelineStep(
              icon: drop.status == DropStatus.collected
                  ? Icons.handshake
                  : Icons.directions_walk,
              title: drop.status == DropStatus.accepted 
                  ? AppLocalizations.of(context).onTheWay
                  : drop.status == DropStatus.collected
                      ? AppLocalizations.of(context).wasOnTheWay
                      : AppLocalizations.of(context).accepted,
              subtitle: _getAcceptedSubtitle(drop),
              isCompleted: drop.status == DropStatus.accepted ||
                  drop.status == DropStatus.collected,
              isActive: drop.status == DropStatus.accepted,
              isLive: drop.status == DropStatus.accepted,
              color: Colors.green,
            ),
          ),
          // Connector between step 2 and 3
          Container(
            width: 2,
            height: 36,
            margin: const EdgeInsets.only(bottom: 30),
            decoration: BoxDecoration(
              color: drop.status == DropStatus.collected
                  ? Colors.orange.withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          // Step 3: Collected
          Expanded(
            child: _buildLiveTimelineStep(
              icon: Icons.recycling,
              title: AppLocalizations.of(context).collected,
              subtitle: _getCollectedSubtitle(drop),
              isCompleted: drop.status == DropStatus.collected,
              isActive: false,
              isLive: drop.status == DropStatus.collected,
              color: Colors.orange,
            ),
          ),
        ],
      ),

      // Live Updates Section (only for accepted drops)
      if (drop.status == DropStatus.accepted)
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.green[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).collectorOnHisWay,
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${AppLocalizations.of(context).estimatedTime}: ${_getEstimatedTime()}',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 6,
                    height: 6,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

      // Cancellation Alert
      if (drop.status == DropStatus.cancelled || drop.cancellationCount > 0)
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drop.status == DropStatus.cancelled
                          ? 'Drop cancelled'
                          : 'Collection issues',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      drop.status == DropStatus.cancelled
                          ? 'This drop was cancelled by the collector'
                          : 'Cancelled ${drop.cancellationCount} time${drop.cancellationCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}


  Widget _buildLiveTimelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool isLive,
    required Color color,
    bool isAnimated = false,
  }) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted 
                    ? color 
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: isActive 
                    ? Border.all(color: color, width: 3) 
                    : Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                boxShadow: isLive ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 4,
                  ),
                ] : null,
              ),
              child: isAnimated
                  ? _buildAnimatedSandClock()
                  : Icon(
                      icon,
                      color: isCompleted 
                          ? Colors.white 
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      size: 18,
                    ),
            ),
            if (isLive && color != Colors.orange) // Don't show spinning indicator for collected (orange) step
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 6,
                      height: 6,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isCompleted 
                ? color 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getLiveStatusColor(DropStatus status) {
    switch (status) {
      case DropStatus.pending:
        return Colors.grey;
      case DropStatus.accepted:
        return Colors.green;
      case DropStatus.collected:
        return Colors.orange;
      case DropStatus.cancelled:
        return Colors.red;
      case DropStatus.expired:
        return Colors.red;
      case DropStatus.stale:
        return Colors.brown;
    }
  }

  String _getLiveStatusText(DropStatus status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case DropStatus.pending:
        return l10n.waitingForCollector;
      case DropStatus.accepted:
        return l10n.liveCollectorOnTheWay;
      case DropStatus.collected:
        return l10n.collected;
      case DropStatus.cancelled:
        return '❌ ${l10n.cancelled}';
      case DropStatus.expired:
        return '⏰ ${l10n.expired}';
      case DropStatus.stale:
        return '🟤 ${l10n.stale}';
    }
  }

  Widget _buildAnimatedSandClock({double size = 20, Color? color}) {
    return _AnimatedSandClockWidget(
      size: size,
      color: color ?? Colors.orange,
    );
  }

  String _getLastUpdateText(Drop drop) {
    final l10n = AppLocalizations.of(context);
    final now = TimezoneService.now();
    final diff = now.difference(TimezoneService.toGermanTime(drop.modifiedAt));
    
    if (diff.inMinutes < 1) {
      return l10n.justNow;
    } else if (diff.inMinutes < 60) {
      return l10n.minutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return l10n.hoursAgo(diff.inHours);
    } else {
      return l10n.daysAgo(diff.inDays);
    }
  }

  String _getAcceptedSubtitle(Drop drop) {
    final l10n = AppLocalizations.of(context);
    if (drop.status == DropStatus.accepted) {
      return l10n.collectorOnHisWay;
    } else if (drop.status == DropStatus.collected) {
      return l10n.collectorWasOnTheWay;
    } else {
      return l10n.waiting;
    }
  }

  String _getCollectedSubtitle(Drop drop) {
    final l10n = AppLocalizations.of(context);
    if (drop.status == DropStatus.collected) {
      return l10n.collected;
    } else {
      return l10n.notYetCollected;
    }
  }

  String _getEstimatedTime() {
    // Simulate estimated arrival time
    final now = TimezoneService.now();
    final estimated = now.add(const Duration(minutes: 15));
    return '${estimated.hour.toString().padLeft(2, '0')}:${estimated.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildItemCount(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isWarning ? Colors.orange : null,
              fontWeight: isWarning ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Icon(
              Icons.filter_list,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).filterHistory,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (_hasActiveFilters())
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppLocalizations.of(context).activeFilters,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: selectedViewType == 'Earnings'
                ? [
                    // Earnings time range filter
                    _buildFilterDropdown(
                      AppLocalizations.of(context).timeRange,
                      selectedEarningsTimeRange ?? 'All Time',
                      earningsTimeRangeOptions,
                      (value) => setState(() => selectedEarningsTimeRange = value == 'All Time' ? null : value),
                      isActive: selectedEarningsTimeRange != null,
                    ),
                  ]
                : [
                    // Status filter
                    _buildFilterDropdown(
                      AppLocalizations.of(context).status,
                      selectedStatus ?? 'All',
                      statusOptions,
                      (value) => setState(() => selectedStatus = value == 'All' ? null : value),
                      isActive: selectedStatus != null,
                    ),
                    const SizedBox(height: 16),

                    // Time range filter
                    _buildFilterDropdown(
                      AppLocalizations.of(context).timeRange,
                      selectedTimeRange ?? 'All Time',
                      timeRangeOptions,
                      (value) => setState(() => selectedTimeRange = value == 'All Time' ? null : value),
                      isActive: selectedTimeRange != null,
                    ),
                    const SizedBox(height: 16),

                    // Item type filter
                    _buildFilterDropdown(
                      AppLocalizations.of(context).itemType,
                      selectedItemType ?? 'All Items',
                      itemTypeOptions,
                      (value) => setState(() => selectedItemType = value == 'All Items' ? null : value),
                      isActive: selectedItemType != null,
                    ),
                    const SizedBox(height: 16),

                    // Bottle type filter
                    _buildFilterDropdown(
                      AppLocalizations.of(context).bottleType,
                      selectedBottleType ?? 'All Types',
                      bottleTypeOptions,
                      (value) => setState(() => selectedBottleType = value == 'All Types' ? null : value),
                      isActive: selectedBottleType != null,
                    ),
                  ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedStatus = null;
                selectedTimeRange = null;
                selectedItemType = null;
                selectedBottleType = null;
                selectedEarningsTimeRange = null;
              });
              // No need to reload data since we're using client-side filtering
            },
            child: Text(
              AppLocalizations.of(context).clearAll,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // No need to reload data since we're using client-side filtering
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text(AppLocalizations.of(context).apply),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    if (selectedViewType == 'Earnings') {
      return selectedEarningsTimeRange != null;
    }
    return selectedStatus != null ||
           selectedTimeRange != null ||
           selectedItemType != null ||
           selectedBottleType != null;
  }

  Widget _buildFilterDropdown(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged, {
    bool isActive = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: isActive 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isActive 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isActive 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixIcon: isActive 
                ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) 
                : null,
          ),
          items: options.map((option) {
            String displayText = option;
            if (label == AppLocalizations.of(context).timeRange) {
              displayText = _getLocalizedTimeRangeOption(option);
              // Handle earnings-specific options
              if (selectedViewType == 'Earnings') {
                if (option == 'Daily') {
                  displayText = AppLocalizations.of(context).today;
                } else if (option == 'Weekly') {
                  displayText = AppLocalizations.of(context).thisWeek;
                } else if (option == 'Monthly') {
                  displayText = AppLocalizations.of(context).thisMonth;
                }
              }
            } else if (label == AppLocalizations.of(context).itemType) {
              displayText = _getLocalizedItemTypeOption(option);
            } else if (label == AppLocalizations.of(context).bottleType) {
              displayText = _getLocalizedBottleTypeOption(option);
            } else if (label == AppLocalizations.of(context).status) {
              displayText = option == 'All' 
                  ? AppLocalizations.of(context).all
                  : option == 'collected'
                      ? AppLocalizations.of(context).collected
                      : option == 'cancelled'
                          ? AppLocalizations.of(context).cancelled
                          : option == 'pending'
                              ? AppLocalizations.of(context).pending
                              : option;
            }
            return DropdownMenuItem(
              value: option,
              child: Text(
                displayText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ],
    );
  }


  void _showInteractionDetails(CollectorInteraction interaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(interaction.interactionType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(interaction.interactionType),
                          color: _getStatusColor(interaction.interactionType),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                  Text(
                          _getStatusText(interaction.interactionType).toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(interaction.interactionType),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Interaction Details', [
                        _buildDetailRow('ID', interaction.id),
                        _buildDetailRow('Time', _formatDate(interaction.interactionTime)),
                        _buildDetailRow('Type', interaction.interactionType),
                        if (interaction.notes?.isNotEmpty == true)
                          _buildDetailRow(AppLocalizations.of(context).notes, _translateInteractionNote(interaction.notes!)),
                        if (interaction.cancellationReason?.isNotEmpty == true)
                          _buildDetailRow(AppLocalizations.of(context).cancellationReason, _formatCancellationReason(interaction.cancellationReason!)),
                      ]),

                      if (interaction.dropoff != null) ...[
                        const SizedBox(height: 24),
                        _buildDetailSection('Drop Details', [
                          _buildDetailRow('Drop ID', interaction.dropoff!.id),
                          _buildDetailRow('User ID', interaction.dropoff!.userId),
                          _buildDetailRow('Bottles', interaction.dropoff!.numberOfBottles.toString()),
                          _buildDetailRow('Cans', interaction.dropoff!.numberOfCans.toString()),
                          _buildDetailRow('Bottle Type', interaction.dropoff!.bottleType),
                          _buildDetailRow('Status', interaction.dropoff!.status),
                          _buildDetailRow('Leave Outside', interaction.dropoff!.leaveOutside ? 'Yes' : 'No'),
                          _buildDetailRow('Suspicious', interaction.dropoff!.isSuspicious ? 'Yes' : 'No'),
                          if (interaction.dropoff!.notes?.isNotEmpty == true)
                            _buildDetailRow('Drop Notes', interaction.dropoff!.notes!),
                          if (interaction.dropoff!.location != null)
                            _buildDetailRow('Location', '${interaction.dropoff!.location.coordinates[1].toStringAsFixed(6)}, ${interaction.dropoff!.location.coordinates[0].toStringAsFixed(6)}'),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDropDetails(Drop drop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header with enhanced design
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Status badge with enhanced design
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(drop.status.name).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(drop.status.name).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(drop.status.name),
                                color: _getStatusColor(drop.status.name),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getStatusText(drop.status.name).toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(drop.status.name),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Close button with better design
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: Colors.grey[700]),
                            iconSize: 20,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Quick stats cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickStatCard(
                            'Items',
                            '${drop.numberOfBottles + drop.numberOfCans}',
                            Icons.inventory_2,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickStatCard(
                            'Bottles',
                            '${drop.numberOfBottles}',
                            Icons.water_drop,
                            Colors.cyan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickStatCard(
                            'Cans',
                            '${drop.numberOfCans}',
                            Icons.local_drink,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content with enhanced design
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEnhancedDetailSection('Drop Information', [
                          _buildEnhancedDetailRow('Drop ID', drop.id, Icons.qr_code),
                          _buildEnhancedDetailRow('Created', _formatDate(drop.createdAt), Icons.schedule),
                          _buildEnhancedDetailRow('Last Updated', _formatDate(drop.modifiedAt), Icons.update),
                          _buildEnhancedDetailRow('Bottle Type', drop.bottleType.localizedDisplayName(context), Icons.category),
                          _buildEnhancedDetailRow('Leave Outside', drop.leaveOutside ? 'Yes' : 'No', Icons.home),
                        ]),

                        if (drop.notes?.isNotEmpty == true) ...[
                          const SizedBox(height: 24),
                          _buildEnhancedDetailSection('Notes', [
                            _buildEnhancedDetailRow('Special Instructions', drop.notes!, Icons.note),
                          ]),
                        ],

                        if (drop.cancellationCount > 0) ...[
                          const SizedBox(height: 24),
                          _buildEnhancedDetailSection('Cancellation History', [
                            _buildEnhancedDetailRow('Total Cancellations', '${drop.cancellationCount}', Icons.cancel),
                            if (drop.cancelledByCollectorIds.isNotEmpty)
                              _buildEnhancedDetailRow('Cancelled By', '${drop.cancelledByCollectorIds.length} collectors', Icons.people),
                          ]),
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDetailRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No collection history yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your collection history will appear here',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading history',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final controller = ref.read(historyControllerProvider.notifier);
              controller.refresh();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'collected':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'collected':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    final l10n = AppLocalizations.of(context);
    switch (status.toLowerCase()) {
      case 'collected':
        return l10n.collected;
      case 'cancelled':
        return l10n.cancelled;
      case 'pending':
        return l10n.pending;
      case 'accepted':
        return l10n.accepted;
      case 'expired':
        return l10n.expired;
      default:
        return status;
    }
  }

  String _translateInteractionNote(String note) {
    final l10n = AppLocalizations.of(context);
    final noteLower = note.toLowerCase();
    
    // Translate common backend note patterns
    if (noteLower.contains('accepted drop for collection')) {
      return l10n.acceptedDropForCollection;
    }
    if (noteLower.contains('collection completed successfully')) {
      return l10n.collectionCompletedSuccessfully;
    }
    if (noteLower.contains('collection expired')) {
      return l10n.dropExpired;
    }
    if (noteLower.contains('collection cancelled')) {
      return l10n.dropCancelled;
    }
    
    // Return original note if no translation found
    return note;
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

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context);
    print('🕐 HistoryScreen._formatDate: Input date: $date');
    final germanDate = TimezoneService.toGermanTime(date);
    print('🕐 HistoryScreen._formatDate: German date: $germanDate');
    final now = TimezoneService.now();
    print('🕐 HistoryScreen._formatDate: Current German time: $now');
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(germanDate.year, germanDate.month, germanDate.day);
    
    // Format time as HH:mm (use Western numerals)
    final timeString = '${germanDate.hour.toString().padLeft(2, '0')}:${germanDate.minute.toString().padLeft(2, '0')}';
    print('🕐 HistoryScreen._formatDate: Time string: $timeString');
    
    if (dateOnly == today) {
      return l10n.todayAt(timeString);
    } else if (dateOnly == yesterday) {
      return l10n.yesterdayAt(timeString);
    } else {
      final difference = today.difference(dateOnly).inDays;
      
      if (difference < 7) {
        // Show day name for recent dates (use localized day names)
        String dayName;
        switch (germanDate.weekday) {
          case 1: dayName = l10n.mon; break;
          case 2: dayName = l10n.tue; break;
          case 3: dayName = l10n.wed; break;
          case 4: dayName = l10n.thu; break;
          case 5: dayName = l10n.fri; break;
          case 6: dayName = l10n.sat; break;
          case 7: dayName = l10n.sun; break;
          default: dayName = '';
        }
        return '$dayName ${l10n.at} $timeString';
      } else if (difference < 30) {
        // Show "X days ago" for older dates
        return '${l10n.daysAgoShort(difference)} ${l10n.at} $timeString';
      } else {
        // Show full date for very old dates (use localized month names with Western numerals)
        String monthName;
        switch (germanDate.month) {
          case 1: monthName = l10n.jan; break;
          case 2: monthName = l10n.feb; break;
          case 3: monthName = l10n.mar; break;
          case 4: monthName = l10n.apr; break;
          case 5: monthName = l10n.may; break;
          case 6: monthName = l10n.jun; break;
          case 7: monthName = l10n.jul; break;
          case 8: monthName = l10n.aug; break;
          case 9: monthName = l10n.sep; break;
          case 10: monthName = l10n.oct; break;
          case 11: monthName = l10n.nov; break;
          case 12: monthName = l10n.dec; break;
          default: monthName = '';
        }
        // Use Western numerals for day
        return '$monthName ${germanDate.day} ${l10n.at} $timeString';
      }
    }
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

  String _formatItemCount(int bottles, int cans) {
    final l10n = AppLocalizations.of(context);
    final parts = <String>[];
    
    if (bottles > 0) {
      parts.add('$bottles ${l10n.bottles}');
    }
    if (cans > 0) {
      parts.add('$cans ${l10n.cans}');
    }
    
    if (parts.isEmpty) {
      return '0 ${l10n.items}';
    }
    
    return parts.join(', ');
  }

  Widget _buildActiveFiltersSummary() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Active Filters: ${_getAppliedFiltersText()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedStatus = null;
                    selectedTimeRange = null;
                    selectedItemType = null;
                    selectedBottleType = null;
                  });
                  _loadInitialData();
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getAppliedFiltersText() {
    final filters = <String>[];
    if (selectedStatus != null && selectedStatus != 'All') {
      filters.add('Status: $selectedStatus');
    }
    if (selectedTimeRange != null && selectedTimeRange != 'All Time') {
      filters.add('Time: $selectedTimeRange');
    }
    if (selectedItemType != null && selectedItemType != 'All Items') {
      filters.add('Item Type: $selectedItemType');
    }
    if (selectedBottleType != null && selectedBottleType != 'All Types') {
      filters.add('Bottle Type: $selectedBottleType');
    }
    return filters.join(', ');
  }

  int _getGroupedItemsCount(List<CollectorInteraction> interactions) {
    final groupedInteractions = _groupInteractionsByDrop(interactions);
    return groupedInteractions.length;
  }

  // Helper to group interactions by dropoffId and create pairs
  List<List<CollectorInteraction>> _groupInteractionsByDrop(List<CollectorInteraction> interactions) {
    final Map<String, List<CollectorInteraction>> grouped = {};
    
    for (final interaction in interactions) {
      // Try to get a unique identifier for the drop
      String dropKey = '';
      
      // ALWAYS prefer dropoff.id if available (most reliable)
      if (interaction.dropoff?.id.isNotEmpty == true) {
        dropKey = interaction.dropoff!.id;
      } else if (interaction.dropoffId.isNotEmpty) {
        // Use dropoffId as fallback
        dropKey = interaction.dropoffId;
      } else {
        // Last resort: use interaction id (this means ungrouped)
        dropKey = interaction.id;
      }
      
      if (dropKey.isNotEmpty) {
        grouped.putIfAbsent(dropKey, () => []).add(interaction);
      }
    }
    
    // Sort each group by interaction time
    for (final group in grouped.values) {
      group.sort((a, b) => a.interactionTime.compareTo(b.interactionTime));
    }
    
    // Now create pairs from each group
    List<List<CollectorInteraction>> pairs = [];
    
    for (final group in grouped.values) {
      // Find all accepted interactions
      final acceptedInteractions = group.where((i) => i.interactionType == 'accepted').toList();
      
      // If there are accepted interactions, create pairs with them
      if (acceptedInteractions.isNotEmpty) {
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
          } else {
            // If no subsequent interaction, just show the accepted one
            pairs.add([accepted]);
          }
        }
      } else {
        // If no accepted interactions, show standalone interactions
        for (final interaction in group) {
          if (interaction.interactionType == 'cancelled' || 
              interaction.interactionType == 'collected' || 
              interaction.interactionType == 'expired') {
            pairs.add([interaction]);
          }
        }
      }
    }
    
    // Sort pairs by the most recent interaction time (descending order)
    pairs.sort((a, b) => b.last.interactionTime.compareTo(a.last.interactionTime));
    
    return pairs;
  }

  // Helper to build a timeline for a single drop
  
  Widget _buildDropTimeline(List<CollectorInteraction> interactions, BuildContext context) {
  final firstInteraction = interactions.first;
  final lastInteraction = interactions.last;

  return Card(
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropoff details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drop image and map side by side
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
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          firstInteraction.dropoff!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image_not_supported,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                size: 60,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    // Placeholder when no image
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        size: 60,
                      ),
                    ),
                  const SizedBox(width: 8),

                  // Small map with pin
                  if (firstInteraction.dropoff?.location != null) ...[
                    Expanded(
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Image.network(
                                _getStaticMapUrl(
                                  LatLng(
                                    firstInteraction.dropoff!.location.coordinates[1],
                                    firstInteraction.dropoff!.location.coordinates[0],
                                  ),
                                  isDark: Theme.of(context).brightness == Brightness.dark,
                                ),
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 120,
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    child: Center(
                                      child: Icon(
                                        Icons.map,
                                        size: 24,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Custom pin overlay - using same green/white pin as drop cards
                              Positioned.fill(
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
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 16,
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
                ],
              ),
              const SizedBox(height: 8),

              // Drop information under image and map
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  // Plastic bottles count
                  if (firstInteraction.dropoff?.numberOfBottles != null &&
                      firstInteraction.dropoff!.numberOfBottles > 0)
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
                          _formatLargeNumber(firstInteraction.dropoff!.numberOfBottles),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[600],
                              ),
                        ),
                      ],
                    ),
                  // Cans count
                  if (firstInteraction.dropoff?.numberOfCans != null &&
                      firstInteraction.dropoff!.numberOfCans > 0)
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
                          _formatLargeNumber(firstInteraction.dropoff!.numberOfCans),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[600],
                              ),
                        ),
                      ],
                    ),
                  // Item count
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatItemCount(firstInteraction.dropoff?.numberOfBottles ?? 0, firstInteraction.dropoff?.numberOfCans ?? 0),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[600],
                            ),
                      ),
                    ],
                  ),
                  // Date
                  Text(
                    _formatDate(firstInteraction.dropoff!.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                  ),
                  // Special instructions
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
                    // Timeline dot + line
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

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(interaction.interactionTime),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusText(interaction.interactionType),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          // Show earnings if collected
                          if (isCollected && interaction.earnings != null && interaction.earnings! > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  size: 14,
                                  color: const Color(0xFF00695C),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DropValueCalculator.formatEstimatedValue(interaction.earnings!),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF00695C),
                                      ),
                                ),
                              ],
                            ),
                          ],
                          if (interaction.notes?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              _translateInteractionNote(interaction.notes!),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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


  String _getStaticMapUrl(LatLng location, {bool isDark = false}) {
    // Use the same API key that works in the drops tab
    const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    const baseUrl = 'https://maps.googleapis.com/maps/api/staticmap';
    
    // Build base query parameters
    final queryParts = <String>[
      'center=${location.latitude},${location.longitude}',
      'zoom=16',
      'size=600x400',
      'maptype=roadmap',
    ];
    
    // Add dark theme styling if needed
    if (isDark) {
      // Dark theme styles - each style is added as a separate parameter
      final darkStyles = [
        'feature:all|element:labels.text.fill|color:0xffffff|lightness:-100',
        'feature:all|element:labels.text.stroke|color:0x000000|lightness:100',
        'feature:all|element:labels.icon|visibility:off',
        'feature:administrative|element:geometry.stroke|color:0x444444',
        'feature:administrative|element:geometry.fill|color:0x1a1a1a',
        'feature:landscape|element:geometry|color:0x2d2d2d',
        'feature:landscape|element:geometry.fill|color:0x1a1a1a',
        'feature:poi|element:geometry|color:0x2d2d2d',
        'feature:poi|element:geometry.fill|color:0x1a1a1a',
        'feature:road|element:geometry|color:0x3d3d3d',
        'feature:road|element:geometry.fill|color:0x2d2d2d',
        'feature:road|element:labels.text.fill|color:0xffffff',
        'feature:road|element:labels.text.stroke|color:0x000000',
        'feature:transit|element:geometry|color:0x2d2d2d',
        'feature:transit|element:geometry.fill|color:0x1a1a1a',
        'feature:water|element:geometry|color:0x1a1a1a',
        'feature:water|element:geometry.fill|color:0x0a0a0a',
      ];
      
      // Add each style parameter
      for (final style in darkStyles) {
        queryParts.add('style=${Uri.encodeComponent(style)}');
      }
    }
    
    // Add API key
    queryParts.add('key=$apiKey');
    
    // Build final URL
    return '$baseUrl?${queryParts.join('&')}';
  }
}

class _AnimatedSandClockWidget extends StatefulWidget {
  final double size;
  final Color color;

  const _AnimatedSandClockWidget({
    required this.size,
    required this.color,
  });

  @override
  State<_AnimatedSandClockWidget> createState() => _AnimatedSandClockWidgetState();
}

class _AnimatedSandClockWidgetState extends State<_AnimatedSandClockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _controller.repeat(); // This makes it spin continuously
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.hourglass_empty,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
} 