import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:botleji/features/drops/controllers/drops_controller.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/core/theme/app_colors.dart';
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/core/config/api_config.dart';
import 'package:botleji/core/api/api_client.dart';
import 'dart:async';
import 'dart:math';
import 'package:botleji/core/services/local_notification_service.dart';
import 'package:botleji/features/home/presentation/screens/home_screen.dart';

// Navigation step model
class NavigationStep {
  final String instruction;
  final String distance;
  final String duration;
  final String maneuver;
  final List<LatLng> polylinePoints;
  final String? streetName;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
    required this.polylinePoints,
    this.streetName,
  });
}

class NavigationScreen extends ConsumerStatefulWidget {
  final LatLng destination;
  final String dropId;

  const NavigationScreen({
    super.key,
    required this.destination,
    required this.dropId,
  });

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Polyline> _polylines = {};
  List<NavigationStep> _navigationSteps = [];
  int _currentStepIndex = 0;
  String? _nextTurnInstruction;
  String? _nextTurnDistance;
  String? _nextStreetName;
  String? _routeDistance;
  String? _routeDuration;
  bool _isLoading = true;
  bool _hasReachedDestination = false;
  double _distanceToDestination = 0.0;
  bool _isMoving = false;
  bool _isUserInteracting = false;
  bool _hasInitialCameraPosition = false;
  LatLng? _lastLocation;
  DateTime? _lastLocationTime;
  Timer? _locationTimer;
  StreamSubscription<Position>? _locationSubscription;
  
  // Custom marker icon
  BitmapDescriptor? _customDropMarker;
  
  // Timer variables
  Timer? _timer;
  int _remainingSeconds = 0;
  DateTime? _collectionStartTime;
  int _totalTimeoutSeconds = 0;
  bool _hasTimedOut = false;

  // Proximity and slide button variables
  static const double _arrivalThreshold = 50.0; // 50 meters threshold
  static const double _movementThreshold = 5.0;
  static const Duration _fastUpdateInterval = Duration(seconds: 1);
  static const Duration _slowUpdateInterval = Duration(seconds: 3);
  
  // Slide button variables
  bool _showSlideButton = false;
  double _slideProgress = 0.0;
  bool _isSliding = false;
  late AnimationController _slideAnimationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _collectionStartTime = DateTime.now();
    _loadCustomMarker(); // Load custom marker icon
    
