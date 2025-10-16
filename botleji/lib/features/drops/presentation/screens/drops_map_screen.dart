// Drops Map Screen - Shows drops on map with route functionality for collectors
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'package:botleji/features/drops/controllers/drops_controller.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/navigation/presentation/screens/navigation_screen.dart'; // Added import for NavigationScreen
import 'package:botleji/features/navigation/controllers/navigation_controller.dart'; // Added import for navigationControllerProvider
import 'package:botleji/core/widgets/account_lock_card.dart';

class DropsMapScreen extends ConsumerStatefulWidget {
  const DropsMapScreen({super.key});

  @override
  ConsumerState<DropsMapScreen> createState() => _DropsMapScreenState();
}

class _DropsMapScreenState extends ConsumerState<DropsMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  
  // Add map key for forced rebuilding (like home screen)
  int _mapKey = 0;
  File? _selectedImage;
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = true;
  
  // Account lock card state
  bool _lockCardDismissed = false;
  
  // Custom marker icon
  BitmapDescriptor? _customDropMarker;
  
  // Form fields
  int _numberOfBottles = 1;
  int _numberOfCans = 1;
  BottleType _bottleType = BottleType.plastic;
  String _notes = '';
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 2) % 24,
    minute: TimeOfDay.now().minute);
  bool _leaveOutside = false;

  // Focus nodes for keyboard navigation
  final FocusNode _bottlesFocusNode = FocusNode();
  final FocusNode _cansFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();
  
  // Route functionality
  bool _showRoute = false;
  String? _routeDistance;
  String? _routeDuration;
  Drop? _selectedDropForRoute;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker(); // Load custom marker icon
    _initializeLocation();
    _loadDropsForMap();
    
    // Listen for mode changes to reset lock card dismissed flag and show card
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    
    // Add a test polyline immediately for debugging
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final testPoints = [
        const LatLng(52.27307215605556, 10.508999931699236),
        const LatLng(52.27307215605556 + 0.01, 10.508999931699236 + 0.01),
      ];
      
      
      final testPolyline = Polyline(
        polylineId: const PolylineId('init_test'),
        color: Colors.blue,
        width: 15,
        points: testPoints,
        );
      
      setState(() {
        _polylines.add(testPolyline);
        _showRoute = true;
        _routeDistance = 'Init Test';
        _routeDuration = 'Blue Line';
      });
    });
    
    // Listen to user mode changes and refresh drops
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen(userModeControllerProvider, (previous, next) {
        next.whenData((mode) {
          // Refresh drops when user mode changes
          _loadDropsForMap();
        });
      });
    });
  }

  Future<void> _initializeLocation() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them in your device settings.';
          _isLoading = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied. Please enable them in your device settings.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied. Please enable them in your device settings.';
          _isLoading = false;
        });
        return;
      }

      // Try to get location with retry logic
      LatLng? location = await _getLocationWithRetry();
      
      if (location == null) {
        // Try to get last known position as fallback
        try {
          final lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            location = LatLng(lastPosition.latitude, lastPosition.longitude);
            print('🔍 DropsMap: Using last known location as fallback');
          }
        } catch (e) {
          print('🔍 DropsMap: Could not get last known position: $e');
        }
      }

      if (location == null) {
        setState(() {
          _errorMessage = 'Unable to get your location. Please check your location settings and try again.';
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _currentLocation = location;
          _isLoading = false;
          _errorMessage = null;
        });

        // If map controller exists, animate to current location
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 15),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error getting location: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Get location with retry logic and exponential backoff
  Future<LatLng?> _getLocationWithRetry() async {
    const int maxRetries = 3;
    const Duration initialTimeout = Duration(seconds: 5);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔍 DropsMap: Location attempt $attempt/$maxRetries');
        
        // Use shorter timeout for faster failure detection
        final timeout = Duration(seconds: initialTimeout.inSeconds * attempt);
        
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Reduced accuracy for faster response
          timeLimit: timeout,
        );
        print('🔍 DropsMap: Location obtained successfully on attempt $attempt');
        return LatLng(position.latitude, position.longitude);
        
      } catch (e) {
        print('🔍 DropsMap: Location attempt $attempt failed: $e');
        
        if (attempt == maxRetries) {
          print('🔍 DropsMap: All location attempts failed');
          return null;
        }
        
        // Wait before retry with exponential backoff
        final delay = Duration(milliseconds: 500 * attempt);
        print('🔍 DropsMap: Waiting ${delay.inMilliseconds}ms before retry');
        await Future.delayed(delay);
      }
    }
    
    return null;
  }

  Future<void> _loadDropsForMap() async {
    try {
      // Clear drops first to prevent showing cached drops from other modes
      ref.read(dropsControllerProvider.notifier).clearDrops();
      
      final userMode = ref.read(userModeControllerProvider);
      final authState = ref.read(authNotifierProvider);
      
      userMode.whenData((mode) async {
        if (mode == UserMode.collector) {
          // Load only available drops for collectors (pending and cancelled, not suspicious)
          // Exclude drops that this collector cancelled
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
    } catch (e) {
      // Clear drops on error
      ref.read(dropsControllerProvider.notifier).clearDrops();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside text fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _initializeLocation,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          if (_errorMessage == null && _isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading map...'),
                ],
              ),
            ),
          if (_errorMessage == null && !_isLoading && _currentLocation != null)
              Consumer(
                builder: (context, ref, child) {
                  // Watch drops and create markers
                  final dropsState = ref.watch(dropsControllerProvider);
                  
                  return dropsState.when(
                    data: (drops) {
                      // Create markers from drops (exclude censored and suspicious / 3+ cancellations for household)
                      Set<Marker> dropMarkers = {};
                      if (drops.isNotEmpty) {
                        final filteredForMap = drops.where((d) =>
                          !d.isCensored &&
                          !d.isSuspicious &&
                          (d.cancellationCount) < 3
                        ).toList();
                        dropMarkers = filteredForMap.map((drop) {
                          return Marker(
                            markerId: MarkerId('drop_${drop.id}'),
                            position: drop.location,
                            icon: _customDropMarker ?? BitmapDescriptor.defaultMarker,
                            infoWindow: InfoWindow(
                              title: '${drop.numberOfBottles + drop.numberOfCans} items',
                              snippet: '${drop.bottleType.name} - ${drop.status.name}',
                            ),
                            onTap: () => _showDropDetails(drop),
                          );
                        }).toSet();
                      }
                      
                      // Combine drop markers with existing markers
                      final allMarkers = {..._markers, ...dropMarkers};
                      
                      return Stack(
                        children: [
                          GoogleMap(
                            key: ValueKey(_mapKey), // Add map key for forced rebuilding
                            initialCameraPosition: CameraPosition(
                              target: _currentLocation!,
                              zoom: 15,
                            ),
                            onMapCreated: _onMapCreated,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            markers: allMarkers,
                            polylines: _polylines,
                            mapType: MapType.normal,
                            zoomControlsEnabled: true,
                            zoomGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            tiltGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                            compassEnabled: true,
                            trafficEnabled: false,
                            indoorViewEnabled: true,
                            onCameraMove: (CameraPosition position) {},
                            onCameraIdle: () {},
                          ),
                          // Route info display - Always show for testing
                          if (true) // Changed from (_showRoute || _routeDistance != null) to always show for testing
                            Positioned(
                              top: 16,
                              left: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.95), // Make it more visible
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.route,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Route to Drop',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            _routeDistance != null && _routeDuration != null 
                                                ? '$_routeDistance • $_routeDuration'
                                                : 'Calculating route...',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _clearRoute,
                                      icon: Icon(
                                        Icons.close,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading drops...'),
                        ],
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading drops: $error',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loadDropsForMap,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
      floatingActionButton: !_isLoading && _errorMessage == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Test buttons (for debugging)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton.small(
                    heroTag: 'test_polylines_fab',
                    onPressed: _testPolylines,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.circle, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton.small(
                    heroTag: 'current_location_test_fab',
                    onPressed: () {
                      if (_currentLocation != null) {
                        // Create a small polyline right at current location
                        final testPoints = [
                          _currentLocation!,
                          LatLng(_currentLocation!.latitude + 0.001, _currentLocation!.longitude + 0.001),
                        ];
                        
                        final testPolyline = Polyline(
                          polylineId: const PolylineId('current_location_test'),
                          color: Colors.yellow,
                          width: 25,
                          points: testPoints,
                        );
                        setState(() {
                          _polylines.clear();
                          _polylines.add(testPolyline);
                          _showRoute = true;
                          _routeDistance = 'Current Location Test';
                          _routeDuration = 'Yellow Line';
                          _mapKey++; // Force map rebuild
                        });
                        
                      }
                    },
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton.small(
                    heroTag: 'force_test_fab',
                    onPressed: () {
                      final testPoints = [
                        const LatLng(52.27307215605556, 10.508999931699236),
                        const LatLng(52.27307215605556 + 0.005, 10.508999931699236 + 0.005),
                      ];
                      
                      final testPolyline = Polyline(
                        polylineId: const PolylineId('force_test'),
                        color: Colors.orange,
                        width: 20, // Very thick
                        points: testPoints,
                      );
                      setState(() {
                        _polylines.clear();
                        _polylines.add(testPolyline);
                        _showRoute = true;
                        _routeDistance = 'FORCE TEST';
                        _routeDuration = 'Orange Line';
                      });
                      
                    },
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.warning, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton.small(
                    heroTag: 'info_test_fab',
                    onPressed: () {
                      setState(() {
                        _showRoute = true;
                        _routeDistance = 'Test Distance';
                        _routeDuration = 'Test Duration';
                      });
                    },
                    backgroundColor: Colors.yellow,
                    child: const Icon(Icons.info, color: Colors.black),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton.small(
                    heroTag: 'fixed_coordinates_fab',
                    onPressed: () {
                      // Create a polyline at fixed coordinates
                      final fixedPoints = [
                        const LatLng(52.27307215605556, 10.508999931699236),
                        const LatLng(52.27307215605556 + 0.01, 10.508999931699236 + 0.01),
                      ];
                      
                      final testPolyline = Polyline(
                        polylineId: const PolylineId('fixed_test'),
                        color: Colors.purple,
                        width: 15,
                        points: fixedPoints,
                      );
                      setState(() {
                        _polylines.clear();
                        _polylines.add(testPolyline);
                        _showRoute = true;
                        _routeDistance = 'Fixed Test';
                        _routeDuration = 'Purple Line';
                      });
                      
                    },
                    backgroundColor: Colors.purple,
                    child: const Icon(Icons.straighten, color: Colors.white),
                  ),
                ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FloatingActionButton.small(
                      heroTag: 'test_route_fab',
                      onPressed: () {
                        if (_currentLocation != null) {
                          // Test route to a fixed location
                          final testDestination = LatLng(52.27307215605556, 10.508999931699236);
                          
                          // Create a simple test polyline
                          final testPolyline = Polyline(
                            polylineId: const PolylineId('test_route'),
                            color: Colors.red,
                            width: 10,
                            points: [_currentLocation!, testDestination],
                          );
                          setState(() {
                            _polylines.clear();
                            _polylines.add(testPolyline);
                            _showRoute = true;
                            _routeDistance = 'Test Route';
                            _routeDuration = 'Testing...';
                          });
                          
                          // Also try the API route
                          _calculateRoute(_currentLocation!, testDestination);
                        }
                      },
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.route, color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
                  heroTag: 'create_drop_map_fab',
                  onPressed: () => _showCreateDropSheet(context),
                  label: const Text('Create Drop'),
                  icon: const Icon(Icons.add_location),
                ),
              ],
            )
          : null,
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedImage = null;
      _numberOfBottles = 1;
      _numberOfCans = 1;
      _bottleType = BottleType.plastic;
      _notes = '';
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay(
        hour: (TimeOfDay.now().hour + 2) % 24,
        minute: TimeOfDay.now().minute,
      );
      _leaveOutside = false;
    });
    
    // Clear focus nodes
    _bottlesFocusNode.unfocus();
    _cansFocusNode.unfocus();
    _notesFocusNode.unfocus();
  }

  void _showCreateDropSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) {
        return GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside text fields in modal
            FocusScope.of(context).unfocus();
          },
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // Header - Fixed at top
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create New Drop',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          // Dismiss keyboard and close modal
                          FocusScope.of(context).unfocus();
                          Navigator.pop(context);
                          _resetForm();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Scrollable content - Takes remaining space
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image picker
                            InkWell(
                              onTap: _pickImage,
                              child: Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _selectedImage == null
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.camera_alt),
                                            Text('Add Photo'),
                                          ],
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Number of bottles
                            TextFormField(
                              initialValue: _numberOfBottles.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Number of Bottles',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              focusNode: _bottlesFocusNode,
                              onFieldSubmitted: (_) {
                                _cansFocusNode.requestFocus();
                              },
                              validator: (value) {
                                if (value == null || int.tryParse(value) == null || int.parse(value) < 1) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _numberOfBottles = int.tryParse(value) ?? 1;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Number of cans
                            TextFormField(
                              initialValue: _numberOfCans.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Number of Cans',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              focusNode: _cansFocusNode,
                              onFieldSubmitted: (_) {
                                _notesFocusNode.requestFocus();
                              },
                              validator: (value) {
                                if (value == null || int.tryParse(value) == null || int.parse(value) < 1) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _numberOfCans = int.tryParse(value) ?? 1;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Bottle type
                            DropdownButtonFormField<BottleType>(
                              value: _bottleType,
                              decoration: const InputDecoration(
                                labelText: 'Bottle Type',
                                border: OutlineInputBorder(),
                              ),
                              items: BottleType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _bottleType = value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Notes
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Notes (Optional)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              textInputAction: TextInputAction.done,
                              focusNode: _notesFocusNode,
                              onFieldSubmitted: (_) {
                                // Hide keyboard when Done is pressed on notes field
                                _notesFocusNode.unfocus();
                              },
                              onChanged: (value) => _notes = value,
                            ),
                            const SizedBox(height: 16),
                            
                            // Time window
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _selectTime(context, true),
                                    icon: const Icon(Icons.access_time),
                                    label: Text('Start: ${_startTime.format(context)}'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _selectTime(context, false),
                                    icon: const Icon(Icons.access_time),
                                    label: Text('End: ${_endTime.format(context)}'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Leave outside checkbox
                            CheckboxListTile(
                              title: const Text('Leave outside the door'),
                              value: _leaveOutside,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _leaveOutside = value);
                                }
                              },
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Submit button - Fixed at bottom
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: FilledButton(
                    onPressed: () {
                      // Dismiss keyboard before submitting
                      FocusScope.of(context).unfocus();
                      _submitDrop();
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit Drop',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submitDrop() {
    if (_formKey.currentState!.validate() && _currentLocation != null && _selectedImage != null) {
      // Mock submission - in real app, this would be handled by a provider
      final newDrop = Drop(
        id: DateTime.now().toString(), // Mock ID
        userId: ref.read(authNotifierProvider).value?.id ?? '',
        imageUrl: _selectedImage!.path,
        numberOfBottles: _bottleType == BottleType.can ? 0 : _numberOfBottles,
        numberOfCans: _bottleType == BottleType.plastic ? 0 : _numberOfCans,
        bottleType: _bottleType,
        notes: _notes.isEmpty ? "" : _notes,
        leaveOutside: _leaveOutside,
        location: _currentLocation!,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Add marker to map
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(newDrop.id),
            position: newDrop.location,
            infoWindow: InfoWindow(
              title: '${newDrop.numberOfBottles} bottles',
              snippet: newDrop.bottleType.name,
            ),
          ),
        );
      });

      Navigator.pop(context); // Close bottom sheet
      _resetForm(); // Reset form state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drop created successfully!')),
      );
    }
  }

  void _showDropDetails(Drop drop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => FutureBuilder<Map<String, dynamic>?>(
          future: ref.read(dropsControllerProvider.notifier).getUserInfo(drop.userId),
          builder: (context, snapshot) {
            final userData = snapshot.data ?? {
              'name': 'Unknown User',
              'phoneNumber': 'N/A',
              'profilePhoto': null,
            };
            
            // Check if this is the current user's drop
            final currentUserId = ref.read(authNotifierProvider).value?.id;
            final isOwnDrop = currentUserId == drop.userId;
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Drop Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Drop image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              drop.imageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(drop.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              drop.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(drop.status),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // User Information Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isOwnDrop ? 'Your Information' : 'Created by',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // User profile photo
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage: userData['profilePhoto'] != null
                                          ? NetworkImage(userData['profilePhoto'])
                                          : null,
                                      child: userData['profilePhoto'] == null
                                          ? Icon(
                                              Icons.person,
                                              size: 24,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userData['name'] ?? 'Unknown User',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.phone,
                                                size: 16,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                userData['phoneNumber'] ?? 'N/A',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Drop information
                          _buildInfoRow('Bottle Type', drop.bottleType.name.toUpperCase()),
                          _buildInfoRow('Plastic Bottles', '${drop.numberOfBottles}'),
                          _buildInfoRow('Cans', '${drop.numberOfCans}'),
                          _buildInfoRow('Total Items', '${drop.numberOfBottles + drop.numberOfCans}'),
                          _buildInfoRow('Leave Outside', drop.leaveOutside ? 'Yes' : 'No'),
                          _buildInfoRow('Created', _formatDate(drop.createdAt)),

                          
                          // Notes (if any)
                          if (drop.notes?.isNotEmpty == true) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Notes',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                drop.notes!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                          
                          // Actions for collectors
                          if (ref.read(userModeControllerProvider).value == UserMode.collector && 
                              drop.status == DropStatus.pending) ...[
                            const SizedBox(height: 24),
                            // Check if there's an active collection
                            Builder(
                              builder: (context) {
                                final hasActiveCollection = ref.watch(navigationControllerProvider) != null;
                                
                                return Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: hasActiveCollection ? null : () async {
                                          try {
                                            print('🔍 Accepting drop from map: ${drop.id}');
                                            
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
                                            
                                            // Close the modal
                                            Navigator.pop(context);
                                            
                                            // Navigate to navigation screen and replace the current route
                                            // This prevents going back to the map
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => NavigationScreen(
                                                  destination: drop.location,
                                                  dropId: drop.id,
                                                ),
                                              ),
                                            );
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
                                        },
                                        icon: Icon(hasActiveCollection ? Icons.block : Icons.check),
                                        label: Text(hasActiveCollection ? 'Complete Current Drop First' : 'Accept Drop'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: hasActiveCollection ? Colors.grey : Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                      ),
                                    ),
                                    if (hasActiveCollection) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 16,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'You have an active collection. Complete or cancel it first.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DropStatus status) {
    switch (status) {
      case DropStatus.pending:
        return Colors.orange;
      case DropStatus.accepted:
        return Colors.green;
      case DropStatus.collected:
        return Colors.blue;
      case DropStatus.cancelled:
        return Colors.red;
      case DropStatus.expired:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  double _getMarkerHue(DropStatus status) {
    switch (status) {
      case DropStatus.pending:
        return BitmapDescriptor.hueOrange;
      case DropStatus.accepted:
        return BitmapDescriptor.hueGreen;
      case DropStatus.collected:
        return BitmapDescriptor.hueBlue;
      case DropStatus.cancelled:
        return BitmapDescriptor.hueRed;
      case DropStatus.expired:
        return BitmapDescriptor.hueRed;
    }
  }

  // Calculate route between two points using Google Directions API
  Future<void> _calculateRoute(LatLng origin, LatLng destination) async {
    try {
      const apiKey = "AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E";
      final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final points = route['overview_polyline']['points'];
          
          // Decode polyline points
          final polylinePoints = _decodePolyline(points);
          
          // Create polyline for the map with more visible styling
          final polyline = Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue, // Use bright blue for visibility
            width: 8, // Make it thicker
            points: polylinePoints,
            geodesic: true,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          );
          setState(() {
            _polylines.clear();
            _polylines.add(polyline);
            _routeDistance = leg['distance']['text'];
            _routeDuration = leg['duration']['text'];
            _showRoute = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
    }
  }

  // Decode Google polyline string to list of LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  // Show route to selected drop
  void _showRouteToDrop(Drop drop) {
    if (_currentLocation != null) {
      _selectedDropForRoute = drop;
      _calculateRoute(_currentLocation!, drop.location);
    }
  }

  // Clear route
  void _clearRoute() {
    setState(() {
      _polylines.clear();
      _showRoute = false;
      _routeDistance = null;
      _routeDuration = null;
      _selectedDropForRoute = null;
    });
  }

  // Test if polylines work at all
  void _testPolylines() {
    // Create a simple test polyline at fixed coordinates (no API needed)
    final testPoints = [
      const LatLng(52.27307215605556, 10.508999931699236),
      const LatLng(52.27307215605556 + 0.01, 10.508999931699236 + 0.01),
    ];
    
    final testPolyline = Polyline(
      polylineId: const PolylineId('test_line'),
      color: Colors.red,
      width: 10,
      points: testPoints,
    );
    setState(() {
      _polylines.clear();
      _polylines.add(testPolyline);
      _showRoute = true;
      _routeDistance = 'Test Line';
      _routeDuration = 'Simple Test';
    });
  }

  // Load custom marker icon from assets
  Future<void> _loadCustomMarker() async {
    try {
      // Load pre-sized 48x64px marker icon (no scaling needed)
      final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty,
        'assets/icons/drop-pin.png',
      );
      setState(() {
        _customDropMarker = customIcon;
      });
      debugPrint('✅ Custom drop marker loaded successfully (48x64px)');
    } catch (e) {
      debugPrint('❌ Error loading custom marker: $e');
      // Fallback to default marker if loading fails
      setState(() {
        _customDropMarker = BitmapDescriptor.defaultMarker;
      });
    }
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

  void dispose() {
    _bottlesFocusNode.dispose();
    _cansFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }
} 