import 'dart:ui';

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
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        
        // Note: 3-day cutoff is only for support tickets, not for user's own drops
        return true;
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
    
    Future<void> _maybeShowCensoredNotice(List<Drop> drops) async {
      // Only for household users
      final modeAsync = ref.read(userModeControllerProvider);
      if (!mounted) return;
      modeAsync.whenData((mode) async {
        if (mode != UserMode.household) return;
        if (drops.isEmpty) return;
        
        // Find first censored drop not previously shown
        final prefs = await SharedPreferences.getInstance();
        final censored = drops.firstWhere(
          (d) => d.isCensored && (prefs.getBool('censor_notice_${d.id}') != true),
          orElse: () => Drop.empty(),
        );
        if (censored.id.isEmpty) return;
        
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 380,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.purple, size: 28),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Your drop image was censored',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.grey),
                          tooltip: 'How warnings work',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Warning System'),
                                content: const Text(
                                  'Warnings accumulate and can lead to temporary or permanent account locks.\n\n'+
                                  '5 warnings: 24h lock\n10 warnings: 3 days\n15 warnings: 1 week\n20 warnings: 1 month\n25+ warnings: Permanent (until admin review).'
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))
                                ],
                              ),
                            );
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Image.network(censored.imageUrl, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.25),
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('CENSORED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Reason: ${censored.censorReason ?? 'Inappropriate image'}', style: const TextStyle(fontSize: 13, color: Colors.purple)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.recycling, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('${censored.numberOfBottles} bottles, ${censored.numberOfCans} cans', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('Created ${DateFormat('MMM d, yyyy – HH:mm').format(censored.createdAt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'A warning was added to your account for this drop. Please make sure future images follow the community guidelines.',
                        style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('censor_notice_${censored.id}', true);
                          if (mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Got it'),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      });
    }
    
    // Listen to user mode changes and refresh drops
    ref.listen(userModeControllerProvider, (previous, next) {
      next.whenData((mode) {
        // Refresh drops when user mode changes
        if (mounted) {
          _loadDrops();
        }
      });
    });

    // Subscribe to real-time drop_censored events
    ref.listen(notificationServiceProvider, (prev, next) {
      final service = next;
      service.onDropCensored = (dropId, reason) async {
        // Reload user drops and show the popup immediately for this drop if not shown before
        final auth = ref.read(authNotifierProvider).value;
        if (auth?.id != null) {
          await ref.read(dropsControllerProvider.notifier).loadUserDrops(auth!.id);
          final drops = ref.read(dropsControllerProvider).maybeWhen(data: (d) => d, orElse: () => <Drop>[]);
          final censored = drops.firstWhere((d) => d.id == dropId, orElse: () => Drop.empty());
          if (censored.id.isNotEmpty && mounted) {
            final prefs = await SharedPreferences.getInstance();
            if (prefs.getBool('censor_notice_${censored.id}') == true) return;
            await showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => _buildCensorDialog(context, censored),
            );
          }
        }
      };
    });

    return userMode.when(
      data: (mode) {
        return dropsState.when(
          data: (drops) {
            // Update all drops and apply filters
            if (_allDrops != drops) {
              _allDrops = drops;
              _applyFilters();
              // Show censored notice once when entering Drops tab (household)
              _maybeShowCensoredNotice(drops);
              
              // Sort drops by distance for collectors or by creation date for households after updating
              if (mode == UserMode.collector) {
                _sortDropsByDistance();
              } else if (mode == UserMode.household) {
                _sortDropsByCreationDate();
              }
            }

            // For collectors, apply both pending status and distance/date filters
            // Household: show all user drops (including censored) in My Drops list
            final displayDrops = mode == UserMode.household 
                ? _filteredDrops
                : _filteredDrops.where((drop) => drop.status == DropStatus.pending).toList();
            
            // Household: Tabbed view for Good, Cancelled/Flagged, Censored
            final isHousehold = mode == UserMode.household;
            // Use _allDrops for tab counts (not filtered drops) to get true counts
            final allDropsForTabs = isHousehold ? _allDrops : displayDrops;
            // Precompute filtered lists for counts and rendering
            // Good drops: only valid ones (pending/accepted, not suspicious, not censored, <3 cancellations)
            final goodDrops = isHousehold
                ? allDropsForTabs.where((d) =>
                    !d.isSuspicious && !d.isCensored && (d.cancellationCount) < 3 &&
                    (d.status == DropStatus.pending || d.status == DropStatus.accepted)
                  ).toList()
                : displayDrops;
            // Flagged/Cancelled: suspicious or cancelled 3+ times
            final flaggedDrops = isHousehold
                ? allDropsForTabs.where((d) => d.isSuspicious || (d.cancellationCount) >= 3).toList()
                : const <Drop>[];
            // Censored: only censored drops
            final censoredDrops = isHousehold
                ? allDropsForTabs.where((d) => d.isCensored).toList()
                : const <Drop>[];
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: isHousehold ? DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    Material(
                      color: Colors.white,
                      child: TabBar(
                        labelColor: const Color(0xFF00695C),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFF00695C),
                        tabs: [
                          Tab(text: 'Drops (${goodDrops.length})'),
                          Tab(text: 'Cancelled/Flagged (${flaggedDrops.length})'),
                          Tab(text: 'Censored (${censoredDrops.length})'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Good drops (pending/accepted, not suspicious, not censored, <3 cancellations)
                          CustomScrollView(
                            slivers: [
                              _buildHeader(mode, displayDrops),
                              SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: _buildDropsSliverList(
                                  allDropsForTabs.where((d) =>
                                    !d.isSuspicious && !d.isCensored && (d.cancellationCount) < 3 &&
                                    (d.status == DropStatus.pending || d.status == DropStatus.accepted)
                                  ).toList(),
                                  mode,
                                ),
                              ),
                            ],
                          ),
                          // Tab 2: Cancelled/Flagged
                          CustomScrollView(
                            slivers: [
                              _buildHeader(mode, displayDrops),
                              SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: _buildDropsSliverList(
                                  allDropsForTabs.where((d) => d.isSuspicious || (d.cancellationCount) >= 3).toList(),
                                  mode,
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.info_outline, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Drops in this tab were either cancelled or flagged due to multiple cancellations. Flagged drops are hidden from the map.',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                          // Tab 3: Censored
                          CustomScrollView(
                            slivers: [
                              _buildHeader(mode, displayDrops),
                              SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: _buildDropsSliverList(
                                  displayDrops.where((d) => d.isCensored).toList(),
                                  mode,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ) : CustomScrollView(
              slivers: [
                _buildHeader(mode, displayDrops),
                
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

  Dialog _buildCensorDialog(BuildContext context, Drop censored) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.purple, size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Your drop image was censored', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.grey),
                  tooltip: 'How warnings work',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Warning System'),
                        content: const Text(
                          'Warnings accumulate and can lead to temporary or permanent account locks.\n\n'
                          '5 warnings: 24h lock\n10 warnings: 3 days\n15 warnings: 1 week\n20 warnings: 1 month\n25+ warnings: Permanent (until admin review).'
                        ),
                        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
                      ),
                    );
                  },
                )
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Image.network(censored.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.25),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                      child: const Text('CENSORED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text('Reason: ${censored.censorReason ?? 'Inappropriate image'}', style: const TextStyle(fontSize: 13, color: Colors.purple)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.recycling, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text('${censored.numberOfBottles} bottles, ${censored.numberOfCans} cans', style: const TextStyle(fontSize: 13)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Created ${DateFormat('MMM d, yyyy – HH:mm').format(censored.createdAt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), border: Border.all(color: Colors.orange.withOpacity(0.2)), borderRadius: BorderRadius.circular(8)),
              child: const Text('A warning was added to your account for this drop. Please make sure future images follow the community guidelines.', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('censor_notice_${censored.id}', true);
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('Got it'),
              ),
            )
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

  // Shared header used in tabbed and single views
  SliverAppBar _buildHeader(UserMode mode, List<Drop> displayDrops) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              mode == UserMode.collector ? 'All Drops' : 'My Drops',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00695C),
                  ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              color: const Color(0xFF00695C),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDrops,
              color: const Color(0xFF00695C),
            ),
          ],
        ),
      ),
    );
  }
} 