    // Initialize slide button animation
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,);
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeInOut),
    );
    _initializeLocation();
  }

  void _initializeTimer() {
    // Cancel any existing timer
    _timer?.cancel();
    
    // Reset timeout flag
    _hasTimedOut = false;
    
    // Calculate timeout based on route duration + buffer
    int routeDurationMinutes = 0;
    
    // Parse route duration from the calculated route
    if (_routeDuration != null) {
      final durationParts = _routeDuration!.split(' ');
      if (durationParts.length >= 2) {
        if (durationParts[1].contains('hour')) {
          routeDurationMinutes = int.parse(durationParts[0]) * 60;
          if (durationParts.length >= 4) {
            routeDurationMinutes += int.parse(durationParts[2]);
          }
        } else {
          // For testing, use 20 seconds instead of parsing minutes
          routeDurationMinutes = 0; // 20 seconds
        }
      }
    }
    
    int bufferMinutes;
    
    if (routeDurationMinutes <= 5) {
      bufferMinutes = 10; // 10 minutes buffer for short routes
    } else if (routeDurationMinutes <= 15) {
      bufferMinutes = 15; // 15 minutes buffer for medium routes
    } else {
      bufferMinutes = 20; // 20 minutes buffer for long routes
    }
    
    _totalTimeoutSeconds = (routeDurationMinutes + bufferMinutes) * 60;
    
    // For testing, use 1 minute (60 seconds)
    _totalTimeoutSeconds = 60;
    
    // Calculate remaining time based on elapsed time since accepted
    final activeCollection = ref.read(navigationControllerProvider.notifier).activeCollection;
    if (activeCollection?.acceptedAt != null) {
      final elapsed = DateTime.now().difference(activeCollection!.acceptedAt!).inSeconds;
      _remainingSeconds = _totalTimeoutSeconds - elapsed;
      
      // Ensure remaining time is not negative
      if (_remainingSeconds <= 0) {
        _remainingSeconds = _totalTimeoutSeconds; // For testing, always start with full time
      }
    } else {
      _remainingSeconds = _totalTimeoutSeconds;
    }
    
    debugPrint('⏰ Timer initialized:');
    debugPrint('⏰ Route duration: ${routeDurationMinutes} minutes');
    debugPrint('⏰ Buffer: ${bufferMinutes} minutes');
    debugPrint('⏰ Total timeout: ${_totalTimeoutSeconds} seconds');
    debugPrint('⏰ Remaining time: ${_remainingSeconds} seconds');
    
    // Start countdown timer
    debugPrint('⏰ Starting countdown timer with ${_remainingSeconds} seconds remaining...');
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0 && !_hasTimedOut) {
        setState(() {
          _remainingSeconds--;
        });
        debugPrint('⏰ Timer tick: ${_remainingSeconds} seconds remaining');
      } else if (_remainingSeconds <= 0 && !_hasTimedOut) {
        // Timeout reached - only handle once
        debugPrint('⏰ TIMEOUT REACHED - Calling _handleTimeout()');
        _handleTimeout();
        timer.cancel();
      }
    });
  }

  void _handleTimeout() async {
    if (_hasTimedOut) {
      debugPrint('⏰ Timeout already handled, skipping...');
      return;
    }
    
    // Set flag immediately to prevent multiple calls
    _hasTimedOut = true;
    
    debugPrint('⏰ TIMEOUT REACHED - Starting timeout handling...');
    
    // Show notification immediately when timeout occurs
    debugPrint('🔔 Showing drop expired notification immediately on timeout');
    final activeCollection = ref.read(navigationControllerProvider.notifier).activeCollection;
    if (activeCollection != null) {
      debugPrint('🔔 Active collection found, calling notification service...');
      debugPrint('🔔 Drop ID: ${activeCollection.dropoffId}');  
      
      try {
        await LocalNotificationService().showDropExpiredNotification(
          dropId: activeCollection.dropoffId,
          dropTitle: 'Drop Collection',
          context: context,
        );
        debugPrint('🔔 Notification service call completed successfully');
      } catch (e) {
        debugPrint('❌ Error calling notification service: $e');
      }
    } else {
      debugPrint('🔔 No active collection found for notification');
    }
    
    // Show immediate alert to confirm timer is working
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('⏰ Timer Expired!'),
          content: const Text('The collection timer has expired. The navigation screen will now exit.'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _continueTimeoutHandling();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  
  void _continueTimeoutHandling() async {
    try {
      // Get collector ID from the active collection (the one who accepted the drop)
      final activeCollection = ref.read(navigationControllerProvider.notifier).activeCollection;
      debugPrint('📋 Active collection found: ${activeCollection != null}');
      
      if (activeCollection != null) {
        debugPrint('📋 Drop ID: ${activeCollection.dropoffId}');
        debugPrint('📋 Bottles: ${activeCollection.numberOfBottles}, Cans: ${activeCollection.numberOfCans}');
        
        // Use the collector ID that was stored when the drop was accepted
        final collectorId = activeCollection.collectorId;
        debugPrint('👤 Collector ID from active collection: $collectorId');
        
        if (collectorId.isNotEmpty) {
          debugPrint('🚀 Creating expired interaction...');
          debugPrint('🚀 API URL: ${ApiConfig.baseUrl}/dropoffs/interactions');
          debugPrint('🚀 Request data: ${jsonEncode({
            'collectorId': collectorId,
            'dropoffId': activeCollection.dropoffId,
            'interactionType': 'expired',
            'notes': 'Collection expired - timer timeout',
            'dropoffStatus': 'pending',
            'numberOfItems': activeCollection.numberOfBottles + activeCollection.numberOfCans,
            'bottleType': activeCollection.bottleType,
          })}');
          
          // Create expired interaction in the database
          final dio = ApiClientConfig.createDio();
          try {
            final response = await dio.post(
              '${ApiConfig.baseUrl}/dropoffs/interactions',
              data: {
                'collectorId': collectorId,
                'dropoffId': activeCollection.dropoffId,
                'interactionType': 'expired',
                'notes': 'Collection expired - timer timeout',
                'dropoffStatus': 'pending',
                'numberOfItems': activeCollection.numberOfBottles + activeCollection.numberOfCans,
                'bottleType': activeCollection.bottleType,
              },
              options: Options(
                headers: {
                  'Content-Type': 'application/json',
                },
              ),
            );

            debugPrint('✅ Expired interaction created: ${response.statusCode}');
            debugPrint('✅ Response data: ${response.data}');

            // Track collection expiration for smart support (placeholder log)
            debugPrint('✅ Collection expiration tracked for smart support');
          } catch (e) {
            debugPrint('❌ Error creating expired interaction: $e');
            debugPrint('❌ Error details: ${e.toString()}');
            
            // Check if it's a duplicate error (409 Conflict)
            if (e.toString().contains('409') || e.toString().contains('duplicate')) {
              debugPrint('ℹ️ Expired interaction already exists, continuing...');
            } else {
              debugPrint('❌ Unknown error, continuing anyway...');
            }
          }
          
          // Also update the drop status back to pending
          debugPrint('🔄 Updating drop status to pending...');
          debugPrint('🔄 API URL: ${ApiConfig.baseUrl}/dropoffs/${activeCollection.dropoffId}/status');
          final updateResponse = await dio.patch(
            '${ApiConfig.baseUrl}/dropoffs/${activeCollection.dropoffId}/status',
            data: {
              'status': 'pending',
            },
            options: Options(
              headers: {
                'Content-Type': 'application/json',
              },
            ),
          );

          debugPrint('✅ Drop status updated to pending: ${updateResponse.statusCode}');
        } else {
          debugPrint('❌ No collector ID found in active collection');
        }
      } else {
        debugPrint('❌ No active collection found');
      }
    } catch (e) {
      debugPrint('❌ Error creating expired interaction: $e');
      debugPrint('❌ Error details: ${e.toString()}');
    }
    
    // Show notification for drop expiration
    debugPrint('🔔 Showing drop expired notification from navigation screen');
    final activeCollection = ref.read(navigationControllerProvider.notifier).activeCollection;
    if (activeCollection != null) {
      debugPrint('🔔 Active collection found, calling notification service...');
      debugPrint('🔔 Drop ID: ${activeCollection.dropoffId}');
      debugPrint('🔔 Drop Title: Drop Collection');
      
      try {
        // Use background notification method (no context required)
        await LocalNotificationService().showDropExpiredNotificationBackground(
          dropId: activeCollection.dropoffId,
          dropTitle: 'Drop Collection', // You can customize this title
        );
        debugPrint('🔔 Notification service call completed successfully');
      } catch (e) {
        debugPrint('❌ Error calling notification service: $e');
      }
    } else {
      debugPrint('🔔 No active collection found for notification');
    }
    
    debugPrint('🧹 Clearing SharedPreferences...');
    // Clear SharedPreferences
    ref.read(navigationControllerProvider.notifier).completeCollection();
    
    debugPrint('🏠 Navigating to home screen...');
    // Force exit to home screen without showing popup here
    // The popup will be shown on the home screen
    
    // Check if context is still mounted
    if (mounted) {
      debugPrint('✅ Context is mounted, attempting navigation...');
      try {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        debugPrint('✅ Navigation command sent successfully');
      } catch (e) {
        debugPrint('❌ Navigation failed: $e');
        // Fallback: try to pop all routes
        try {
          Navigator.of(context).popUntil((route) => route.isFirst);
          debugPrint('✅ Fallback navigation successful');
        } catch (e2) {
          debugPrint('❌ Fallback navigation also failed: $e2');
        }
      }
    } else {
      debugPrint('❌ Context is not mounted, cannot navigate');
    }
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    _timer?.cancel();
    _locationTimer?.cancel();
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Load custom marker icon from assets
  Future<void> _loadCustomMarker() async {
    try {
      // Match default Google Maps marker size (approximately 48x48 actual pixels)
      // Using width parameter to control final size
      final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(24, 24)), // Much smaller logical size
        'assets/icons/drop-pin.png',
      );
      setState(() {
        _customDropMarker = customIcon;
      });
      debugPrint('✅ Custom drop marker loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading custom marker: $e');
      // Fallback to default marker if loading fails
      setState(() {
        _customDropMarker = BitmapDescriptor.defaultMarker;
      });
    }
  }

  Future<void> _initializeLocation() async {
    try {
      // Request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get initial position with high accuracy
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      final position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _lastLocation = _currentLocation;
        _lastLocationTime = DateTime.now();
        _isLoading = false;
      });
      
      // Calculate route once location is available
      if (_currentLocation != null) {
        debugPrint('Location initialized, calculating route...');
        debugPrint('Current location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
        debugPrint('Destination: ${widget.destination.latitude}, ${widget.destination.longitude}');
        _calculateRoute(_currentLocation!, widget.destination);
        _startLocationMonitoring();
        
        // In debug mode, force immediate distance calculation
        // if (_debugMode) { // Removed debug mode
        //   debugPrint('🧪 DEBUG MODE: Forcing immediate distance calculation');
        //   _updateDistanceToDestination();
        // }
      } else {
        debugPrint('ERROR: Current location is null after initialization!');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startLocationMonitoring() {
    // Start with fast updates initially
    _startFastLocationUpdates();
    
    // Also use location stream for real-time updates
    _startLocationStream();
  }

  void _startFastLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(_fastUpdateInterval, (timer) {
      _updateDistanceToDestination();
    });
  }

  void _startSlowLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(_slowUpdateInterval, (timer) {
      _updateDistanceToDestination();
    });
  }

  void _updateCameraPosition(LatLng newLocation) {
    // Completely disable automatic camera updates - only manual control allowed
    debugPrint('⏸️ Camera updates disabled - manual control only');
    // Do nothing - camera stays where user puts it
  }

  
