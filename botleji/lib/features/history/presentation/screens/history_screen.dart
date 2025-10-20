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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Filter options
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
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      selectedStatus = null;
      selectedTimeRange = null;
      selectedItemType = null;
      selectedBottleType = null;
      _searchController.clear();
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
              body: const Center(
                child: Text('Please login to view your drops'),
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
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _showSearchDialog,
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
          body: Center(child: Text('Error loading user data: $error')),
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
        title: const Text('Collection History'),
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final controller = ref.read(historyControllerProvider.notifier);
          await controller.refresh();
        },
        child: historyAsync.when(
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
    ),
  );
}

 

  List<CollectorInteraction> _applyFilters(List<CollectorInteraction> interactions) {
    List<CollectorInteraction> filtered = interactions;
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((interaction) {
        final dropoff = interaction.dropoff;
        if (dropoff != null) {
          return dropoff.notes?.toLowerCase().contains(searchTerm) == true ||
                 dropoff.bottleType.toLowerCase().contains(searchTerm) ||
                 interaction.notes?.toLowerCase().contains(searchTerm) == true ||
                 interaction.cancellationReason?.toLowerCase().contains(searchTerm) == true;
        }
        return interaction.notes?.toLowerCase().contains(searchTerm) == true ||
               interaction.cancellationReason?.toLowerCase().contains(searchTerm) == true;
      }).toList();
    }

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

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((drop) {
        return drop.notes?.toLowerCase().contains(searchTerm) == true ||
               drop.bottleType.name.toLowerCase().contains(searchTerm) == true;
      }).toList();
    }

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
                      if (dropoff?.location != null) ...[
                        const SizedBox(width: 4), // Small gap between image and map
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
                                  // Static map image - using simple static map like drops tab
                                  Image.network(
                                    _getStaticMapUrl(LatLng(
                                      dropoff!.location.coordinates[1],
                                      dropoff.location.coordinates[0],
                                    )),
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
                                  // Custom pin overlay (always visible)
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
                      // Total amount
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total ${_formatLargeNumber((dropoff?.numberOfBottles ?? 0) + (dropoff?.numberOfCans ?? 0))}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[600],
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
                              color: Colors.white,
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
                              interaction.notes!,
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
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              // Static map image
                              Image.network(
                                _getStaticMapUrl(LatLng(
                                  drop.location.latitude,
                                  drop.location.longitude,
                                )),
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
                              // Custom pin overlay (always visible)
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
                        'Total ${_formatLargeNumber(drop.numberOfBottles + drop.numberOfCans)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[600],
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
              title: 'Created',
              subtitle: _formatDate(drop.createdAt),
              isCompleted: true,
              isActive: false,
              isLive: false,
              color: Colors.blue,
            ),
          ),
          // Step 2: Accepted
          Expanded(
            child: _buildLiveTimelineStep(
              icon: drop.status == DropStatus.collected
                  ? Icons.handshake
                  : Icons.check_circle,
              title: 'Accepted',
              subtitle: _getAcceptedSubtitle(drop),
              isCompleted: drop.status == DropStatus.accepted ||
                  drop.status == DropStatus.collected,
              isActive: drop.status == DropStatus.accepted,
              isLive: drop.status == DropStatus.accepted,
              color: Colors.green,
            ),
          ),
          // Step 3: Collected
          Expanded(
            child: _buildLiveTimelineStep(
              icon: Icons.recycling,
              title: 'Collected',
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
                      'Collector is on the way',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Estimated arrival: ${_getEstimatedTime()}',
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
                color: isCompleted ? color : Colors.grey[300],
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: color, width: 3) : null,
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
                      color: isCompleted ? Colors.white : Colors.grey[600],
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
                    border: Border.all(color: Colors.white, width: 2),
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
            color: isCompleted ? color : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
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
    switch (status) {
      case DropStatus.pending:
        return 'Waiting for collector';
      case DropStatus.accepted:
        return '🟢 Live - Collector on the way';
      case DropStatus.collected:
        return 'Collected';
      case DropStatus.cancelled:
        return '❌ Cancelled';
      case DropStatus.expired:
        return '⏰ Expired';
      case DropStatus.stale:
        return '🟤 Stale';
    }
  }

  Widget _buildAnimatedSandClock({double size = 20, Color? color}) {
    return _AnimatedSandClockWidget(
      size: size,
      color: color ?? Colors.orange,
    );
  }

  String _getLastUpdateText(Drop drop) {
    final now = TimezoneService.now();
    final diff = now.difference(TimezoneService.toGermanTime(drop.modifiedAt));
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String _getAcceptedSubtitle(Drop drop) {
    if (drop.status == DropStatus.accepted) {
      return 'Collector accepted';
    } else if (drop.status == DropStatus.collected) {
      return 'Was accepted';
    } else {
      return 'Waiting...';
    }
  }

  String _getCollectedSubtitle(Drop drop) {
    if (drop.status == DropStatus.collected) {
      return 'Collected';
    } else {
      return 'Not yet collected';
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
        title: Row(
          children: [
            const Icon(Icons.filter_list),
            const SizedBox(width: 8),
            const Text('Filter History'),
            if (_hasActiveFilters())
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
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
            children: [
              // Status filter
              _buildFilterDropdown(
                'Status',
                selectedStatus ?? 'All',
                statusOptions,
                (value) => setState(() => selectedStatus = value == 'All' ? null : value),
                isActive: selectedStatus != null,
              ),
              const SizedBox(height: 16),

              // Time range filter
              _buildFilterDropdown(
                'Time Range',
                selectedTimeRange ?? 'All Time',
                timeRangeOptions,
                (value) => setState(() => selectedTimeRange = value == 'All Time' ? null : value),
                isActive: selectedTimeRange != null,
              ),
              const SizedBox(height: 16),

              // Item type filter
              _buildFilterDropdown(
                'Item Type',
                selectedItemType ?? 'All Items',
                itemTypeOptions,
                (value) => setState(() => selectedItemType = value == 'All Items' ? null : value),
                isActive: selectedItemType != null,
              ),
              const SizedBox(height: 16),

              // Bottle type filter
              _buildFilterDropdown(
                'Bottle Type',
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
                _searchController.clear();
              });
              // No need to reload data since we're using client-side filtering
            },
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // No need to reload data since we're using client-side filtering
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return selectedStatus != null ||
           selectedTimeRange != null ||
           selectedItemType != null ||
           selectedBottleType != null ||
           _searchController.text.isNotEmpty;
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
            color: isActive ? Colors.blue : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: isActive ? Colors.blue : Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: isActive ? Colors.blue : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: isActive ? Colors.blue : Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixIcon: isActive ? const Icon(Icons.check_circle, color: Colors.blue) : null,
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search History'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by notes, bottle type, or cancellation reason...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {}); // Trigger rebuild to apply search filter
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {});
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Search'),
          ),
        ],
      ),
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
                          _buildDetailRow('Notes', interaction.notes!),
                        if (interaction.cancellationReason?.isNotEmpty == true)
                          _buildDetailRow('Cancellation Reason', interaction.cancellationReason!),
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
                          _buildEnhancedDetailRow('Bottle Type', drop.bottleType.name.toUpperCase(), Icons.category),
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
    switch (status.toLowerCase()) {
      case 'collected':
        return 'Collected';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    print('🕐 HistoryScreen._formatDate: Input date: $date');
    final germanDate = TimezoneService.toGermanTime(date);
    print('🕐 HistoryScreen._formatDate: German date: $germanDate');
    final now = TimezoneService.now();
    print('🕐 HistoryScreen._formatDate: Current German time: $now');
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(germanDate.year, germanDate.month, germanDate.day);
    
    // Format time as HH:mm
    final timeString = '${germanDate.hour.toString().padLeft(2, '0')}:${germanDate.minute.toString().padLeft(2, '0')}';
    print('🕐 HistoryScreen._formatDate: Time string: $timeString');
    
    if (dateOnly == today) {
      return 'Today at $timeString';
    } else if (dateOnly == yesterday) {
      return 'Yesterday at $timeString';
    } else {
      final difference = today.difference(dateOnly).inDays;
      
      if (difference < 7) {
        // Show day name for recent dates
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final dayName = dayNames[germanDate.weekday - 1];
        return '$dayName at $timeString';
      } else if (difference < 30) {
        // Show "X days ago" for older dates
        return '${difference}d ago at $timeString';
      } else {
        // Show full date for very old dates
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthName = monthNames[germanDate.month - 1];
        return '$monthName ${germanDate.day} at $timeString';
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
                    _searchController.clear();
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
    if (_searchController.text.isNotEmpty) {
      filters.add('Search: "${_searchController.text}"');
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
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          firstInteraction.dropoff!.imageUrl!,
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
                    // Placeholder when no image
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
                  const SizedBox(width: 8),

                  // Small map with pin
                  if (firstInteraction.dropoff?.location != null) ...[
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
                                _getStaticMapUrl(
                                  LatLng(
                                    firstInteraction.dropoff!.location.coordinates[1],
                                    firstInteraction.dropoff!.location.coordinates[0],
                                  ),
                                ),
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 120,
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
                              // Custom pin overlay
                              Positioned.fill(
                                child: Center(
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
                  // Total amount
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
                          if (interaction.notes?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              interaction.notes!,
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