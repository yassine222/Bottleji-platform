import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'package:botleji/features/drops/controllers/drops_controller.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/drops/presentation/widgets/drop_card.dart';
import 'package:botleji/features/drops/presentation/screens/edit_drop_screen.dart';
import 'package:botleji/features/navigation/presentation/screens/navigation_screen.dart';
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/core/widgets/account_lock_card.dart';

class DropsListScreen extends ConsumerStatefulWidget {
  const DropsListScreen({super.key});

  @override
  ConsumerState<DropsListScreen> createState() => _DropsListScreenState();
}

class _DropsListScreenState extends ConsumerState<DropsListScreen> {
  // Filter states
  DropStatus? _selectedStatus; // For household users
  
  // Account lock card state
  bool _lockCardDismissed = false;
  String _selectedDateFilter = 'All';
  String _selectedDistanceFilter = 'All'; // For collectors
  List<Drop> _allDrops = [];
  List<Drop> _filteredDrops = [];
  LatLng? _currentLocation;
  
  // Date filter options
  final List<String> _dateFilterOptions = [
    'All',
    'Today',
    'Last 7 days',
    'Last 30 days',
    'This month',
    'Last month',
  ];
  
  // Distance filter options
  final List<String> _distanceFilterOptions = [
    'All',
    'Within 1 km',
    'Within 3 km',
    'Within 5 km',
    'Within 10 km',
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    
    // Load drops when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDrops();
      
      // Listen for mode changes to reset lock card dismissed flag and show card
      ref.listen(userModeControllerProvider, (previous, next) {
        next.whenData((mode) {
          if (mode == UserMode.collector) {
            // Reset dismissed flag when switching to collector mode
            setState(() {
              _lockCardDismissed = false;
            });
            // Check lock status when switching to collector mode
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _checkLockStatus();
              }
            });
          }
        });
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load drops when dependencies change - delay to avoid build cycle issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDrops();
        _checkLockStatus();
      }
    });
  }
  
  void _checkLockStatus() {
    final userMode = ref.read(userModeControllerProvider).value;
    final user = ref.read(authNotifierProvider).value;
    
    // Only show lock card if in collector mode and account is locked
    if (userMode == UserMode.collector && 
        user != null && 
        user.isCurrentlyLocked && 
        user.accountLockedUntil != null &&
        !_lockCardDismissed) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: AccountLockCard(
            lockedUntil: user.accountLockedUntil!,
            onDismiss: () {
              setState(() {
                _lockCardDismissed = true;
              });
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }

  Future<void> _initializeLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      // Sort drops by distance after getting location
      _sortDropsByDistance();
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  double _calculateDistance(LatLng dropLocation) {
    if (_currentLocation == null) return double.infinity;
    
    return Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      dropLocation.latitude,
      dropLocation.longitude,
    );
  }

  Future<void> _loadDrops() async {
    // Clear drops first to prevent showing cached drops from other modes
    ref.read(dropsControllerProvider.notifier).clearDrops();
    
    final userMode = ref.read(userModeControllerProvider);
    final authState = ref.read(authNotifierProvider);
    
    userMode.whenData((mode) async {
      if (mode == UserMode.collector) {
        // Load only available drops for collectors (pending and cancelled, not suspicious)
        final collectorId = authState.value?.id;
        await ref.read(dropsControllerProvider.notifier).loadDropsAvailableForCollectors(
          excludeCollectorId: collectorId,
        );
      } else if (mode == UserMode.household) {
        // Load user's own drops for households
        if (authState.value?.id != null) {
          await ref.read(dropsControllerProvider.notifier).loadUserDrops(authState.value!.id);
        } else {
          // Clear drops if no user ID
          ref.read(dropsControllerProvider.notifier).clearDrops();
        }
      }
    });
  }

  void _sortDropsByDistance() {
    final userMode = ref.read(userModeControllerProvider);
    userMode.whenData((mode) {
      if (mode == UserMode.collector && _currentLocation != null) {
        setState(() {
          _filteredDrops.sort((a, b) {
            final distanceA = _calculateDistance(a.location);
            final distanceB = _calculateDistance(b.location);
            return distanceA.compareTo(distanceB); // Sort by distance (nearest first)
          });
        });
      }
    });
  }

  void _sortDropsByCreationDate() {
    final userMode = ref.read(userModeControllerProvider);
    userMode.whenData((mode) {
      if (mode == UserMode.household) {
        setState(() {
          _filteredDrops.sort((a, b) {
            return b.createdAt.compareTo(a.createdAt); // Sort by creation date (newest first)
          });
        });
      }
    });
  }

    void _applyFilters() {
    setState(() {
      _filteredDrops = _allDrops.where((drop) {
        // Status filter (for household users)
        if (_selectedStatus != null && drop.status != _selectedStatus) {
          return false;
        }
        
        // Date filter
        if (_selectedDateFilter != 'All') {
          final dropDate = drop.createdAt;
          final now = DateTime.now();
          
          switch (_selectedDateFilter) {
            case 'Today':
              final today = DateTime(now.year, now.month, now.day);
              final dropDay = DateTime(dropDate.year, dropDate.month, dropDate.day);
              if (dropDay != today) return false;
              break;
            case 'Last 7 days':
              final weekAgo = now.subtract(const Duration(days: 7));
              if (dropDate.isBefore(weekAgo)) return false;
              break;
            case 'Last 30 days':
              final monthAgo = now.subtract(const Duration(days: 30));
              if (dropDate.isBefore(monthAgo)) return false;
              break;
            case 'This month':
              final thisMonth = DateTime(now.year, now.month, 1);
              if (dropDate.isBefore(thisMonth)) return false;
              break;
            case 'Last month':
              final lastMonth = DateTime(now.year, now.month - 1, 1);
              final thisMonth = DateTime(now.year, now.month, 1);
              if (dropDate.isBefore(lastMonth) || dropDate.isAfter(thisMonth)) return false;
              break;
          }
        }
        
        // Distance filter (for collectors)
        if (_selectedDistanceFilter != 'All') {
          final distance = _calculateDistance(drop.location);
          double maxDistance;
          
          switch (_selectedDistanceFilter) {
            case 'Within 1 km':
              maxDistance = 1000;
              break;
            case 'Within 3 km':
              maxDistance = 3000;
              break;
            case 'Within 5 km':
              maxDistance = 5000;
              break;
            case 'Within 10 km':
              maxDistance = 10000;
              break;
            default:
              maxDistance = double.infinity;
          }
          
          if (distance > maxDistance) return false;
        }
        
        // Enforce 3-day cutoff for household mode
        final userMode = ref.read(userModeControllerProvider);
        bool within3Days = true;
        userMode.whenData((mode) {
          if (mode == UserMode.household) {
            final cutoff = DateTime.now().subtract(const Duration(days: 3));
            if (drop.createdAt.isBefore(cutoff)) {
              within3Days = false;
            }
          }
        });

        return within3Days;
      }).toList();
      
      // Sort drops by distance for collectors (nearest first) or by creation date for households (newest first)
      final userMode = ref.read(userModeControllerProvider);
      userMode.whenData((mode) {
        if (mode == UserMode.collector && _currentLocation != null) {
          _filteredDrops.sort((a, b) {
            final distanceA = _calculateDistance(a.location);
            final distanceB = _calculateDistance(b.location);
            return distanceA.compareTo(distanceB); // Sort by distance (nearest first)
          });
        } else if (mode == UserMode.household) {
          _filteredDrops.sort((a, b) {
            return b.createdAt.compareTo(a.createdAt); // Sort by creation date (newest first)
          });
        }
      });
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDateFilter = 'All';
      _selectedDistanceFilter = 'All';
      _filteredDrops = _allDrops;
      
      // Sort drops by distance for collectors (nearest first) or by creation date for households (newest first) even when clearing filters
      final userMode = ref.read(userModeControllerProvider);
      userMode.whenData((mode) {
        if (mode == UserMode.collector && _currentLocation != null) {
          _filteredDrops.sort((a, b) {
            final distanceA = _calculateDistance(a.location);
            final distanceB = _calculateDistance(b.location);
            return distanceA.compareTo(distanceB); // Sort by distance (nearest first)
          });
        } else if (mode == UserMode.household) {
          _filteredDrops.sort((a, b) {
            return b.createdAt.compareTo(a.createdAt); // Sort by creation date (newest first)
          });
        }
      });
    });
  }

  void _showFilterDialog() {
    final userMode = ref.read(userModeControllerProvider);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Drops'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status filter (for household users)
              if (userMode.value == UserMode.household) ...[
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedStatus == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = null;
                        });
                      },
                    ),
                    ...DropStatus.values.map((status) => FilterChip(
                      label: Text(status.name.toUpperCase()),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = selected ? status : null;
                        });
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Date filter
              const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDateFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _dateFilterOptions.map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDateFilter = value!;
                  });
                },
              ),
              
              // Distance filter (only for collectors)
              if (userMode.value == UserMode.collector) ...[
                const SizedBox(height: 16),
                const Text('Distance:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDistanceFilter,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _distanceFilterOptions.map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDistanceFilter = value!;
                    });
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilters();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDropDialog(Drop drop) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDropScreen(drop: drop),
      ),
    );
    
    // Refresh drops if edit was successful or drop was deleted
    if (result == true || result == 'deleted') {
      _loadDrops();
    }
  }

  void _showDeleteConfirmation(Drop drop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Drop'),
        content: const Text(
          'Are you sure you want to delete this drop? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDrop(drop);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDrop(Drop drop) async {
    try {
      await ref.read(dropsControllerProvider.notifier).deleteDrop(drop.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drop deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting drop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptDrop(Drop drop) async {
    try {
      print('🔍 Accepting drop: ${drop.id}');
      
      final authState = ref.read(authNotifierProvider);
      final user = authState.value;
      final collectorId = user?.id;
      
      if (collectorId == null) {
        throw Exception('Collector ID not found');
      }
      
      // Check if account is locked
      if (user?.isCurrentlyLocked ?? false) {
        if (mounted && user?.accountLockedUntil != null) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: AccountLockCard(
                lockedUntil: user!.accountLockedUntil!,
                onDismiss: () => Navigator.of(context).pop(),
              ),
            ),
          );
        }
        return;
      }

      // Assign the collector to the drop
      await ref.read(dropsControllerProvider.notifier).assignCollector(drop.id, collectorId);
      print('✅ Collector assigned to drop');
      
      // Start the collection - this will persist the state
      await ref.read(navigationControllerProvider.notifier).startCollection(
        destination: drop.location,
        dropId: drop.id,
        dropoffId: drop.id, // Using drop.id as dropoffId for now
        imageUrl: drop.imageUrl,
        numberOfBottles: drop.numberOfBottles,
        numberOfCans: drop.numberOfCans,
        bottleType: drop.bottleType.name,
        notes: drop.notes,
        leaveOutside: drop.leaveOutside,
        routeDuration: null, // Will be set by navigation screen
        routeDistance: null, // Will be set by navigation screen
        collectorId: collectorId, // Add collector ID
      );
      print('✅ Collection started and saved');
      
      // Track active collection for smart support
      print('✅ Active collection tracked for smart support');
      
      if (mounted) {
        // Navigate to navigation screen and replace the current route
        // This prevents going back to the drops list
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NavigationScreen(
              destination: drop.location,
              dropId: drop.id,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error accepting drop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting drop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userMode = ref.watch(userModeControllerProvider);
    final dropsState = ref.watch(dropsControllerProvider);
    
    // Listen to user mode changes and refresh drops
    ref.listen(userModeControllerProvider, (previous, next) {
      next.whenData((mode) {
        // Refresh drops when user mode changes
        if (mounted) {
          _loadDrops();
        }
      });
    });

    return userMode.when(
      data: (mode) {
        return dropsState.when(
          data: (drops) {
            // Update all drops and apply filters
            if (_allDrops != drops) {
              _allDrops = drops;
              _applyFilters();
              
              // Sort drops by distance for collectors or by creation date for households after updating
              if (mode == UserMode.collector) {
                _sortDropsByDistance();
              } else if (mode == UserMode.household) {
                _sortDropsByCreationDate();
              }
            }

            // For collectors, apply both pending status and distance/date filters
            final displayDrops = mode == UserMode.household 
                ? _filteredDrops 
                : _filteredDrops.where((drop) => drop.status == DropStatus.pending).toList();
            
            return CustomScrollView(
              slivers: [
                // Sliver App Bar - Collapsible header
                SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: false,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  toolbarHeight: 80,
                  automaticallyImplyLeading: false, // Remove the back/drawer button
                  flexibleSpace: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          mode == UserMode.collector ? 'All Drops' : 'My Drops',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00695C), // Green color
                          ),
                        ),
                        const Spacer(),
                        // Filter button
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _showFilterDialog,
                          color: const Color(0xFF00695C), // Green color
                        ),
                        // Refresh button
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadDrops,
                          color: const Color(0xFF00695C), // Green color
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Filter summary (if filters are applied)
                if ((mode == UserMode.household && (_selectedStatus != null || _selectedDateFilter != 'All')) ||
                    (mode == UserMode.collector && (_selectedDateFilter != 'All' || _selectedDistanceFilter != 'All')))
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.filter_list, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Filters Applied',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: _clearFilters,
                                child: const Text('Clear All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (_selectedStatus != null)
                                Chip(
                                  label: Text('Status: ${_selectedStatus!.name.toUpperCase()}'),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedStatus = null;
                                      _applyFilters();
                                    });
                                  },
                                ),
                              if (_selectedDateFilter != 'All')
                                Chip(
                                  label: Text('Date: $_selectedDateFilter'),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedDateFilter = 'All';
                                      _applyFilters();
                                    });
                                  },
                                ),
                              if (_selectedDistanceFilter != 'All')
                                Chip(
                                  label: Text('Distance: $_selectedDistanceFilter'),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedDistanceFilter = 'All';
                                      _applyFilters();
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mode == UserMode.collector
                                ? 'Showing ${displayDrops.length} of ${_allDrops.where((drop) => drop.status == DropStatus.pending).length} pending drops'
                                : 'Showing ${displayDrops.length} of ${_allDrops.length} drops',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Drops list
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: _buildDropsSliverList(displayDrops, mode),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading drops',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadDrops,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading user mode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropsSliverList(List<Drop> drops, UserMode mode) {
    // Check if there's an active collection for collectors
    final hasActiveCollection = mode == UserMode.collector && 
        ref.watch(navigationControllerProvider) != null;

    if (drops.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                mode == UserMode.collector 
                    ? Icons.location_off 
                    : Icons.add_location,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                mode == UserMode.collector 
                    ? (_selectedDateFilter != 'All' || _selectedDistanceFilter != 'All')
                        ? 'No drops match your filters'
                        : 'No drops available'
                    : (_selectedStatus != null || _selectedDateFilter != 'All')
                        ? 'No drops match your filters'
                        : 'No drops created yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mode == UserMode.collector 
                    ? (_selectedDateFilter != 'All' || _selectedDistanceFilter != 'All')
                        ? 'Try adjusting your filters'
                        : 'Check back later for new drops'
                    : (_selectedStatus != null || _selectedDateFilter != 'All')
                        ? 'Try adjusting your filters'
                        : 'Create your first drop to get started',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              if ((mode == UserMode.household && (_selectedStatus != null || _selectedDateFilter != 'All')) ||
                  (mode == UserMode.collector && (_selectedDateFilter != 'All' || _selectedDistanceFilter != 'All')))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: FilledButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final drop = drops[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropCard(
              key: ValueKey(drop.id), // Add key for better widget recycling
              drop: drop,
              showActions: mode == UserMode.collector,
              currentLocation: _currentLocation,
              hasActiveCollection: hasActiveCollection,
              onStatusUpdate: mode == UserMode.collector 
                  ? (newStatus) async {
                      if (newStatus == DropStatus.accepted) {
                        await _acceptDrop(drop);
                      } else {
                        await ref.read(dropsControllerProvider.notifier)
                            .updateDropStatus(drop.id, newStatus);
                        _loadDrops();
                      }
                    }
                  : (newStatus) async {
                      await ref.read(dropsControllerProvider.notifier)
                          .updateDropStatus(drop.id, newStatus);
                      _loadDrops();
                    },
              onEdit: mode == UserMode.household ? () => _showEditDropDialog(drop) : null,
              onDelete: mode == UserMode.household && drop.status == DropStatus.pending 
                  ? () => _showDeleteConfirmation(drop) 
                  : null,
            ),
          );
        },
        childCount: drops.length,
      ),
    );
  }
} 