void _startLocationStream() {
  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.medium, // Reduced accuracy for better performance
    distanceFilter: 10, // Update every 10 meters of movement (increased from 5)
  );

  _locationSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen(
    (Position position) {
      final newLocation = LatLng(position.latitude, position.longitude);

      // Check if user is moving
      if (_lastLocation != null) {
        final movementDistance = Geolocator.distanceBetween(
          _lastLocation!.latitude,
          _lastLocation!.longitude,
          newLocation.latitude,
          newLocation.longitude,
        );
        final isMoving = movementDistance > _movementThreshold;

        if (isMoving != _isMoving) {
          _isMoving = isMoving;
          // Switch between fast and slow updates based on movement
          if (_isMoving) {
            _startFastLocationUpdates();
          } else {
            _startSlowLocationUpdates();
          }
        }
      }

      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
          _lastLocation = newLocation;
          _lastLocationTime = DateTime.now();
        });
      }

      // Camera updates disabled - only manual control allowed
      // _updateCameraPosition(newLocation); // Removed automatic camera updates

      // Update distance immediately when location changes
      if (mounted) {
        _updateDistanceToDestination();
      }
    },
    onError: (error) {
      debugPrint('Location stream error: $error');
      // Fallback to timer-based updates
      _startSlowLocationUpdates();
    },
  );
}



  Future<void> _updateDistanceToDestination() async {
    if (_currentLocation == null) return;
    
    try {
      // Use current location from stream if available, otherwise get new position
      LatLng currentLatLng = _currentLocation!;
      
      // Only get new position if we don't have a recent one from the stream
      // Increased interval to reduce frequency of new position requests
      if (_lastLocationTime == null || 
          DateTime.now().difference(_lastLocationTime!) > const Duration(seconds: 10)) {
        try {
          const LocationSettings locationSettings = LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5), // Increased timeout
          );
          final position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
          currentLatLng = LatLng(position.latitude, position.longitude);
          debugPrint('✅ Got new position: ${position.latitude}, ${position.longitude}');
        } catch (locationError) {
          // If getting new position fails, just use the current one from stream
          debugPrint('⚠️ Could not get new position, using current: $locationError');
          // Don't throw, just continue with current location
        }
      }
      
      // Calculate remaining route distance if we have route data
      double remainingDistance = 0;
      
      if (_navigationSteps.isNotEmpty) {
        // Find the closest point on the route to current position
        double minDistance = double.infinity;
        LatLng closestPoint = _navigationSteps.first.polylinePoints.first;
        int closestStepIndex = 0;
        
        // Search through all route steps to find the closest point
        for (int i = 0; i < _navigationSteps.length; i++) {
          final step = _navigationSteps[i];
          for (final point in step.polylinePoints) {
            final distance = Geolocator.distanceBetween(
              currentLatLng.latitude,
              currentLatLng.longitude,
              point.latitude,
              point.longitude,
            );
            if (distance < minDistance) {
              minDistance = distance;
              closestPoint = point;
              closestStepIndex = i;
            }
          }
        }
        
        // Calculate remaining distance from the closest point to destination
        // by summing up the distances of remaining steps
        remainingDistance = 0;
        
        // Add distance from current position to closest point
        remainingDistance += minDistance;
        
        // Add distances of all remaining steps
        for (int i = closestStepIndex; i < _navigationSteps.length; i++) {
          final step = _navigationSteps[i];
          if (step.polylinePoints.isNotEmpty) {
            // Calculate step distance
            double stepDistance = 0;
            for (int j = 0; j < step.polylinePoints.length - 1; j++) {
              stepDistance += Geolocator.distanceBetween(
                step.polylinePoints[j].latitude,
                step.polylinePoints[j].longitude,
                step.polylinePoints[j + 1].latitude,
                step.polylinePoints[j + 1].longitude,
              );
            }
            remainingDistance += stepDistance;
          }
        }
      } else {
        // Fallback to straight-line distance if no route calculated
        remainingDistance = Geolocator.distanceBetween(
          currentLatLng.latitude,
          currentLatLng.longitude,
          widget.destination.latitude,
          widget.destination.longitude,
        );
      }
      
      if (mounted) {
        // Add protection for very close distances to prevent crashes
        if (remainingDistance.isNaN || remainingDistance.isInfinite) {
          debugPrint('⚠️ Invalid distance detected: $remainingDistance, skipping update');
          return;
        }
        
        // Limit distance updates to prevent rapid state changes
        final distanceDifference = (remainingDistance - _distanceToDestination).abs();
        if (distanceDifference < 0.1) {
          // Skip update if distance change is very small (less than 10cm)
          return;
        }
        
        setState(() {
          _distanceToDestination = remainingDistance;
          _hasReachedDestination = remainingDistance <= _arrivalThreshold;
          
          // Only show slide button automatically if not very close (use test button for close drops)
          if (remainingDistance <= _arrivalThreshold && remainingDistance > 5.0) {
            _showSlideButton = true;
          } else if (remainingDistance > _arrivalThreshold) {
            _showSlideButton = false;
          }
          // If very close (≤5m), keep current state (use test button to control)
        });
        
        debugPrint('📍 Distance to destination: ${remainingDistance.toStringAsFixed(2)} meters');
        debugPrint('📍 Arrival threshold: $_arrivalThreshold meters');
        debugPrint('📍 Has reached destination: $_hasReachedDestination');
        debugPrint('📍 Show slide button: $_showSlideButton');
      }
    } catch (e) {
      debugPrint('Error updating distance: $e');
      // Don't let this error crash the app
    }
  }

  Future<void> _calculateRoute(LatLng origin, LatLng destination) async {
    try {
      debugPrint('Calculating route from ${origin.latitude}, ${origin.longitude} to ${destination.latitude}, ${destination.longitude}');
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&units=metric'
        '&key=AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E'
        );

      debugPrint('Directions API URL: ${url.toString().replaceAll('AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E', 'API_KEY_HIDDEN')}');
      debugPrint('Using API key: AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E');

      final dio = ApiClientConfig.createDio();
      debugPrint('Making API call...');
      
      Map<String, dynamic> data;
      try {
        final response = await dio.get(url.toString());
        debugPrint('API call completed. Status code: ${response.statusCode}');
        debugPrint('Response data type: ${response.data.runtimeType}');
        
        // Handle response data appropriately
        if (response.data is String) {
          data = json.decode(response.data as String);
          debugPrint('JSON decoded from String');
        } else if (response.data is Map<String, dynamic>) {
          data = response.data as Map<String, dynamic>;
          debugPrint('Response data already decoded');
        } else {
          debugPrint('❌ Unexpected response data type: ${response.data.runtimeType}');
          return;
        }
        
        debugPrint('JSON decoded successfully');
        debugPrint('Decoded data type: ${data.runtimeType}');
        debugPrint('Directions API response status: ${data['status']}');
        debugPrint('Response keys: ${data.keys.toList()}');
        debugPrint('Full response: $data');
      } catch (apiError) {
        debugPrint('❌ API call failed: $apiError');
        debugPrint('❌ API error type: ${apiError.runtimeType}');
        if (apiError is DioException) {
          debugPrint('❌ Dio error type: ${apiError.type}');
          debugPrint('❌ Dio error message: ${apiError.message}');
          debugPrint('❌ Dio response status: ${apiError.response?.statusCode}');
          debugPrint('❌ Dio response data: ${apiError.response?.data}');
        }
        return;
      }

      if (data['status'] == 'OK') {
        debugPrint('✅ API response is OK, processing routes...');
        
        final routes = data['routes'] as List;
        debugPrint('Number of routes returned: ${routes.length}');
        
        if (routes.isEmpty) {
          debugPrint('ERROR: No routes returned from API');
          return;
        }
        
        final route = routes[0];
        debugPrint('Route keys: ${route.keys.toList()}');
        
        final legs = route['legs'] as List;
        debugPrint('Number of legs: ${legs.length}');
        
        if (legs.isEmpty) {
          debugPrint('ERROR: No legs in route');
          return;
        }
        
        final leg = legs[0];
        debugPrint('Leg keys: ${leg.keys.toList()}');
        debugPrint('✅ Route data structure looks good, processing polyline...');
        
        // Debug the first step to understand the structure
        if (leg['steps'] is List && (leg['steps'] as List).isNotEmpty) {
          final firstStep = (leg['steps'] as List)[0];
          debugPrint('First step keys: ${firstStep.keys.toList()}');
          debugPrint('First step html_instructions type: ${firstStep['html_instructions']?.runtimeType}');
          debugPrint('First step distance type: ${firstStep['distance']?.runtimeType}');
          debugPrint('First step duration type: ${firstStep['duration']?.runtimeType}');
        }
        
        setState(() {
          // Handle distance safely
          if (leg['distance'] is Map && leg['distance']['text'] is String) {
            _routeDistance = leg['distance']['text'] as String;
          } else {
            _routeDistance = 'Unknown distance';
          }
          
          // Handle duration safely
          if (leg['duration'] is Map && leg['duration']['text'] is String) {
            _routeDuration = leg['duration']['text'] as String;
          } else {
            _routeDuration = 'Unknown duration';
          }
        });

        // Check if overview_polyline exists
        if (route['overview_polyline'] == null) {
          debugPrint('ERROR: No overview_polyline in route');
          return;
        }

        debugPrint('✅ Overview polyline found, decoding...');

        // Decode polyline with proper type checking
        List<LatLng> points = [];
        final overviewPolyline = route['overview_polyline'];
        debugPrint('overview_polyline type: ${overviewPolyline.runtimeType}');
        debugPrint('overview_polyline content: $overviewPolyline');
        
        if (overviewPolyline is Map && overviewPolyline['points'] is String) {
          debugPrint('✅ Polyline format is correct, decoding points...');
          points = _decodePolyline(overviewPolyline['points'] as String);
        } else {
          debugPrint('ERROR: Invalid overview_polyline format');
          debugPrint('overview_polyline type: ${overviewPolyline.runtimeType}');
          return;
        }
        
        debugPrint('Route calculated successfully!');
        // Handle distance safely for debug print
        String distanceText = 'Unknown';
        if (leg['distance'] is Map && leg['distance']['text'] is String) {
          distanceText = leg['distance']['text'] as String;
        }
        
        // Handle duration safely for debug print
        String durationText = 'Unknown';
        if (leg['duration'] is Map && leg['duration']['text'] is String) {
          durationText = leg['duration']['text'] as String;
        }
        
        debugPrint('Route distance: $distanceText');
        debugPrint('Route duration: $durationText');
        debugPrint('Polyline points count: ${points.length}');
        
        // Update active collection with route information
        _updateActiveCollectionWithRouteInfo();
        
        if (points.isNotEmpty) {
          debugPrint('✅ Creating polyline with ${points.length} points...');
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: const Color(0xFF00695C), // App's green color
                width: 8, // Increased width for better visibility
                geodesic: true,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            };
          });
          
          debugPrint('✅ Polyline added to map with ${_polylines.length} polylines');
          debugPrint('Polyline color: ${const Color(0xFF00695C)}');
          debugPrint('Polyline start: ${points.first.latitude}, ${points.first.longitude}');
          debugPrint('Polyline end: ${points.last.latitude}, ${points.last.longitude}');
          debugPrint('🎉 Route calculation and polyline creation completed successfully!');
        } else {
          debugPrint('Warning: No polyline points decoded!');
        }

        // Parse navigation steps
        final steps = leg['steps'] as List;
        debugPrint('✅ Processing ${steps.length} navigation steps...');
        
        _navigationSteps = steps.map((step) {
          debugPrint('Processing step: ${step.keys.toList()}');
          
          // Handle polyline data safely
          List<LatLng> polylinePoints = [];
          if (step['polyline'] != null) {
            final polylineData = step['polyline'];
            if (polylineData is Map && polylineData['points'] is String) {
              polylinePoints = _decodePolyline(polylineData['points'] as String);
            }
          }
          
          // Handle html_instructions safely
          String instruction = '';
          if (step['html_instructions'] is String) {
            instruction = _stripHtmlTags(step['html_instructions'] as String);
          }
          
          // Handle distance and duration safely
          String distance = '';
          String duration = '';
          if (step['distance'] is Map && step['distance']['text'] is String) {
            distance = step['distance']['text'] as String;
          }
          if (step['duration'] is Map && step['duration']['text'] is String) {
            duration = step['duration']['text'] as String;
          }
          
          // Handle maneuver safely
          String maneuver = '';
          if (step['maneuver'] is String) {
            maneuver = step['maneuver'] as String;
          }
          
          return NavigationStep(
            instruction: instruction,
            distance: distance,
            duration: duration,
            maneuver: maneuver,
            polylinePoints: polylinePoints,
            streetName: instruction.contains('<b>') 
                ? _extractStreetName(instruction)
                : null,
            );
        }).toList();
        
        debugPrint('✅ Navigation steps processed successfully!');

        _updateNextTurnInfo();
        
        // Center camera on the beginning of the route with high zoom
        _centerCameraOnRouteStart();
        _initializeTimer(); // Initialize timer after route is calculated
      } else {
        debugPrint('❌ Directions API error: ${data['status']}');
        debugPrint('❌ Error message: ${data['error_message'] ?? 'No error message'}');
        debugPrint('❌ Available routes: ${data['routes']?.length ?? 0}');
        
        // Check for specific API key errors
        if (data['status'] == 'REQUEST_DENIED') {
          debugPrint('❌ API KEY ISSUE: The API key is either invalid, restricted, or hidden from Google Cloud Console');
          debugPrint('❌ Please check your Google Cloud Console settings:');
          debugPrint('❌ 1. Go to Google Cloud Console');
          debugPrint('❌ 2. Navigate to APIs & Services > Credentials');
          debugPrint('❌ 3. Find your API key: AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E');
          debugPrint('❌ 4. Make sure it has the following APIs enabled:');
          debugPrint('❌    - Directions API');
          debugPrint('❌    - Maps JavaScript API');
          debugPrint('❌    - Geocoding API');
          debugPrint('❌ 5. Check if there are any restrictions (HTTP referrers, IP addresses)');
          debugPrint('❌ 6. Make sure the API key is not hidden/disabled');
        }
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
      debugPrint('Error stack trace: ${StackTrace.current}');
    }
  }

  String? _extractStreetName(String htmlInstructions) {
    try {
      final regex = RegExp(r'<b>([^<]+)</b>');
      final match = regex.firstMatch(htmlInstructions);
      return match?.group(1);
    } catch (e) {
      debugPrint('Error extracting street name: $e');
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    try {
      debugPrint('Decoding polyline: ${encoded.substring(0, encoded.length > 50 ? 50 : encoded.length)}...');
      
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
      
      debugPrint('Decoded ${poly.length} polyline points');
      if (poly.isNotEmpty) {
        debugPrint('First point: ${poly.first.latitude}, ${poly.first.longitude}');
        debugPrint('Last point: ${poly.last.latitude}, ${poly.last.longitude}');
      }
      
      return poly;
    } catch (e) {
      debugPrint('Error decoding polyline: $e');
      return [];
    }
  }

  String _stripHtmlTags(String htmlString) {
    try {
      RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
      return htmlString.replaceAll(exp, '');
    } catch (e) {
      debugPrint('Error stripping HTML tags: $e');
      return htmlString; // Return original string if stripping fails
    }
  }

  void _updateNextTurnInfo() {
    if (_currentStepIndex < _navigationSteps.length) {
      final step = _navigationSteps[_currentStepIndex];
      setState(() {
        _nextTurnInstruction = step.instruction;
        _nextTurnDistance = step.distance;
        _nextStreetName = step.streetName;
      });
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters >= 1000) {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    } else {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'straight':
        return Icons.straight;
      case 'ramp-left':
        return Icons.ramp_left;
      case 'ramp-right':
        return Icons.ramp_right;
      case 'merge':
        return Icons.merge;
      case 'fork-left':
        return Icons.fork_left;
      case 'fork-right':
        return Icons.fork_right;
      case 'ferry':
        return Icons.directions_boat;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      case 'navigation':
        return Icons.navigation;
      default:
        return Icons.straight;
    }
  }

  Widget _buildNavigationBanner() {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(16, 25, 16, 16),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: isDark
            ? AppColors.darkPrimary.withOpacity(0.2)
            : AppColors.lightPrimary.withOpacity(0.2),
        width: 1,
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ---------------- HEADER ----------------
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00695C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.route,
                    color: Color(0xFF00695C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route to Drop',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (_routeDistance != null && _routeDuration != null)
                        Text(
                          '$_routeDistance • $_routeDuration',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _temporaryExit(),
                  icon: Icon(
                    Icons.close,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ---------------- NEXT TURN ----------------
            if (_nextTurnInstruction != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getManeuverIcon(
                        _navigationSteps.isNotEmpty
                            ? _navigationSteps[_currentStepIndex].maneuver
                            : '',
                      ),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nextTurnInstruction!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (_nextTurnDistance != null ||
                            _nextStreetName != null)
                          Text(
                            '${_nextTurnDistance ?? ''}${_nextStreetName != null ? ' • $_nextStreetName' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            /// ---------------- DISTANCE TO DESTINATION ----------------
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _hasReachedDestination
                    ? Colors.green.withOpacity(0.1)
                    : const Color(0xFF00695C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasReachedDestination
                      ? Colors.green.withOpacity(0.3)
                      : const Color(0xFF00695C).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasReachedDestination
                        ? Icons.location_on
                        : Icons.my_location,
                    color: _hasReachedDestination
                        ? Colors.green
                        : const Color(0xFF00695C),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hasReachedDestination
                          ? 'You have arrived at the destination!'
                          : '${_formatDistance(_distanceToDestination)} remaining',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _hasReachedDestination
                            ? Colors.green
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            /// ---------------- TIMER ----------------
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _remainingSeconds < 300
                    ? Colors.orange.withOpacity(0.1)
                    : const Color(0xFF00695C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _remainingSeconds < 300
                      ? Colors.orange.withOpacity(0.3)
                      : const Color(0xFF00695C).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: _remainingSeconds < 300
                        ? Colors.orange
                        : const Color(0xFF00695C),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete collection in: ${_formatTime(_remainingSeconds)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _remainingSeconds < 300
                            ? Colors.orange
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ---------------- ACTION BUTTONS ----------------
            if (_hasReachedDestination) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cancel Collection'),
                            content: const Text(
                                'Are you sure you want to cancel this collection?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('No'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.lightError,
                                ),
                                child: const Text('Yes, Cancel'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          _showCancellationDialog(context);
                        }
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.lightError,
                        side: BorderSide(color: AppColors.lightError),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancellationDialog(context),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Exit Navigation'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkTextSecondary.withOpacity(0.3)
                          : AppColors.lightTextSecondary.withOpacity(0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  // Loading state shortcut
  if (_isLoading) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.lightPrimary),
                  const SizedBox(height: 16),
                  Text(
                    'Calculating route...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  return WillPopScope(
    onWillPop: () async {
      // Show confirmation dialog before allowing back
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave Collection?'),
          content: const Text(
            'You have an active collection. Are you sure you want to leave? '
            'You must complete or cancel the collection to proceed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lightError,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (shouldPop == true) {
        await ref.read(navigationControllerProvider.notifier).cancelCollection();
      }
      return shouldPop ?? false;
    },
    child: Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              setState(() {
                _hasInitialCameraPosition = true;
              });
              debugPrint('🗺️ Map created - Initial camera position set');
            },
            onCameraMoveStarted: () {
              debugPrint('👆 User started interacting with map');
              setState(() {
                _isUserInteracting = true;
              });
            },
            onCameraIdle: () {
              debugPrint('👆 User finished interacting with map - will resume auto-update in 2 seconds');
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  debugPrint('🔄 Resuming automatic camera updates');
                  setState(() {
                    _isUserInteracting = false;
                  });
                }
              });
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? widget.destination,
              zoom: 18,
              tilt: 0,
              bearing: 0,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('destination'),
                position: widget.destination,
                icon: _customDropMarker ?? BitmapDescriptor.defaultMarker,
                infoWindow: const InfoWindow(title: 'Drop Location'),
              ),
            },
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            mapType: MapType.normal,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            minMaxZoomPreference: const MinMaxZoomPreference(15, 20),
          ),

          // Navigation Banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildNavigationBanner(),
          ),

          // Floating Action Buttons
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // My Location button
                FloatingActionButton(
                  heroTag: 'my_location_nav_fab',
                  onPressed: () {
                    if (_mapController != null && _currentLocation != null) {
                      debugPrint('📍 My Location button pressed - manual camera control');
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLng(_currentLocation!),
                      );
                    }
                  },
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.my_location),
                ),

                const SizedBox(height: 12),

                // Toggle simple slide button / timer
                FloatingActionButton(
                  heroTag: 'test_slide_button_fab',
                  onPressed: () {
                    setState(() {
                      _showSlideButton = !_showSlideButton;
                      if (_showSlideButton) {
                        _slideProgress = 0.0;
                        _timer?.cancel();
                      } else {
                        _initializeTimer();
                      }
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _showSlideButton
                              ? 'Slide button shown - Timer stopped'
                              : 'Slide button hidden - Timer restarted',
                        ),
                        backgroundColor: Colors.blue,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  child: Icon(_showSlideButton ? Icons.visibility_off : Icons.visibility),
                ),

                const SizedBox(height: 12),

                // Simple Collection Button (appears under navigation button)
                if (_showSlideButton)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: FilledButton(
                      onPressed: () async {
                        debugPrint('🔘 Confirm Collection button pressed!');
                        try {
                          final authState = ref.read(authNotifierProvider);
                          final collectorId = authState?.value?.id;

                          if (collectorId != null) {
                            debugPrint('🔘 Updating drop status to collected...');
                            await ref
                                .read(dropsControllerProvider.notifier)
                                .updateDropStatus(widget.dropId, DropStatus.collected);

                            debugPrint('🔘 Drop status updated successfully!');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Drop marked as collected!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            debugPrint('🔘 Error: No collector ID found');
                          }
                        } catch (e) {
                          debugPrint('🔘 Error marking drop as collected: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00695C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Collection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  
Widget _buildSlideButton() {
  final trackWidth = MediaQuery.of(context).size.width * 0.8;
  const handleSize = 60.0;
  final handleLeft = (trackWidth * _slideProgress - handleSize / 2)
      .clamp(0.0, trackWidth - handleSize);

  return AnimatedBuilder(
    animation: _slideAnimation,
    builder: (context, child) {
      return Container(
        height: handleSize,
        width: trackWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(handleSize / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background track
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(handleSize / 2),
                color: Colors.grey.shade200,
              ),
            ),

            // Progress fill
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: (trackWidth * _slideProgress).clamp(0.0, trackWidth),
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(handleSize / 2),
                color: const Color(0xFF00695C),
              ),
            ),

            // Slide handle
            Positioned(
              left: handleLeft,
              top: 0,
              child: GestureDetector(
                onPanStart: (_) {
                  setState(() {
                    _isSliding = true;
                  });
                },
                onPanUpdate: (details) {
                  if (!_isSliding) return;

                  // Convert to local x within the track
                  final box = context.findRenderObject() as RenderBox;
                  final local = box.globalToLocal(details.globalPosition);

                  // Effective width where handle can move (track minus handle)
                  final effective = trackWidth - handleSize;

                  // Progress is handle-left within [0, effective] normalized to [0..1]
                  final px = (local.dx - handleSize / 2).clamp(0.0, effective);
                  final progress = (px / effective).clamp(0.0, 1.0);

                  setState(() {
                    _slideProgress = progress;
                  });

                  if (_slideProgress >= 0.95) {
                    _completeSlideCollection();
                  }
                },
                onPanEnd: (_) {
                  setState(() {
                    _isSliding = false;
                    if (_slideProgress < 0.95) {
                      _slideProgress = 0.0;
                    }
                  });
                },
                child: Container(
                  width: handleSize,
                  height: handleSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(handleSize / 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: _slideProgress > 0.5
                        ? Colors.white
                        : const Color(0xFF00695C),
                    size: 24,
                  ),
                ),
              ),
            ),

            // Text overlay
            Positioned.fill(
              child: Center(
                child: Text(
                  _slideProgress > 0.5 ? 'Release to Collect' : 'Slide to Collect',
                  style: TextStyle(
                    color: _slideProgress > 0.5
                        ? Colors.white
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  

  void _completeSlideCollection() async {
    // Animate the slide completion
    await _slideAnimationController.forward();
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Collection confirmed!'),
        backgroundColor: Color(0xFF00695C),
        duration: Duration(seconds: 1),
      ),
      );

    // Mark the drop as collected
    try {
      final authState = ref.read(authNotifierProvider);
      final collectorId = authState?.value?.id;
      
      if (collectorId != null) {
        await ref.read(dropsControllerProvider.notifier)
            .updateDropStatus(widget.dropId, DropStatus.collected);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drop marked as collected!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking drop as collected: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
        );
    }
    
    // Complete the collection
    await _handleCollectionCompletion();
  }

  
  void _showCancellationDialog(BuildContext context) {
  CancellationReason? selectedReason;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Cancel Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this collection? Please select a reason:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...CancellationReason.values.map(
              (reason) => RadioListTile<CancellationReason>(
                title: Text(reason.displayName),
                value: reason,
                groupValue: selectedReason,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    selectedReason = value;
                  });
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: selectedReason == null
                ? null
                : () {
                    Navigator.pop(context);
                    _handleCancellation(selectedReason!);
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lightError,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Collection'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _handleCancellation(CancellationReason reason) async {
  try {
    final authState = ref.read(authNotifierProvider);
    final collectorId = authState?.value?.id;

    if (collectorId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated'),
            backgroundColor: AppColors.lightError,
          ),
        );
      }
      return;
    }

    await ref.read(dropsControllerProvider.notifier)
        .cancelAcceptedDrop(widget.dropId, reason.value, collectorId);

    // Clear the persistent collection state
    await ref.read(navigationControllerProvider.notifier).cancelCollection();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // ⚠️ Removed `const` so string interpolation works
          content: Text('Collection cancelled: ${reason.displayName}'),
          backgroundColor: AppColors.lightMapPin,
        ),
      );

      // Navigate back to home screen
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling collection: $e'),
          backgroundColor: AppColors.lightError,
        ),
      );
    }
  }
}

  

  Future<void> _handleCollectionCompletion() async {
    debugPrint('🧪 DEBUG: Starting collection completion...');
    try {
      final authState = ref.read(authNotifierProvider);
      final collectorId = authState?.value?.id;
      
      debugPrint('🧪 DEBUG: Collector ID: $collectorId');
      
      if (collectorId == null) {
        debugPrint('🧪 DEBUG: No collector ID found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: User not authenticated'),
              backgroundColor: AppColors.lightError,
            ),
          );
        }
        return;
      }
      
      debugPrint('🧪 DEBUG: Confirming collection for drop: ${widget.dropId}');
      await ref.read(dropsControllerProvider.notifier)
          .confirmCollection(widget.dropId);
      
      debugPrint('🧪 DEBUG: Collection confirmed, clearing state...');
      // Clear the persistent collection state
      await ref.read(navigationControllerProvider.notifier).completeCollection();
      
      debugPrint('🧪 DEBUG: State cleared, navigating to home...');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to home screen using a more direct approach
        try {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          debugPrint('🧪 DEBUG: Navigation to home completed');
        } catch (e) {
          debugPrint('🧪 DEBUG: Route navigation failed, trying fallback: $e');
          // Fallback: navigate to home screen directly
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
          debugPrint('🧪 DEBUG: Fallback navigation completed');
        }
      }
    } catch (e) {
      debugPrint('🧪 DEBUG: Error in collection completion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing collection: $e'),
            backgroundColor: AppColors.lightError,
          ),
          );
      }
    }
  }

  void _centerCameraOnRouteStart() {
    if (_mapController == null || _navigationSteps.isEmpty) {
      debugPrint('⚠️ Cannot center camera on route start: map controller not ready or no route steps.');
      return;
    }

    final startPoint = _navigationSteps.first.polylinePoints.first;
    
    // Calculate bearing from the first two points of the polyline
    double bearing = 0.0;
    if (_navigationSteps.first.polylinePoints.length >= 2) {
      final secondPoint = _navigationSteps.first.polylinePoints[1];
      bearing = _calculateBearing(startPoint, secondPoint);
      debugPrint('🧭 Calculated bearing: ${bearing.toStringAsFixed(1)}°');
    }
    
    final cameraUpdate = CameraUpdate.newLatLngZoom(startPoint, 18.0);
    _mapController!.animateCamera(cameraUpdate).then((_) {
      // Set the bearing after the camera position is set
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: startPoint,
          zoom: 18.0,
          tilt: 0,
          bearing: bearing,
        ),
      ));
    });
    
    debugPrint('📍 Centering camera on route start at ${startPoint.latitude}, ${startPoint.longitude} with zoom 18 and bearing ${bearing.toStringAsFixed(1)}°');
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * pi / 180;
    final double lat2 = end.latitude * pi / 180;
    final double dLon = (end.longitude - start.longitude) * pi / 180;

    final double y = sin(dLon) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    
    double bearing = atan2(y, x) * 180 / pi;
    bearing = (bearing + 360) % 360; // Normalize to 0-360 degrees
    
    debugPrint('🧭 Bearing calculation: start(${start.latitude}, ${start.longitude}) -> end(${end.latitude}, ${end.longitude}) = ${bearing.toStringAsFixed(1)}°');
    
    return bearing;
  }

  void _updateActiveCollectionWithRouteInfo() {
    final activeCollection = ref.read(navigationControllerProvider);
    if (activeCollection != null) {
      final updatedCollection = activeCollection.copyWith(
        routeDistance: _routeDistance,
        routeDuration: _routeDuration,
      );
      ref.read(navigationControllerProvider.notifier).updateCollection(updatedCollection);
      debugPrint('✅ Active collection updated with route info: ${_routeDistance} • ${_routeDuration}');
    } else {
      debugPrint('❌ Active collection is null, cannot update with route info.');
    }
  }

  void _temporaryExit() {
    // Cancel timers
    _timer?.cancel();
    _locationTimer?.cancel();
    
    // Reset timeout flag
    _hasTimedOut = false;
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Navigation'),
          content: const Text('Are you sure you want to exit navigation? Your collection will remain active.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

}
  

enum CancellationReason {
  NoAccess('No Access', 'noAccess'),
  NotFound('Not Found', 'notFound'),
  AlreadyCollected('Already Collected', 'alreadyCollected'),
  WrongLocation('Wrong Location', 'wrongLocation'),
  Unsafe('Unsafe Location', 'unsafe'),
  Other('Other', 'other');

  const CancellationReason(this.displayName, this.value);
  final String displayName;
  final String value;
} 
  