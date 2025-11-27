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
import 'package:botleji/l10n/app_localizations.dart';

class DropsListScreen extends ConsumerStatefulWidget {
  final String? initialFilter; // Optional initial filter (e.g., "Active")
  
  const DropsListScreen({super.key, this.initialFilter});

  @override
  ConsumerState<DropsListScreen> createState() => _DropsListScreenState();
}

class _DropsListScreenState extends ConsumerState<DropsListScreen> {
  // Filter states
  DropStatus? _selectedStatus; // For household users
  
  // Chip filter for household users
  String? _selectedChipFilter;
  bool _filterInitialized = false;
  
  // Account lock card state
  bool _lockCardDismissed = false;
  String _selectedDateFilter = 'All';
  String _selectedDistanceFilter = 'All'; // For collectors
  List<Drop> _allDrops = [];
  List<Drop> _filteredDrops = [];
  LatLng? _currentLocation;
  
  // Track censored drops that have been shown in this session to prevent duplicate popups
  final Set<String> _shownCensoredDropIds = {};
  
  // Prevent multiple simultaneous loads
  bool _isLoadingDrops = false;
  
  // Date filter options - will be localized in the UI
  List<String> _getDateFilterOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.all,
      l10n.today,
      l10n.last7Days,
      l10n.last30Days,
      l10n.thisMonth,
      l10n.lastMonth,
    ];
  }
  
  // Distance filter options - will be localized in the UI
  List<String> _getDistanceFilterOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.all,
      l10n.within1Km,
      l10n.within3Km,
      l10n.within5Km,
      l10n.within10Km,
    ];
  }
  
  // Helper to get the filter key from localized string
  String _getDateFilterKey(String localizedValue, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (localizedValue == l10n.all) return 'All';
    if (localizedValue == l10n.today) return 'Today';
    if (localizedValue == l10n.last7Days) return 'Last 7 days';
    if (localizedValue == l10n.last30Days) return 'Last 30 days';
    if (localizedValue == l10n.thisMonth) return 'This month';
    if (localizedValue == l10n.lastMonth) return 'Last month';
    return localizedValue; // Fallback to original if not found
  }
  
  // Helper to get the distance filter key from localized string
  String _getDistanceFilterKey(String localizedValue, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (localizedValue == l10n.all) return 'All';
    if (localizedValue == l10n.within1Km) return 'Within 1 km';
    if (localizedValue == l10n.within3Km) return 'Within 3 km';
    if (localizedValue == l10n.within5Km) return 'Within 5 km';
    if (localizedValue == l10n.within10Km) return 'Within 10 km';
    return localizedValue; // Fallback to original if not found
  }
  
  // Helper to get localized string from filter key
  String _getLocalizedDateFilter(String key, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'All':
        return l10n.all;
      case 'Today':
        return l10n.today;
      case 'Last 7 days':
        return l10n.last7Days;
      case 'Last 30 days':
        return l10n.last30Days;
      case 'This month':
        return l10n.thisMonth;
      case 'Last month':
        return l10n.lastMonth;
      default:
        return key;
    }
  }
  
  // Helper to get localized string from distance filter key
  String _getLocalizedDistanceFilter(String key, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'All':
        return l10n.all;
      case 'Within 1 km':
        return l10n.within1Km;
      case 'Within 3 km':
        return l10n.within3Km;
      case 'Within 5 km':
        return l10n.within5Km;
      case 'Within 10 km':
        return l10n.within10Km;
      default:
        return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    
    // Load drops when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDrops();
      if (mounted) _checkLockStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize filter with localized string only once
    if (!_filterInitialized) {
      // Use initialFilter if provided, otherwise default to "Active"
      if (widget.initialFilter != null) {
        _selectedChipFilter = widget.initialFilter;
      } else {
        _selectedChipFilter = AppLocalizations.of(context).active;
      }
      _filterInitialized = true;
    }
    // Don't reload drops in didChangeDependencies to prevent infinite loops
    // Drops are already loaded in initState
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
    // Prevent multiple simultaneous loads
    if (_isLoadingDrops) return;
    _isLoadingDrops = true;
    
    try {
      // Clear drops first to prevent showing cached drops from other modes
      ref.read(dropsControllerProvider.notifier).clearDrops();
    
    final userMode = ref.read(userModeControllerProvider);
    final authState = ref.read(authNotifierProvider);
    
      await userMode.when(
        data: (mode) async {
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
        },
        loading: () async {},
        error: (_, __) async {},
      );
    } finally {
      // Always reset loading flag
      if (mounted) {
        _isLoadingDrops = false;
      }
    }
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
        
        // Hide very close drops (< 100m) for collectors to prevent navigation crashes
        final userMode = ref.read(userModeControllerProvider);
        if (userMode.value == UserMode.collector && _currentLocation != null) {
          final distance = _calculateDistance(drop.location);
          if (distance < 100.0) return false; // Hide drops less than 100m
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
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final dateOptions = _getDateFilterOptions(context);
          final distanceOptions = _getDistanceFilterOptions(context);
          final currentDateFilterLocalized = _getLocalizedDateFilter(_selectedDateFilter, context);
          final currentDistanceFilterLocalized = _getLocalizedDistanceFilter(_selectedDistanceFilter, context);
          
          return AlertDialog(
            title: Text(l10n.filterDrops),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status filter (for household users)
                if (userMode.value == UserMode.household) ...[
                  Text('${l10n.status}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: Text(l10n.all),
                        selected: _selectedStatus == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = null;
                          });
                        },
                      ),
                      ...DropStatus.values.map((status) => FilterChip(
                        label: Text(status.localizedDisplayName(context)),
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
                Text('${l10n.date}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: currentDateFilterLocalized,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: dateOptions.map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDateFilter = _getDateFilterKey(value!, context);
                    });
                  },
                ),
                
                // Distance filter (only for collectors)
                if (userMode.value == UserMode.collector) ...[
                  const SizedBox(height: 16),
                  Text('${l10n.distance}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: currentDistanceFilterLocalized,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: distanceOptions.map((option) => DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDistanceFilter = _getDistanceFilterKey(value!, context);
                      });
                    },
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _applyFilters();
                },
                child: Text(l10n.apply),
              ),
            ],
          );
        },
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
        
        // Find first censored drop not previously shown (check both SharedPreferences and session cache)
        final prefs = await SharedPreferences.getInstance();
        final censored = drops.firstWhere(
          (d) => d.isCensored && 
                 (prefs.getBool('censor_notice_${d.id}') != true) &&
                 !_shownCensoredDropIds.contains(d.id),
          orElse: () => Drop.empty(),
        );
        if (censored.id.isEmpty) return;
        
        // Mark as shown in this session immediately to prevent duplicate popups
        _shownCensoredDropIds.add(censored.id);
        
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
                        Text('Created ${_formatRelativeDate(censored.createdAt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                          // Already marked in session cache, just close dialog
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
            // Check both SharedPreferences and session cache
            if (prefs.getBool('censor_notice_${censored.id}') == true || _shownCensoredDropIds.contains(censored.id)) {
              return;
            }
            // Mark as shown in this session immediately
            _shownCensoredDropIds.add(censored.id);
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
            
            // Household: Modern chip-based filter system
            final isHousehold = mode == UserMode.household;
            // Use the same baseline as the visible list for counts to avoid mismatches
            final allDropsForTabs = displayDrops;
            // Precompute filtered lists for counts and rendering
            // Good drops: only active drops (pending or accepted, not suspicious, not censored, not stale, <3 cancellations)
            final goodDrops = isHousehold
                ? allDropsForTabs.where((d) =>
                    !d.isSuspicious && !d.isCensored && (d.cancellationCount) < 3 &&
                    (d.status == DropStatus.pending || d.status == DropStatus.accepted) && d.status != DropStatus.stale
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
            // Stale: drops with stale status (excluding censored)
            final staleDrops = isHousehold
                ? allDropsForTabs.where((d) => d.status == DropStatus.stale && !d.isCensored).toList()
                : const <Drop>[];
            // Collected: drops with collected status
            final collectedDrops = isHousehold
                ? allDropsForTabs.where((d) => d.status == DropStatus.collected).toList()
                : const <Drop>[];

            // Debug counts to diagnose mismatches
            if (isHousehold) {
              // Using microtasks to avoid build spam
              Future.microtask(() {
                debugPrint('🔢 Drops tab debug — totals: all=${_allDrops.length}, display=${displayDrops.length}, good=${goodDrops.length}, flagged=${flaggedDrops.length}, censored=${censoredDrops.length}');
                final badInGood = allDropsForTabs.where((d) =>
                  (d.isCensored || d.isSuspicious || d.cancellationCount >= 3 || (d.status != DropStatus.pending && d.status != DropStatus.accepted))
                ).length;
                debugPrint('🔢 Drops tab debug — invalid in baseline (should be excluded from good): $badInGood');
              });
            }
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: isHousehold ? _buildHouseholdDropsWithChips(
                mode, 
                displayDrops, 
                goodDrops, 
                flaggedDrops, 
                censoredDrops, 
                staleDrops,
                collectedDrops
              ) : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
          child: _buildHeader(mode, displayDrops),
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
                                  label: Text('${AppLocalizations.of(context).status}: ${_selectedStatus!.localizedDisplayName(context)}'),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedStatus = null;
                                      _applyFilters();
                                    });
                                  },
                                ),
                              if (_selectedDateFilter != 'All')
                                Chip(
                                  label: Text('${AppLocalizations.of(context).date}: ${_getLocalizedDateFilter(_selectedDateFilter, context)}'),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedDateFilter = 'All';
                                      _applyFilters();
                                    });
                                  },
                                ),
                              if (_selectedDistanceFilter != 'All')
                                Chip(
                                  label: Text('${AppLocalizations.of(context).distance}: ${_getLocalizedDistanceFilter(_selectedDistanceFilter, context)}'),
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
                
                // Bottom padding to prevent bottom nav bar interference
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 100, // Bottom nav height + extra padding
                  ),
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
              Text('Created ${_formatRelativeDate(censored.createdAt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                  // Already marked in session cache, just close dialog
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
      final l10n = AppLocalizations.of(context);
      String titleText;
      String subtitleText;
      
      if (mode == UserMode.collector) {
        // Collector mode
        if (_selectedDateFilter != 'All' || _selectedDistanceFilter != 'All') {
          titleText = l10n.noDropsMatchYourFilters;
          subtitleText = l10n.tryAdjustingYourFilters;
        } else {
          titleText = l10n.noDropsAvailable;
          subtitleText = l10n.checkBackLaterForNewDrops;
        }
      } else {
        // Household mode - change message based on selected chip filter
        if (_selectedDateFilter != 'All') {
          // Date filter is active
          titleText = l10n.noDropsMatchYourFilters;
          subtitleText = l10n.tryAdjustingYourFilters;
        } else {
          // No date filter - check chip filter
          final filterKey = _getFilterKey(_selectedChipFilter ?? l10n.active);
          switch (filterKey) {
            case 'Active':
              titleText = l10n.noActiveDrops;
              subtitleText = l10n.createYourFirstDropToGetStarted;
              break;
            case 'Collected':
              titleText = l10n.noCollectedDrops;
              subtitleText = '';
              break;
            case 'Stale':
              titleText = l10n.noStaleDrops;
              subtitleText = '';
              break;
            case 'Censored':
              titleText = l10n.noCensoredDrops;
              subtitleText = '';
              break;
            case 'Flagged':
              titleText = l10n.noFlaggedDrops;
              subtitleText = '';
              break;
            default:
              titleText = l10n.noDropsCreatedYet;
              subtitleText = l10n.createYourFirstDropToGetStarted;
          }
        }
      }
      
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
                titleText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              if (subtitleText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitleText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if ((mode == UserMode.household && (_selectedStatus != null || _selectedDateFilter != 'All')) ||
                  (mode == UserMode.collector && (_selectedDateFilter != 'All' || _selectedDistanceFilter != 'All')))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: FilledButton(
                    onPressed: _clearFilters,
                    child: Text(l10n.clearFilters),
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
              isHousehold: mode == UserMode.household,
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
              onEdit: mode == UserMode.household && !drop.isSuspicious && !drop.isCensored && drop.cancellationCount < 3
                  ? () => _showEditDropDialog(drop) 
                  : null,
              onDelete: mode == UserMode.household && drop.status == DropStatus.pending && !drop.isSuspicious && !drop.isCensored && drop.cancellationCount < 3
                  ? () => _showDeleteConfirmation(drop) 
                  : null,
            ),
          );
        },
        childCount: drops.length,
      ),
    );
  }

  // Simple header widget
  Widget _buildHeader(UserMode mode, List<Drop> displayDrops) {
    return Container(
      decoration: BoxDecoration(
        
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            mode == UserMode.collector ? AppLocalizations.of(context).allDrops : AppLocalizations.of(context).myDrops,
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
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    
    final dateOnly = DateTime(date.year, date.month, date.day);
    final timeStr = DateFormat('h:mm a').format(date);
    
    if (dateOnly == today) {
      return 'Today at $timeStr';
    } else if (dateOnly == yesterday) {
      return 'Yesterday at $timeStr';
    } else if (dateOnly == twoDaysAgo) {
      return '2 days ago';
    } else if (dateOnly == threeDaysAgo) {
      return '3 days ago';
    } else {
      // More than 3 days ago - show exact date
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  Widget _buildHouseholdDropsWithChips(
    UserMode mode,
    List<Drop> displayDrops,
    List<Drop> goodDrops,
    List<Drop> flaggedDrops,
    List<Drop> censoredDrops,
    List<Drop> staleDrops,
    List<Drop> collectedDrops,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(mode, displayDrops),
        ),
        
        // Info message based on selected filter - moved to top for better visibility
        if ((_selectedChipFilter ?? AppLocalizations.of(context).active) != AppLocalizations.of(context).active)
          SliverToBoxAdapter(
            child: _buildInfoMessage(),
          ),
        
        // Modern chip filter section
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(AppLocalizations.of(context).active, goodDrops.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppLocalizations.of(context).collected, collectedDrops.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppLocalizations.of(context).flagged, flaggedDrops.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppLocalizations.of(context).censored, censoredDrops.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppLocalizations.of(context).stale, staleDrops.length),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        
        // Drops list based on selected filter
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: _buildFilteredDropsList(),
        ),
        
        
        // Bottom padding to prevent bottom nav bar interference
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).padding.bottom + 100, // Bottom nav height + extra padding
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = (_selectedChipFilter ?? AppLocalizations.of(context).active) == label;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedChipFilter = selected ? label : AppLocalizations.of(context).active;
        });
      },
      selectedColor: const Color(0xFF00695C).withOpacity(0.2),
      checkmarkColor: const Color(0xFF00695C),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF00695C) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF00695C) : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  String _getFilterKey(String? localizedLabel) {
    if (localizedLabel == null) return 'Active';
    final l10n = AppLocalizations.of(context);
    if (localizedLabel == l10n.active) return 'Active';
    if (localizedLabel == l10n.collected) return 'Collected';
    if (localizedLabel == l10n.flagged) return 'Flagged';
    if (localizedLabel == l10n.censored) return 'Censored';
    if (localizedLabel == l10n.stale) return 'Stale';
    return 'Active'; // default
  }

  Widget _buildFilteredDropsList() {
    List<Drop> filteredDrops = [];
    final filterKey = _getFilterKey(_selectedChipFilter);
    
    switch (filterKey) {
      case 'All':
        filteredDrops = _allDrops;
        break;
      case 'Active':
        filteredDrops = _allDrops.where((d) =>
          !d.isSuspicious && !d.isCensored && (d.cancellationCount) < 3 &&
          (d.status == DropStatus.pending || d.status == DropStatus.accepted) && d.status != DropStatus.stale
        ).toList();
        // Sort: accepted drops first, then pending drops
        filteredDrops.sort((a, b) {
          if (a.status == DropStatus.accepted && b.status != DropStatus.accepted) {
            return -1; // a comes first
          } else if (a.status != DropStatus.accepted && b.status == DropStatus.accepted) {
            return 1; // b comes first
          }
          // If both have same status, maintain original order (by creation date)
          return 0;
        });
        break;
      case 'Collected':
        filteredDrops = _allDrops.where((d) => d.status == DropStatus.collected).toList();
        break;
      case 'Flagged':
        filteredDrops = _allDrops.where((d) => d.isSuspicious || (d.cancellationCount) >= 3).toList();
        break;
      case 'Censored':
        filteredDrops = _allDrops.where((d) => d.isCensored).toList();
        break;
      case 'Stale':
        filteredDrops = _allDrops.where((d) => d.status == DropStatus.stale && !d.isCensored).toList();
        break;
    }
    
    return _buildDropsSliverList(filteredDrops, UserMode.household);
  }

  Widget _buildInfoMessage() {
    String message = '';
    Color iconColor = Colors.grey;
    final filterKey = _getFilterKey(_selectedChipFilter ?? AppLocalizations.of(context).active);
    
    switch (filterKey) {
      case 'Collected':
        message = AppLocalizations.of(context).dropsInThisFilterCollected;
        iconColor = Colors.green;
        break;
      case 'Flagged':
        message = AppLocalizations.of(context).dropsInThisFilterFlagged;
        iconColor = Colors.red;
        break;
      case 'Censored':
        message = AppLocalizations.of(context).dropsInThisFilterCensored;
        iconColor = Colors.orange;
        break;
      case 'Stale':
        message = AppLocalizations.of(context).dropsInThisFilterStale;
        iconColor = Colors.brown;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: iconColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 