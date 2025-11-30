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
import 'package:botleji/core/utils/map_styles.dart';
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/core/utils/logger.dart';
import 'package:botleji/core/config/api_config.dart';
import 'package:botleji/core/api/api_client.dart';
import 'dart:async';
import 'dart:math';
import 'package:botleji/core/services/local_notification_service.dart';
import 'package:botleji/features/home/presentation/screens/home_screen.dart';
import 'package:botleji/features/drops/presentation/widgets/report_drop_dialog.dart';
import 'package:botleji/features/rewards/presentation/providers/collection_success_provider.dart';
import 'package:botleji/features/rewards/presentation/widgets/collection_success_popup.dart';
import 'package:botleji/l10n/app_localizations.dart';
import 'package:botleji/features/collection/presentation/providers/collection_attempts_provider.dart';
import 'package:botleji/features/earnings/presentation/providers/earnings_provider.dart';
import 'package:botleji/core/services/notification_service.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Transportation mode enum
enum TransportationMode {
  walking,
  driving,
  bicycling,
}

extension TransportationModeExtension on TransportationMode {
  String get apiValue {
    switch (this) {
      case TransportationMode.walking:
        return 'walking';
      case TransportationMode.driving:
        return 'driving';
      case TransportationMode.bicycling:
        return 'bicycling';
    }
  }
  
  String getDisplayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case TransportationMode.walking:
        return l10n.walking;
      case TransportationMode.driving:
        return l10n.driving;
      case TransportationMode.bicycling:
        return l10n.bicycling;
    }
  }
  
  IconData get icon {
    switch (this) {
      case TransportationMode.walking:
        return Icons.directions_walk;
      case TransportationMode.driving:
        return Icons.directions_car;
      case TransportationMode.bicycling:
        return Icons.directions_bike;
    }
  }
  
  List<PatternItem> get polylinePattern {
    switch (this) {
      case TransportationMode.walking:
        // Dots pattern for walking (like Google Maps)
        // Using very small dashes to create visible dots since PatternItem.dot doesn't render
        return [PatternItem.dash(3), PatternItem.gap(5)];
      case TransportationMode.driving:
        // Solid line for driving
        return [];
      case TransportationMode.bicycling:
        // Dotted pattern for bicycling (thin dots)
        // Using very small dashes to create visible dots since PatternItem.dot doesn't render
        return [PatternItem.dash(2), PatternItem.gap(4)];
    }
  }
  
  int get polylineWidth {
    switch (this) {
      case TransportationMode.walking:
        return 8; // Thicker for better visibility
      case TransportationMode.driving:
        return 8;
      case TransportationMode.bicycling:
        return 5; // Slightly thicker for visibility but still thin
    }
  }
}

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
  
  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
      'distance': distance,
      'duration': duration,
      'maneuver': maneuver,
      'polylinePoints': polylinePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'streetName': streetName,
    };
  }
  
  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    return NavigationStep(
      instruction: json['instruction'] as String,
      distance: json['distance'] as String,
      duration: json['duration'] as String,
      maneuver: json['maneuver'] as String,
      polylinePoints: (json['polylinePoints'] as List)
          .map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
          .toList(),
      streetName: json['streetName'] as String?,
    );
  }
}

// Cached route data structure
class _CachedRoute {
  final Map<String, dynamic> routeData; // Full API response data
  final List<NavigationStep> navigationSteps;
  final List<LatLng> polylinePoints;
  final String routeDistance;
  final String routeDuration;
  final DateTime cachedAt;
  final String transportationMode;

  _CachedRoute({
    required this.routeData,
    required this.navigationSteps,
    required this.polylinePoints,
    required this.routeDistance,
    required this.routeDuration,
    required this.cachedAt,
    required this.transportationMode,
  });

  bool get isValid {
    // Cache is valid as long as it exists (expiration handled by collection lifecycle)
    // Routes are cleared when collection timer expires or collection is cancelled/completed
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'routeData': routeData,
      'navigationSteps': navigationSteps.map((s) => s.toJson()).toList(),
      'polylinePoints': polylinePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'routeDistance': routeDistance,
      'routeDuration': routeDuration,
      'cachedAt': cachedAt.toIso8601String(),
      'transportationMode': transportationMode,
    };
  }

  factory _CachedRoute.fromJson(Map<String, dynamic> json) {
    return _CachedRoute(
      routeData: json['routeData'] as Map<String, dynamic>,
      navigationSteps: (json['navigationSteps'] as List)
          .map((s) => NavigationStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      polylinePoints: (json['polylinePoints'] as List)
          .map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
          .toList(),
      routeDistance: json['routeDistance'] as String,
      routeDuration: json['routeDuration'] as String,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      transportationMode: json['transportationMode'] as String,
    );
  }
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

class _NavigationScreenState extends ConsumerState<NavigationScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
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
  int _closestPolylinePointIndex = 0; // Track the closest point on the polyline to remove passed segments
  int _previousClosestPolylinePointIndex = 0; // Track previous closest point to calculate distance traveled
  double _lastPolylineUpdateDistance = 0.0; // Track distance traveled since last polyline update
  LatLng? _lastLocation;
  DateTime? _lastLocationTime;
  Timer? _locationTimer;
  StreamSubscription<Position>? _locationSubscription;
  TransportationMode _transportationMode = TransportationMode.driving; // Default to driving
  bool _transportationModeLocked = false; // Lock after first selection to prevent timer exploitation
  
  // Route caching
  static final Map<String, _CachedRoute> _inMemoryCache = {}; // In-memory cache (static to persist across widget rebuilds)
  static const String _cachePrefix = 'route_cache_';
  static int _apiCallCount = 0; // Track API calls for verification
  static int _cacheHitCount = 0; // Track cache hits for verification
  
  // Custom marker icon
  BitmapDescriptor? _customDropMarker;
  
  // Timer variables
  Timer? _timer;
  int _remainingSeconds = 0;
  DateTime? _collectionStartTime;
  int _totalTimeoutSeconds = 0;
  bool _hasTimedOut = false;
  bool _warningNotificationSent = false;
  DateTime? _timerPausedAt; // Track when timer was paused

  // Proximity and slide button variables
  static const double _arrivalThreshold = 100.0; // 100 meters threshold - increased for better UX
  static const double _movementThreshold = 5.0;
  // Optimized intervals matching industry standards (Wolt, Uber, etc.)
  static const Duration _fastUpdateInterval = Duration(seconds: 3); // Changed from 1s to 3s for better battery life
  static const Duration _slowUpdateInterval = Duration(seconds: 5); // Changed from 3s to 5s when stationary
  
  // Slide button variables
  bool _showSlideButton = false;
  double _slideProgress = 0.0;
  bool _isSliding = false;
  double _cancelSlideProgress = 0.0;
  bool _isCancelSliding = false;
  late AnimationController _slideAnimationController;
  late Animation<double> _slideAnimation;

  // Navigation card minimize/expand variables
  bool _isNavigationCardMinimized = false;

  // Location broadcasting variables
  String? _activeAttemptId; // Collection attempt ID for location broadcasting
  DateTime? _lastLocationBroadcastTime; // Track last broadcast time
  LatLng? _lastBroadcastLocation; // Track last broadcast location for distance calculation
  static const Duration _locationBroadcastInterval = Duration(seconds: 5); // Time-based fallback: broadcast every 5 seconds
  static const double _locationBroadcastDistanceThreshold = 5.0; // Distance-based: broadcast when moved 5 meters

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _collectionStartTime = DateTime.now();
    _loadCustomMarker(); // Load custom marker icon
    
    // Initialize slide button animation
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,);
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeInOut),
    );
    _loadTransportationMode();
    _initializeLocation();
  }

  Future<void> _loadTransportationMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString('transportation_mode_${widget.dropId}');
      final isLocked = prefs.getBool('transportation_mode_locked_${widget.dropId}') ?? false;
      
      if (savedMode != null) {
        setState(() {
          _transportationMode = TransportationMode.values.firstWhere(
            (mode) => mode.name == savedMode,
            orElse: () => TransportationMode.driving,
          );
          _transportationModeLocked = isLocked;
        });
      } else {
        // If no saved mode, check if drop was just accepted - allow one change
        // Save the default mode initially
        await _saveTransportationMode();
      }
    } catch (e) {
      debugPrint('Error loading transportation mode: $e');
    }
  }

  Future<void> _saveTransportationMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('transportation_mode_${widget.dropId}', _transportationMode.name);
      await prefs.setBool('transportation_mode_locked_${widget.dropId}', _transportationModeLocked);
    } catch (e) {
      debugPrint('Error saving transportation mode: $e');
    }
  }

  Future<void> _clearTransportationMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('transportation_mode_${widget.dropId}');
      await prefs.remove('transportation_mode_locked_${widget.dropId}');
    } catch (e) {
      debugPrint('Error clearing transportation mode: $e');
    }
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('🔄 NavigationScreen: App lifecycle changed to: $state');
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App went to background - pause timer
      debugPrint('🔄 NavigationScreen: App going to background, pausing timer');
      _pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground - recalculate and resume timer
      debugPrint('🔄 NavigationScreen: App resumed, recalculating timer');
      // Use a small delay to ensure the screen is fully built before checking timer
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _resumeTimer();
        }
      });
    }
  }

  void _pauseTimer() {
    if (_timer != null && _timer!.isActive) {
      _timerPausedAt = DateTime.now();
      _timer?.cancel();
      debugPrint('⏰ Timer paused at: $_timerPausedAt');
    }
  }

  void _resumeTimer() {
    // Always recalculate remaining time based on actual elapsed time when resuming
    final activeCollection = ref.read(navigationControllerProvider.notifier).activeCollection;
    if (activeCollection != null && activeCollection.acceptedAt != null) {
      // If timer wasn't initialized yet, initialize it first
      if (_totalTimeoutSeconds == 0) {
        debugPrint('⏰ Timer not initialized on resume, initializing now...');
        _initializeTimer();
        return; // _initializeTimer will handle the expired check
      }
      
      // Cancel existing timer if any
      _timer?.cancel();
      
      // Recalculate remaining time based on actual elapsed time
      final elapsed = DateTime.now().difference(activeCollection.acceptedAt!).inSeconds;
      _remainingSeconds = _totalTimeoutSeconds - elapsed;
      
      // Ensure remaining time is not negative
      if (_remainingSeconds <= 0) {
        _remainingSeconds = 0;
        debugPrint('⏰ Timer expired while in background - elapsed: ${elapsed}s, timeout: ${_totalTimeoutSeconds}s');
        _timerPausedAt = null;
        
        // Handle timeout immediately - show popup (force show even if already timed out)
        // Use forceShow=true to ensure popup appears when resuming from background
        _handleTimeout(forceShow: true);
        return;
      }
      
      debugPrint('⏰ Timer resumed - Recalculated remaining time: $_remainingSeconds seconds (elapsed: ${elapsed}s)');
      _timerPausedAt = null;
      
      // Restart the timer with recalculated time
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0 && !_hasTimedOut) {
          setState(() {
            _remainingSeconds--;
          });
          
          // Check for warning notification at 30% of total time remaining
          final warningThreshold = (_totalTimeoutSeconds * 0.3).round();
          if (_remainingSeconds <= warningThreshold && !_warningNotificationSent) {
            debugPrint('⚠️ Warning threshold reached: ${_remainingSeconds}s <= ${warningThreshold}s (30% of ${_totalTimeoutSeconds}s)');
            _showWarningNotification();
          }
        } else if (_remainingSeconds <= 0 && !_hasTimedOut) {
          // Timeout reached - only handle once
          debugPrint('⏰ TIMEOUT REACHED - Calling _handleTimeout()');
          _handleTimeout();
          timer.cancel();
        }
      });
    }
  }

  void _initializeTimer() {
    // Cancel any existing timer
    _timer?.cancel();
    _timerPausedAt = null; // Reset pause time
    
    // Reset timeout flag
    _hasTimedOut = false;
    
    // Calculate timeout based on route duration + buffer
    int routeDurationMinutes = 20; // Default fallback - 20 minutes for realistic testing
    
    // Parse route duration from the calculated route
    if (_routeDuration != null && _routeDuration!.isNotEmpty) {
      final durationParts = _routeDuration!.split(' ');
      if (durationParts.length >= 2) {
        if (durationParts[1].contains('hour')) {
          routeDurationMinutes = int.parse(durationParts[0]) * 60;
          if (durationParts.length >= 4) {
            routeDurationMinutes += int.parse(durationParts[2]);
          }
        } else {
          // Parse minutes from duration text like "15 mins"
          routeDurationMinutes = int.parse(durationParts[0]);
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
    
    // Use the calculated timeout instead of hardcoded 1 minute
    // _totalTimeoutSeconds = 60; // Removed hardcoded 1 minute for testing
    
    // Calculate remaining time based on elapsed time since accepted
    final activeCollection = ref.read(navigationControllerProvider.notifier).activeCollection;
    if (activeCollection != null && activeCollection.acceptedAt != null) {
      final elapsed = DateTime.now().difference(activeCollection.acceptedAt!).inSeconds;
      _remainingSeconds = _totalTimeoutSeconds - elapsed;
      
      // Ensure remaining time is not negative
      if (_remainingSeconds <= 0) {
        _remainingSeconds = 0; // Timer already expired
        _hasTimedOut = true;
      }
    } else {
      _remainingSeconds = _totalTimeoutSeconds;
    }
    
    debugPrint('⏰ Timer initialized:');
    debugPrint('⏰ Route duration: ${routeDurationMinutes} minutes');
    debugPrint('⏰ Buffer: ${bufferMinutes} minutes');
    debugPrint('⏰ Total timeout: ${_totalTimeoutSeconds} seconds');
    debugPrint('⏰ Remaining time: ${_remainingSeconds} seconds');
    
    // Only start timer if not already timed out
    if (!_hasTimedOut) {
      // Start countdown timer
      debugPrint('⏰ Starting countdown timer with ${_remainingSeconds} seconds remaining...');
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0 && !_hasTimedOut) {
          setState(() {
            _remainingSeconds--;
          });
          
          // Check for warning notification at 30% of total time remaining
          final warningThreshold = (_totalTimeoutSeconds * 0.3).round();
          if (_remainingSeconds <= warningThreshold && !_warningNotificationSent) {
            debugPrint('⚠️ Warning threshold reached: ${_remainingSeconds}s <= ${warningThreshold}s (30% of ${_totalTimeoutSeconds}s)');
            _showWarningNotification();
          }
        } else if (_remainingSeconds <= 0 && !_hasTimedOut) {
          // Timeout reached - only handle once
          debugPrint('⏰ TIMEOUT REACHED - Calling _handleTimeout()');
          _handleTimeout();
          timer.cancel();
        }
      });
    } else {
      debugPrint('⏰ Timer already expired, not starting countdown');
      // Force show timeout popup when initializing with expired timer
      _handleTimeout(forceShow: true);
    }
  }

  void _handleTimeout({bool forceShow = false}) async {
    // Check if already handled, but allow force show when resuming from background
    if (_hasTimedOut && !forceShow) {
      debugPrint('⏰ Timeout already handled, skipping...');
      return;
    }
    
    // Set flag immediately to prevent multiple calls
    _hasTimedOut = true;
    
    // Clear route cache when timer expires
    await _clearRouteCache();
    
    // Stop location broadcasting
    _stopLocationBroadcasting();
    
    debugPrint('⏰ TIMEOUT REACHED - Starting timeout handling... (forceShow: $forceShow)');
    
    // Show notification immediately when timeout occurs
    debugPrint('🔔 Showing drop expired notification immediately on timeout');
    final activeCollection = ref.read(navigationControllerProvider.notifier).activeCollection;
    if (activeCollection != null) {
      debugPrint('🔔 Active collection found, calling notification service...');
      debugPrint('🔔 Drop ID: ${activeCollection.dropoffId}');
      
      try {
        await LocalNotificationService().showDropExpiredNotification(
          dropId: activeCollection.dropoffId,
          dropTitle: AppLocalizations.of(context).dropCollection,
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
      // Use a small delay to ensure the dialog shows even if called during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context).timerExpired),
              content: Text(AppLocalizations.of(context).timerExpiredMessage),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    _continueTimeoutHandling();
                  },
                  child: Text(AppLocalizations.of(context).ok),
                ),
              ],
            ),
          );
        }
      });
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
          debugPrint('🚀 API URL: ${ApiConfig.baseUrlSync}/dropoffs/interactions');
          debugPrint('🚀 Request data: ${jsonEncode({
            'collectorId': collectorId,
            'dropoffId': activeCollection.dropoffId,
            'interactionType': 'expired',
            'notes': 'Collection expired - timer timeout',
            'dropoffStatus': 'pending',
            'numberOfItems': activeCollection.numberOfBottles + activeCollection.numberOfCans,
            'bottleType': activeCollection.bottleType,
          })}');
          
          // Find and complete the existing collection attempt
          final dio = ApiClientConfig.createDio();
          try {
            // Find the active collection attempt for this drop
            debugPrint('🔍 Getting active collection attempt...');
            final attemptsResponse = await dio.get(
              '${ApiConfig.baseUrlSync}/dropoffs/${activeCollection.dropoffId}/attempts',
              options: Options(
                headers: {
                  'Content-Type': 'application/json',
                },
              ),
            );
            
            final attempts = attemptsResponse.data as List;
            final activeAttempt = attempts.firstWhere(
              (a) => a['status'] == 'active',
              orElse: () => null,
            );
            
            if (activeAttempt == null) {
              debugPrint('❌ No active collection attempt found');
              return;
            }
            
            final attemptId = activeAttempt['_id'];
            debugPrint('✅ Found active attempt: $attemptId');
            
            // Complete it as expired
            debugPrint('🔄 Completing attempt as expired...');
            final completeResponse = await dio.patch(
              '${ApiConfig.baseUrlSync}/dropoffs/${activeCollection.dropoffId}/attempts/$attemptId/complete',
              data: {
                'outcome': 'expired',
                'notes': 'Collection expired - timer timeout',
              },
              options: Options(
                headers: {
                  'Content-Type': 'application/json',
                },
              ),
            );
            
            debugPrint('✅ Collection attempt completed as expired: ${completeResponse.statusCode}');
            debugPrint('✅ Response data: ${completeResponse.data}');

            // Track collection expiration for smart support (placeholder log)
            debugPrint('✅ Collection expiration tracked for smart support');
          } catch (e) {
            debugPrint('❌ Error creating expired collection attempt: $e');
            debugPrint('❌ Error details: ${e.toString()}');
            
            // Check if it's a duplicate error (409 Conflict)
            if (e.toString().contains('409') || e.toString().contains('duplicate')) {
              debugPrint('ℹ️ Collection attempt already exists, continuing...');
            } else {
              debugPrint('❌ Unknown error, continuing anyway...');
            }
          }
          
          // Also update the drop status back to pending
          debugPrint('🔄 Updating drop status to pending...');
          debugPrint('🔄 API URL: ${ApiConfig.baseUrlSync}/dropoffs/${activeCollection.dropoffId}/status');
          final updateResponse = await dio.patch(
            '${ApiConfig.baseUrlSync}/dropoffs/${activeCollection.dropoffId}/status',
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
          dropTitle: AppLocalizations.of(context).dropCollection, // You can customize this title
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
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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
    WidgetsBinding.instance.removeObserver(this);
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
        
        // Get active collection attempt ID for location broadcasting
        debugPrint('🔍 Navigation initialized, getting active attempt ID...');
        _getActiveAttemptId().then((_) {
          debugPrint('✅ Attempt ID retrieval completed: $_activeAttemptId');
          if (_activeAttemptId == null) {
            debugPrint('⚠️ WARNING: Attempt ID is still null after retrieval!');
          } else {
            debugPrint('✅ Ready to broadcast location updates with attempt ID: $_activeAttemptId');
          }
        });
        
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
    // Don't update camera if user is manually interacting with the map
    if (_isUserInteracting || _mapController == null) {
      return;
    }
    
    // Find the next turn point or destination to calculate bearing
    LatLng? targetPoint;
    
    // Collect all polyline points
    List<LatLng> allPolylinePoints = [];
    for (var step in _navigationSteps) {
      allPolylinePoints.addAll(step.polylinePoints);
    }
    
    if (allPolylinePoints.isEmpty) {
      // Fallback to destination if no polyline points
      targetPoint = widget.destination;
    } else {
      // Find a point ahead on the route (look ahead 200-300 meters or 30% of remaining route)
      int lookAheadIndex = _closestPolylinePointIndex;
      double lookAheadDistance = 0;
      const double targetLookAhead = 250.0; // Look ahead 250 meters
      
      for (int i = _closestPolylinePointIndex; i < allPolylinePoints.length - 1; i++) {
        final distance = Geolocator.distanceBetween(
          allPolylinePoints[i].latitude,
          allPolylinePoints[i].longitude,
          allPolylinePoints[i + 1].latitude,
          allPolylinePoints[i + 1].longitude,
        );
        lookAheadDistance += distance;
        lookAheadIndex = i + 1;
        
        if (lookAheadDistance >= targetLookAhead) {
          break;
        }
      }
      
      // Use the look-ahead point, or destination if we've passed most of the route
      targetPoint = lookAheadIndex < allPolylinePoints.length 
          ? allPolylinePoints[lookAheadIndex]
          : widget.destination;
    }
    
    // Calculate bearing from current location to target point
    double bearing = 0.0;
    if (targetPoint != null) {
      bearing = _calculateBearing(newLocation, targetPoint);
    }
    
    // Update camera to follow user position with appropriate zoom and bearing
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: newLocation,
          zoom: 18.5,
          tilt: 0,
          bearing: bearing,
        ),
      ),
    );
  }


  void _startLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // High accuracy for navigation
      distanceFilter: 5, // Update every 5 meters of movement (optimized for navigation apps)
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
        
        // Update camera to follow user position and adjust for next turn
        if (!_isUserInteracting && mounted) {
          _updateCameraPosition(newLocation);
        }
        
        // Update distance immediately when location changes
        if (mounted) {
          _updateDistanceToDestination();
        }

        // Broadcast location to household user (if attempt ID is available)
        if (_activeAttemptId != null) {
          _broadcastLocation(newLocation, position.accuracy, position.speed, position.heading);
        } else {
          // Debug: Log when attempt ID is not available and retry
          final now = DateTime.now();
          if (_lastLocationBroadcastTime == null || 
              now.difference(_lastLocationBroadcastTime ?? DateTime(1970)) > const Duration(seconds: 10)) {
            debugPrint('⚠️ Cannot broadcast location: _activeAttemptId is null, retrying to get attempt ID...');
            // Try to get attempt ID again if we don't have it
            _getActiveAttemptId().then((_) {
              debugPrint('🔄 Retry completed, _activeAttemptId is now: $_activeAttemptId');
            });
            setState(() {
              _lastLocationBroadcastTime = now; // Prevent spam
            });
          }
        }
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
        // Fallback to timer-based updates
        _startSlowLocationUpdates();
      },
    );
  }

  /// Get active collection attempt ID for location broadcasting
  Future<void> _getActiveAttemptId() async {
    try {
      final activeCollection = ref.read(navigationControllerProvider.notifier).activeCollection;
      if (activeCollection == null) {
        debugPrint('⚠️ No active collection found for location broadcasting');
        return;
      }

      debugPrint('🔍 Getting active attempt ID for dropoff: ${activeCollection.dropoffId}');
      final dio = ApiClientConfig.createDio();
      final attemptsResponse = await dio.get(
        '${ApiConfig.baseUrlSync}/dropoffs/${activeCollection.dropoffId}/attempts',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('📦 Attempts response: ${attemptsResponse.data}');
      final attempts = attemptsResponse.data as List;
      debugPrint('📦 Found ${attempts.length} attempts');
      
      final activeAttempt = attempts.firstWhere(
        (a) => a['status'] == 'active',
        orElse: () => null,
      );

      if (activeAttempt != null) {
        final attemptId = activeAttempt['_id'];
        setState(() {
          _activeAttemptId = attemptId;
        });
        debugPrint('✅ Active attempt ID for location broadcasting: $_activeAttemptId');
        debugPrint('📋 Attempt details: status=${activeAttempt['status']}, collectorId=${activeAttempt['collectorId']}');
      } else {
        debugPrint('⚠️ No active collection attempt found for location broadcasting');
        debugPrint('📋 Available attempts: ${attempts.map((a) => '${a['_id']}: ${a['status']}').join(', ')}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting active attempt ID: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Broadcast collector location via WebSocket
  /// Uses hybrid approach: broadcast when moved ≥5m OR ≥5s elapsed (industry standard)
  void _broadcastLocation(LatLng location, double? accuracy, double? speed, double? heading) {
    if (_activeAttemptId == null) {
      debugPrint('⚠️ Cannot broadcast location: _activeAttemptId is null');
      return; // No active attempt
    }

    final notificationService = ref.read(notificationServiceProvider);
    if (!notificationService.isConnected) {
      debugPrint('⚠️ WebSocket not connected, cannot broadcast location');
      return;
    }

    final now = DateTime.now();
    bool shouldBroadcast = false;
    String? broadcastReason;

    // Check if this is the first broadcast
    if (_lastLocationBroadcastTime == null || _lastBroadcastLocation == null) {
      shouldBroadcast = true;
      broadcastReason = 'initial broadcast';
    } else {
      // Calculate distance moved since last broadcast
      final distanceMoved = Geolocator.distanceBetween(
        _lastBroadcastLocation!.latitude,
        _lastBroadcastLocation!.longitude,
        location.latitude,
        location.longitude,
      );

      // Calculate time elapsed since last broadcast
      final timeElapsed = now.difference(_lastLocationBroadcastTime!);

      // Hybrid approach: broadcast if moved ≥5m OR ≥5s elapsed
      if (distanceMoved >= _locationBroadcastDistanceThreshold) {
        shouldBroadcast = true;
        broadcastReason = 'distance threshold (${distanceMoved.toStringAsFixed(1)}m ≥ ${_locationBroadcastDistanceThreshold}m)';
      } else if (timeElapsed >= _locationBroadcastInterval) {
        shouldBroadcast = true;
        broadcastReason = 'time threshold (${timeElapsed.inSeconds}s ≥ ${_locationBroadcastInterval.inSeconds}s)';
      }
    }

    if (!shouldBroadcast) {
      // Don't broadcast yet - conditions not met
      return;
    }

    try {
      debugPrint('📡 Broadcasting collector location: attemptId=$_activeAttemptId, lat=${location.latitude}, lng=${location.longitude}, reason: $broadcastReason');
      notificationService.sendCollectorLocationUpdate(
        attemptId: _activeAttemptId!,
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: accuracy,
        speed: speed,
        heading: heading,
      );

      setState(() {
        _lastLocationBroadcastTime = now;
        _lastBroadcastLocation = location; // Update last broadcast location
      });
      debugPrint('✅ Location broadcasted successfully ($broadcastReason)');
    } catch (e, stackTrace) {
      debugPrint('❌ Error broadcasting location: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Stop location broadcasting
  void _stopLocationBroadcasting() {
    setState(() {
      _activeAttemptId = null;
      _lastLocationBroadcastTime = null;
      _lastBroadcastLocation = null; // Reset last broadcast location
    });
    debugPrint('🛑 Stopped location broadcasting');
  }



  Future<void> _updateDistanceToDestination() async {
    if (_currentLocation == null) return;
    
    try {
      // Use current location from stream if available, otherwise get new position
      LatLng currentLatLng = _currentLocation!;
      
      // Only get new position if we don't have a recent one from the stream
      // Optimized interval matching industry standards (15 seconds)
      if (_lastLocationTime == null || 
          DateTime.now().difference(_lastLocationTime!) > const Duration(seconds: 15)) {
        try {
          const LocationSettings locationSettings = LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5), // Increased timeout
          );
          final position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
          currentLatLng = LatLng(position.latitude, position.longitude);
        } catch (locationError) {
          // If getting new position fails, just use the current one from stream
          debugPrint('⚠️ Could not get new position, using current: $locationError');
          // Don't throw, just continue with current location
        }
      }
      
      // Calculate straight-line distance first
      final straightLineDistance = Geolocator.distanceBetween(
        currentLatLng.latitude,
        currentLatLng.longitude,
        widget.destination.latitude,
        widget.destination.longitude,
      );
      
      double remainingDistance = 0;
      
      // For close drops (< 50m), always use straight-line distance
      if (straightLineDistance < 50.0) {
        remainingDistance = straightLineDistance;
        debugPrint('🎯 Using straight-line distance for close drop: ${remainingDistance.toStringAsFixed(2)}m');
      } else if (_navigationSteps.isNotEmpty) {
        // Find the closest point on the route to current position
        double minDistance = double.infinity;
        LatLng closestPoint = _navigationSteps.first.polylinePoints.first;
        int closestStepIndex = 0;
        int closestPointIndex = 0; // Track the index in the full polyline
        
        // Collect all polyline points with their indices
        List<LatLng> allPolylinePoints = [];
        for (var step in _navigationSteps) {
          allPolylinePoints.addAll(step.polylinePoints);
        }
        
        // Search through all route steps to find the closest point
        int globalIndex = 0;
        for (int i = 0; i < _navigationSteps.length; i++) {
          final step = _navigationSteps[i];
          for (int j = 0; j < step.polylinePoints.length; j++) {
            final point = step.polylinePoints[j];
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
              closestPointIndex = globalIndex;
            }
            globalIndex++;
          }
        }
        
        // Update the closest polyline point index for polyline shrinking
        // Also update current step index if we've progressed to a new step
        if (mounted) {
          bool stepChanged = false;
          setState(() {
            // Store previous index before updating
            _previousClosestPolylinePointIndex = _closestPolylinePointIndex;
            _closestPolylinePointIndex = closestPointIndex;
            
            // Update current step index if we've moved to a new step
            // Use the closest step index, but only advance forward (don't go backwards)
            if (closestStepIndex > _currentStepIndex) {
              _currentStepIndex = closestStepIndex;
              stepChanged = true;
            }
          });
          
          // Update polyline to remove passed segments (uses previous index to calculate distance)
          _updatePolylineForProgress();
          
          // Update turn instructions if we've moved to a new step
          if (stepChanged) {
            _updateNextTurnInfo();
          } else {
            // Even if step hasn't changed, update the distance to next turn dynamically
            _updateNextTurnDistance();
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
          // Only consider "reached destination" when very close (within 5m)
          // This prevents the "You have arrived" card from showing too early
          _hasReachedDestination = remainingDistance <= 5.0;
          
          // Show slide button when collector is within threshold distance OR when destination is reached
          // For very close drops (< 10m), always show button
          // For normal drops, show button when within threshold
          // Always show when destination is reached to allow collection confirmation
          final shouldShowSlideButton = _hasReachedDestination || 
                                       remainingDistance < 10.0 || 
                                       remainingDistance <= _arrivalThreshold;
          
          // Auto-expand card when slide button appears
          if (shouldShowSlideButton && !_showSlideButton) {
            _isNavigationCardMinimized = false;
          }
          
          _showSlideButton = shouldShowSlideButton;
        });
        
      }
    } catch (e) {
      debugPrint('Error updating distance: $e');
      // Don't let this error crash the app
    }
  }

  void _updatePolylineForProgress() {
    if (_navigationSteps.isEmpty || _polylines.isEmpty) {
      return;
    }
    
    // Collect all polyline points from all steps
    List<LatLng> allPolylinePoints = [];
    for (var step in _navigationSteps) {
      allPolylinePoints.addAll(step.polylinePoints);
    }
    
    if (allPolylinePoints.isEmpty) {
      return;
    }
    
    // Calculate distance traveled along the route since last update
    // This is the distance from the previous closest point to the current closest point
    double distanceTraveled = 0.0;
    if (_previousClosestPolylinePointIndex < _closestPolylinePointIndex) {
      // Moved forward - calculate distance along the route
      for (int i = _previousClosestPolylinePointIndex; i < _closestPolylinePointIndex; i++) {
        if (i + 1 < allPolylinePoints.length) {
          distanceTraveled += Geolocator.distanceBetween(
            allPolylinePoints[i].latitude,
            allPolylinePoints[i].longitude,
            allPolylinePoints[i + 1].latitude,
            allPolylinePoints[i + 1].longitude,
          );
        }
      }
    }
    
    // Accumulate distance traveled
    _lastPolylineUpdateDistance += distanceTraveled;
    
    // Only update if we've moved at least 5 meters forward (same as location stream)
    const double updateThreshold = 5.0; // meters
    final totalDistanceTraveled = _lastPolylineUpdateDistance;
    if (totalDistanceTraveled < updateThreshold) {
      // Not enough distance traveled, skip update
      return;
    }
    
    // Reset accumulated distance after update
    _lastPolylineUpdateDistance = 0.0;
    
    // Calculate start index with a small buffer (look back 2 points for smooth transition)
    int startIndex = (_closestPolylinePointIndex - 2).clamp(0, allPolylinePoints.length - 1);
    
    // Don't update if too early in the route (first few points)
    if (startIndex < 3) {
      return;
    }
    
    List<LatLng> remainingPoints = allPolylinePoints.sublist(startIndex);
    
    // Ensure we have at least 2 points for a valid polyline
    if (remainingPoints.length < 2) {
      return;
    }
    
    // If we're very close to destination, ensure destination is included
    final lastPoint = remainingPoints.last;
    final distanceToDestination = Geolocator.distanceBetween(
      lastPoint.latitude,
      lastPoint.longitude,
      widget.destination.latitude,
      widget.destination.longitude,
    );
    
    if (distanceToDestination > 10 && remainingPoints.last != widget.destination) {
      remainingPoints.add(widget.destination);
    }
    
    // Update the polyline with remaining points
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: remainingPoints,
          color: const Color(0xFF00695C),
          width: _transportationMode.polylineWidth,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          patterns: _transportationMode.polylinePattern,
        ),
      };
    });
    
    debugPrint('🔄 Updated polyline: moved ${distanceTraveled.toStringAsFixed(1)}m (total: ${totalDistanceTraveled.toStringAsFixed(1)}m), removed ${startIndex} passed points, showing ${remainingPoints.length} remaining points');
  }

  void _createStraightLineRoute(LatLng origin, LatLng destination, double distance) {
    debugPrint('🎯 Creating straight-line route for close drop');
    
    // Create a simple straight-line polyline
    final points = <LatLng>[origin, destination];
    
    // Create polyline with pattern based on transportation mode
    final polyline = Polyline(
      polylineId: const PolylineId('straight_line_route'),
      points: points,
      color: const Color(0xFF00695C),
      width: _transportationMode.polylineWidth,
      patterns: _transportationMode.polylinePattern,
    );
    
    // Update state
    setState(() {
      _polylines = {polyline};
      _navigationSteps = [];
      _currentStepIndex = 0;
      _nextTurnInstruction = AppLocalizations.of(context).walkStraightToDestination;
      _nextTurnDistance = '${distance.toStringAsFixed(0)}m';
      _nextStreetName = AppLocalizations.of(context).directRoute;
      _routeDistance = '${distance.toStringAsFixed(0)}m';
      _routeDuration = '1 min'; // Estimated walking time
    });
    
    debugPrint('✅ Straight-line route created: ${distance.toStringAsFixed(2)}m');
  }

  // Generate cache key for route
  String _generateCacheKey(LatLng origin, LatLng destination, TransportationMode mode) {
    // Include dropId in cache key so routes are per-drop
    // Round coordinates to 4 decimal places (~11 meters precision) to allow slight variations
    final originLat = origin.latitude.toStringAsFixed(4);
    final originLng = origin.longitude.toStringAsFixed(4);
    final destLat = destination.latitude.toStringAsFixed(4);
    final destLng = destination.longitude.toStringAsFixed(4);
    return '${widget.dropId}_${originLat}_${originLng}_${destLat}_${destLng}_${mode.name}';
  }
  
  // Clear cache for this drop (clears all transportation modes for this drop)
  Future<void> _clearRouteCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear cache for all transportation modes for this drop
      // Since we don't know the exact origin used, we'll clear all cache entries for this drop
      final allKeys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix)).toList();
      final dropCacheKeys = allKeys.where((key) => key.contains('_${widget.dropId}_')).toList();
      
      for (final key in dropCacheKeys) {
        await prefs.remove(key);
        // Extract cache key from pref key (remove prefix)
        final cacheKey = key.replaceFirst(_cachePrefix, '');
        _inMemoryCache.remove(cacheKey);
      }
      
      debugPrint('🧹 Cleared route cache for drop: ${widget.dropId} (${dropCacheKeys.length} entries)');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  // Get cached route
  Future<_CachedRoute?> _getCachedRoute(String cacheKey) async {
    debugPrint('🔍 Checking cache for key: $cacheKey');
    
    // Check in-memory cache first (fastest)
    final inMemoryRoute = _inMemoryCache[cacheKey];
    if (inMemoryRoute != null && inMemoryRoute.isValid) {
      debugPrint('✅ Found route in IN-MEMORY cache');
      debugPrint('📅 Cached at: ${inMemoryRoute.cachedAt}');
      return inMemoryRoute;
    } else if (inMemoryRoute != null && !inMemoryRoute.isValid) {
      debugPrint('⚠️ In-memory cache entry exists but is invalid');
    } else {
      debugPrint('❌ Not found in in-memory cache');
    }

    // Check SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKeyPrefs = '$_cachePrefix$cacheKey';
      debugPrint('🔍 Checking SharedPreferences for key: $cacheKeyPrefs');
      final cachedJson = prefs.getString(cacheKeyPrefs);
      
      if (cachedJson != null) {
        debugPrint('✅ Found entry in SharedPreferences, parsing...');
        final cachedRoute = _CachedRoute.fromJson(json.decode(cachedJson) as Map<String, dynamic>);
        if (cachedRoute.isValid) {
          debugPrint('✅ Found route in SHAREDPREFERENCES cache');
          debugPrint('📅 Cached at: ${cachedRoute.cachedAt}');
          // Update in-memory cache
          _inMemoryCache[cacheKey] = cachedRoute;
          return cachedRoute;
        } else {
          debugPrint('⚠️ Cached route invalid, removing from cache');
          await prefs.remove(cacheKeyPrefs);
        }
      } else {
        debugPrint('❌ Not found in SharedPreferences cache');
      }
    } catch (e) {
      debugPrint('❌ Error reading cache: $e');
    }

    debugPrint('❌ No valid cache found');
    return null;
  }

  // Store route in cache
  Future<void> _storeRouteInCache(String cacheKey, _CachedRoute route) async {
    // Store in in-memory cache
    _inMemoryCache[cacheKey] = route;
    
    // Store in SharedPreferences cache (limit to last 10 routes to avoid storage bloat)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKeyPrefs = '$_cachePrefix$cacheKey';
      await prefs.setString(cacheKeyPrefs, json.encode(route.toJson()));
      
      // Clean up old cache entries (keep only last 10)
      await _cleanupOldCacheEntries(prefs);
      
      debugPrint('✅ Route stored in cache (key: $cacheKey)');
    } catch (e) {
      debugPrint('❌ Error storing cache: $e');
    }
  }

  // Process route data (extracted from _calculateRoute for reuse with cached routes)
  void _processRouteData(
    Map<String, dynamic> data,
    List<LatLng> points,
    List<NavigationStep> navigationSteps,
    String routeDistance,
    String routeDuration,
  ) {
    setState(() {
      _routeDistance = routeDistance;
      _routeDuration = routeDuration;
    });

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
            width: _transportationMode.polylineWidth,
            geodesic: true,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            patterns: _transportationMode.polylinePattern,
          ),
        };
        // Initialize closest point index to 0 (start of route)
        _closestPolylinePointIndex = 0;
        _previousClosestPolylinePointIndex = 0;
        _lastPolylineUpdateDistance = 0.0;
      });
      
      debugPrint('✅ Polyline added to map with ${_polylines.length} polylines');
      debugPrint('Polyline color: ${const Color(0xFF00695C)}');
      debugPrint('Polyline start: ${points.first.latitude}, ${points.first.longitude}');
      debugPrint('Polyline end: ${points.last.latitude}, ${points.last.longitude}');
      debugPrint('🎉 Route calculation and polyline creation completed successfully!');
    } else {
      debugPrint('Warning: No polyline points decoded!');
    }

    _navigationSteps = navigationSteps;
    
    debugPrint('✅ Navigation steps processed successfully!');

    _updateNextTurnInfo();
    
    // Initialize closest point index
    _closestPolylinePointIndex = 0;
    _previousClosestPolylinePointIndex = 0;
    _lastPolylineUpdateDistance = 0.0;
    
    // Center camera on the beginning of the route with high zoom
    _centerCameraOnRouteStart();
    _initializeTimer(); // Initialize timer after route is calculated
  }

  // Clean up old cache entries (keep only last 10)
  Future<void> _cleanupOldCacheEntries(SharedPreferences prefs) async {
    try {
      final allKeys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix)).toList();
      
      if (allKeys.length > 10) {
        // Get all cached routes with their timestamps
        final routesWithTime = <MapEntry<String, DateTime>>[];
        for (final key in allKeys) {
          try {
            final cachedJson = prefs.getString(key);
            if (cachedJson != null) {
              final data = json.decode(cachedJson) as Map<String, dynamic>;
              final cachedAt = DateTime.parse(data['cachedAt'] as String);
              routesWithTime.add(MapEntry(key, cachedAt));
            }
          } catch (e) {
            // Skip invalid entries
            continue;
          }
        }
        
        // Sort by time (oldest first) and remove oldest entries
        routesWithTime.sort((a, b) => a.value.compareTo(b.value));
        final toRemove = routesWithTime.length - 10;
        
        for (int i = 0; i < toRemove; i++) {
          await prefs.remove(routesWithTime[i].key);
        }
        
        debugPrint('🧹 Cleaned up ${toRemove} old cache entries');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up cache: $e');
    }
  }

  Future<void> _calculateRoute(LatLng origin, LatLng destination) async {
    try {
      debugPrint('Calculating route from ${origin.latitude}, ${origin.longitude} to ${destination.latitude}, ${destination.longitude}');
      
      // Calculate straight-line distance first
      final straightLineDistance = Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      );
      
      debugPrint('📏 Straight-line distance: ${straightLineDistance.toStringAsFixed(2)} meters');
      
      // For very close drops (< 50m), use straight-line route instead of driving directions
      if (straightLineDistance < 50.0) {
        debugPrint('🎯 Very close drop detected (${straightLineDistance.toStringAsFixed(2)}m) - Using straight-line route');
        _createStraightLineRoute(origin, destination, straightLineDistance);
        return;
      }

      // Check cache before making API call
      final cacheKey = _generateCacheKey(origin, destination, _transportationMode);
      debugPrint('🔍 Cache key: $cacheKey');
      final cachedRoute = await _getCachedRoute(cacheKey);
      
      if (cachedRoute != null) {
        _cacheHitCount++;
        debugPrint('✅ CACHE HIT #$_cacheHitCount - Using cached route (saved API call!)');
        debugPrint('📊 API Calls: $_apiCallCount | Cache Hits: $_cacheHitCount');
        // Use cached route data
        _processRouteData(cachedRoute.routeData, cachedRoute.polylinePoints, cachedRoute.navigationSteps, cachedRoute.routeDistance, cachedRoute.routeDuration);
        return;
      }

      _apiCallCount++;
      debugPrint('📡 CACHE MISS - No valid cache found, making API call #$_apiCallCount...');
      debugPrint('📊 API Calls: $_apiCallCount | Cache Hits: $_cacheHitCount');
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=${_transportationMode.apiValue}'
        '&units=metric'
        '&key=AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E'
      );

      debugPrint('Directions API URL: ${url.toString().replaceAll('AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E', 'API_KEY_HIDDEN')}');
      debugPrint('Using API key: AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E');

      final dio = ApiClientConfig.createDio();
      debugPrint('🌐 ========== MAKING API CALL #$_apiCallCount ==========');
      debugPrint('🌐 API URL: ${url.toString().replaceAll('AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E', 'API_KEY_HIDDEN')}');
      debugPrint('🌐 Origin: ${origin.latitude}, ${origin.longitude}');
      debugPrint('🌐 Destination: ${destination.latitude}, ${destination.longitude}');
      debugPrint('🌐 Mode: ${_transportationMode.name}');
      debugPrint('🌐 ============================================');
      
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
        debugPrint('Polyline points count: ${points.length}');

        // Parse navigation steps
        final steps = leg['steps'] as List;
        debugPrint('✅ Processing ${steps.length} navigation steps...');
        
        final navigationSteps = steps.map((step) {
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

        // Extract route distance and duration
        final routeDistance = leg['distance'] is Map && leg['distance']['text'] is String
            ? leg['distance']['text'] as String
            : 'Unknown distance';
        final routeDuration = leg['duration'] is Map && leg['duration']['text'] is String
            ? leg['duration']['text'] as String
            : 'Unknown duration';
        
        // Store route in cache for future use
        final cachedRoute = _CachedRoute(
          routeData: data,
          navigationSteps: navigationSteps,
          polylinePoints: points,
          routeDistance: routeDistance,
          routeDuration: routeDuration,
          cachedAt: DateTime.now(),
          transportationMode: _transportationMode.name,
        );
        
        await _storeRouteInCache(cacheKey, cachedRoute);
        
        // Process the route data
        _processRouteData(data, points, navigationSteps, routeDistance, routeDuration);
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

  void _updateNextTurnDistance() {
    if (_currentLocation == null || _currentStepIndex >= _navigationSteps.length) {
      return;
    }
    
    // Calculate the actual distance to the next turn dynamically
    final currentStep = _navigationSteps[_currentStepIndex];
    if (currentStep.polylinePoints.isEmpty) {
      return;
    }
    
    // Find the closest point on the current step's polyline
    double minDistance = double.infinity;
    int closestPointIndex = 0;
    
    for (int i = 0; i < currentStep.polylinePoints.length; i++) {
      final point = currentStep.polylinePoints[i];
      final distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }
    }
    
    // Calculate distance from closest point to the end of this step
    double distanceToTurn = 0;
    for (int i = closestPointIndex; i < currentStep.polylinePoints.length - 1; i++) {
      distanceToTurn += Geolocator.distanceBetween(
        currentStep.polylinePoints[i].latitude,
        currentStep.polylinePoints[i].longitude,
        currentStep.polylinePoints[i + 1].latitude,
        currentStep.polylinePoints[i + 1].longitude,
      );
    }
    
    // Add distance from current position to closest point
    distanceToTurn += minDistance;
    
    // Update the distance display
    if (mounted) {
      setState(() {
        _nextTurnDistance = _formatDistance(distanceToTurn);
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

  Widget _buildTransportationModeChip(
    BuildContext context,
    TransportationMode mode,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final isSelected = _transportationMode == mode;
    return GestureDetector(
      onTap: () {
        // Prevent changing if locked
        if (_transportationModeLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).transportationModeLocked),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        
        if (_transportationMode != mode) {
          setState(() {
            _transportationMode = mode;
            _transportationModeLocked = true; // Lock after first change
          });
          _saveTransportationMode();
          
          // Update existing polyline with new pattern immediately
          if (_polylines.isNotEmpty) {
            final existingPolyline = _polylines.first;
            setState(() {
              _polylines = {
                Polyline(
                  polylineId: existingPolyline.polylineId,
                  points: existingPolyline.points,
                  color: existingPolyline.color,
                  width: mode.polylineWidth,
                  geodesic: existingPolyline.geodesic,
                  startCap: existingPolyline.startCap,
                  endCap: existingPolyline.endCap,
                  patterns: mode.polylinePattern,
                ),
              };
            });
          }
          // Recalculate route with new mode
          if (_currentLocation != null) {
            _calculateRoute(_currentLocation!, widget.destination);
          }
        }
      },
      child: Opacity(
        opacity: _transportationModeLocked && !isSelected ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00695C)
                : (isDark ? AppColors.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00695C)
                  : (isDark
                      ? AppColors.darkPrimary.withOpacity(0.3)
                      : AppColors.lightPrimary.withOpacity(0.3)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                mode.icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  mode.getDisplayName(context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected && _transportationModeLocked) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.lock,
                  size: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            /// ---------------- HEADER ----------------
              Row(
                children: [
                  Container(
                  padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                    color: const Color(0xFF00695C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  child: const Icon(
                      Icons.route,
                    color: Color(0xFF00695C),
                    size: 22,
                    ),
                  ),
                const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).routeToDrop,
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
                  onPressed: () {
                    setState(() {
                      _isNavigationCardMinimized = !_isNavigationCardMinimized;
                    });
                  },
                  icon: Icon(
                    _isNavigationCardMinimized ? Icons.expand_more : Icons.expand_less,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
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
              
            const SizedBox(height: 12),
            
            /// ---------------- TRANSPORTATION MODE SELECTOR ----------------
            Row(
              children: [
                Expanded(
                  child: _buildTransportationModeChip(
                    context,
                    TransportationMode.walking,
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTransportationModeChip(
                    context,
                    TransportationMode.driving,
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTransportationModeChip(
                    context,
                    TransportationMode.bicycling,
                    isDark,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            /// ---------------- CONDITIONAL CONTENT (MINIMIZED/EXPANDED) ----------------
            if (_isNavigationCardMinimized) ...[
              /// ---------------- MINIMIZED CONTENT ----------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.my_location,
                      color: const Color(0xFF00695C),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatDistance(_distanceToDestination)} ${AppLocalizations.of(context).remaining}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _remainingSeconds < 300
                            ? Colors.orange.withOpacity(0.2)
                            : const Color(0xFF00695C).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatTime(_remainingSeconds),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _remainingSeconds < 300
                              ? Colors.orange
                              : const Color(0xFF00695C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
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
              const SizedBox(height: 12),
              ],
              
            /// ---------------- DISTANCE TO DESTINATION ----------------
              Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            ? AppLocalizations.of(context).youHaveArrivedAtDestination
                            : '${_formatDistance(_distanceToDestination)} ${AppLocalizations.of(context).remaining}',
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
              
            const SizedBox(height: 6),
              
            /// ---------------- TIMER ----------------
              Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        '${AppLocalizations.of(context).completeCollectionIn} ${_formatTime(_remainingSeconds)}',
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
              
            const SizedBox(height: 12),
              
            /// ---------------- ACTION BUTTONS ----------------
              // Show slide button when close to drop or when destination is reached
              if (_showSlideButton || _hasReachedDestination) ...[
                // Slide to Collect Button (when close to drop or at destination)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSlideButton(),
                ),
                
                // "Drop not found?" text link when close or at destination
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () {
                      _showCancellationDialog(context);
                    },
                    child: Text(
                      AppLocalizations.of(context).dropNotFound,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
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
                      AppLocalizations.of(context).calculatingRoute,
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
            title: Text(AppLocalizations.of(context).leaveCollection),
            content: Text(
              AppLocalizations.of(context).leaveCollectionMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context).stay),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lightError,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context).leave),
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
              onMapCreated: (GoogleMapController controller) async {
                _mapController = controller;
                setState(() {
                  _hasInitialCameraPosition = true;
                });
                debugPrint('🗺️ Map created - Initial camera position set');
                // Apply map style based on theme
                final brightness = Theme.of(context).brightness;
                final style = brightness == Brightness.dark ? MapStyles.dark : MapStyles.light;
                await controller.setMapStyle(style);
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
                  infoWindow: InfoWindow(title: AppLocalizations.of(context).dropLocation),
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
              padding: const EdgeInsets.only(top: 180), // Add top padding to account for navigation banner
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
            child: SizedBox(
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

                // Drop Details button
                FloatingActionButton(
                  heroTag: 'drop_details_fab',
                  onPressed: () => _showDropDetailsCard(context),
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.info_outline),
                ),

                const SizedBox(height: 12),

                // Test Slide Button (for testing purposes)
                FloatingActionButton(
                  heroTag: 'test_slide_fab',
                  onPressed: () {
                    debugPrint('🧪 Test button pressed - toggling slide button');
                    setState(() {
                      final wasSlideButtonVisible = _showSlideButton;
                      _showSlideButton = !_showSlideButton;
                      
                      // Auto-expand card when slide button becomes visible
                      if (_showSlideButton && !wasSlideButtonVisible) {
                        _isNavigationCardMinimized = false;
                      }
                    });
                  },
                  backgroundColor: _showSlideButton ? Colors.red : Colors.orange,
                  foregroundColor: Colors.white,
                  child: Icon(_showSlideButton ? Icons.close : Icons.swipe),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
          ),
        ],
      ),
    ),
  );
}

  
  Widget _buildSlideButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 56, // Match the height of OutlinedButton with vertical padding 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00695C),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
          ),

          // Progress fill
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width * 0.8 * _slideProgress).clamp(0.0, MediaQuery.of(context).size.width * 0.8),
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF00695C),
            ),
          ),

          // Slide handle
          Positioned(
            left: (MediaQuery.of(context).size.width * 0.8 * _slideProgress + 8).clamp(8.0, MediaQuery.of(context).size.width * 0.8 - 28),
            top: 16,
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

                // Effective width where handle can move
                final trackWidth = MediaQuery.of(context).size.width * 0.8;
                final handleSize = 24.0;
                final effective = trackWidth - handleSize - 16; // 8px padding on each side

                // Progress is handle-left within [0, effective] normalized to [0..1]
                final px = (local.dx - handleSize / 2 - 8).clamp(0.0, effective);
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
              child: Icon(
                Icons.arrow_forward,
                color: _slideProgress > 0.5
                    ? Colors.white
                    : const Color(0xFF00695C),
                size: 24,
              ),
            ),
          ),

          // Text overlay
          Positioned.fill(
            child: Center(
              child: Text(
                _slideProgress > 0.5 ? AppLocalizations.of(context).releaseToCollect : AppLocalizations.of(context).slideToCollect,
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
  }

  String _getLocalizedBottleType(String bottleTypeString) {
    try {
      // Convert string to BottleType enum
      BottleType bottleType;
      switch (bottleTypeString.toLowerCase()) {
        case 'plastic':
          bottleType = BottleType.plastic;
          break;
        case 'can':
          bottleType = BottleType.can;
          break;
        case 'mixed':
          bottleType = BottleType.mixed;
          break;
        default:
          bottleType = BottleType.plastic; // Default fallback
      }
      // Use the localized display name
      return bottleType.localizedDisplayName(context);
    } catch (e) {
      // Fallback to original string if conversion fails
      return bottleTypeString;
    }
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // Handle both cancellation and exit navigation logic
          if (_showSlideButton) {
            // Close to drop - show collection cancellation dialog with reason selection
            _showCancellationDialog(context);
          } else {
            // Far from drop - show simple exit navigation dialog
            _temporaryExit();
          }
        },
        icon: const Icon(Icons.cancel),
        label: Text(AppLocalizations.of(context).cancelCollection),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  

  void _completeSlideCollection() async {
    // Animate the slide completion
    await _slideAnimationController.forward();
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
        content: Text(AppLocalizations.of(context).collectionConfirmed),
        backgroundColor: Color(0xFF00695C),
        duration: Duration(seconds: 1),
      ),
    );

    // Use the existing _confirmCollection method to avoid duplicate reward calculations
    _confirmCollection(context);
  }


  
  void _showDropDetailsCard(BuildContext context) {
    final activeCollection = ref.read(navigationControllerProvider);
    
    if (activeCollection == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.recycling,
                      color: Color(0xFF00695C),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).dropInformation,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Drop Image
              if (activeCollection.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    activeCollection.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Items Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Image.asset(
                              'assets/icons/water-bottle.png',
                              width: 32,
                              height: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${activeCollection.numberOfBottles}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context).plasticBottles,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        Column(
                          children: [
                            Image.asset(
                              'assets/icons/can.png',
                              width: 32,
                              height: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${activeCollection.numberOfCans}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context).cans,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (activeCollection.bottleType != null) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).bottleType}: ',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _getLocalizedBottleType(activeCollection.bottleType!),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Notes
              if (activeCollection.notes != null && activeCollection.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activeCollection.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Leave Outside
              if (activeCollection.leaveOutside) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.door_front_door,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).leaveOutside,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Report Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close details dialog
                    showDialog(
                      context: context,
                      builder: (context) => ReportDropDialog(dropId: widget.dropId),
                    );
                  },
                  icon: const Icon(Icons.flag, size: 20),
                  label: Text(AppLocalizations.of(context).reportDrop),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  void _showCancellationDialog(BuildContext context) {
    CancellationReason? selectedReason;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context).cancelCollection),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).cancelCollectionMessage,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
            ...CancellationReason.values.map(
              (reason) => RadioListTile<CancellationReason>(
                title: Text(reason.localizedDisplayName(context)),
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
              child: Text(AppLocalizations.of(context).back),
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
              child: Text(AppLocalizations.of(context).cancelCollection),
            ),
          ],
        ),
      ),
    );
  }

void _showWarningNotification() async {
  if (_warningNotificationSent) return;
  
  _warningNotificationSent = true;
  debugPrint('⚠️ Showing warning notification - Timer at 30% remaining');
  
  final activeCollection = ref.read(navigationControllerProvider.notifier).activeCollection;
  if (activeCollection != null) {
    try {
      // Show in-app notification (SnackBar) when in foreground
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(AppLocalizations.of(context).collectionTimerRunningLow(_formatTime(_remainingSeconds))),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: AppLocalizations.of(context).view,
              textColor: Colors.white,
              onPressed: () {
                // Navigate to navigation screen if not already there
                debugPrint('⚠️ User tapped view on warning notification');
              },
            ),
          ),
        );
      }
      
      // Also show system notification for background cases
      await LocalNotificationService().showNotification(
        title: AppLocalizations.of(context).collectionTimerWarning,
        body: AppLocalizations.of(context).yourCollectionTimerRunningLow(_formatTime(_remainingSeconds)),
        id: 2000,
        payload: 'timer_warning:${activeCollection.dropoffId}',
      );
      
      debugPrint('⚠️ Warning notification sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending warning notification: $e');
    }
  }
}

  Future<void> _handleCancellation(CancellationReason reason) async {
    try {
      final authState = ref.read(authNotifierProvider);
      final collectorId = authState?.value?.id;
      
      if (collectorId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).errorUserNotAuthenticated),
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
      
      // Clear transportation mode for this drop
      await _clearTransportationMode();
      
      // Clear route cache for this drop
      await _clearRouteCache();
      
      // Stop location broadcasting
      _stopLocationBroadcasting();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          // ⚠️ Removed `const` so string interpolation works
            content: Text(AppLocalizations.of(context).collectionCancelled(reason.localizedDisplayName(context))),
            backgroundColor: AppColors.lightMapPin,
          ),
        );
        
        // Navigate back to home screen
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorCancellingCollection(e.toString())),
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
            SnackBar(
              content: Text(AppLocalizations.of(context).errorUserNotAuthenticated),
              backgroundColor: AppColors.lightError,
            ),
          );
        }
        return;
      }
      
      debugPrint('🧪 DEBUG: Confirming collection for drop: ${widget.dropId}');
      final rewardData = await ref.read(dropsControllerProvider.notifier)
          .confirmCollectionWithRewards(widget.dropId);
      
      // Show collection success popup with reward information
      if (rewardData != null && mounted) {
        // Get reward data from the backend response
        final rewardInfo = rewardData['rewardData'] ?? {};
        final currentTier = rewardInfo['currentTier']?['tier'] ?? 1;
        final tierName = rewardInfo['currentTier']?['name'] ?? 'Bronze Collector';
        final totalPoints = rewardInfo['totalPoints'] ?? 0;
        final pointsAwarded = rewardInfo['pointsAwarded'] ?? 0;
        
        debugPrint('🎉 Reward data: $pointsAwarded points awarded, tier: $tierName');
        
        // Show the collection success popup
        ref.read(collectionSuccessProvider.notifier).showCollectionSuccess(
          pointsAwarded: pointsAwarded,
          tierName: tierName,
          currentTier: currentTier,
          totalPoints: totalPoints,
          tierUpgraded: false,
        );
      }
      
      debugPrint('🧪 DEBUG: Collection confirmed, clearing state...');
      // Clear the persistent collection state
      await ref.read(navigationControllerProvider.notifier).completeCollection();
      
      // Refresh collection attempts to update the session value card
      try {
        ref.read(collectionAttemptsProvider.notifier).refresh();
        debugPrint('✅ Collection attempts refreshed');
      } catch (e) {
        debugPrint('⚠️ Failed to refresh collection attempts: $e');
      }
      
      // Wait a moment for backend to process earnings
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Refresh user data to get updated earningsHistory (like rewardHistory)
      try {
        await ref.read(authNotifierProvider.notifier).refreshUserData();
        debugPrint('✅ User data refreshed (earningsHistory should be updated)');
      } catch (e) {
        debugPrint('⚠️ Failed to refresh user data: $e');
      }
      
      // Refresh earnings providers to update session value card
      try {
        ref.invalidate(todayEarningsProvider);
        ref.invalidate(earningsHistoryProvider({'page': 1, 'limit': 20}));
        debugPrint('✅ Earnings providers refreshed');
      } catch (e) {
        debugPrint('⚠️ Failed to refresh earnings providers: $e');
      }
      
      debugPrint('🧪 DEBUG: State cleared, navigating to home...');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).collectionCompletedSuccessfully),
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
    
    // Calculate bearing from start to a point further along the route for better alignment
    // This ensures the camera aligns with the overall polyline direction, especially for straight lines
    double bearing = 0.0;
    LatLng? directionPoint;
    
    // Collect all polyline points from all steps
    List<LatLng> allPolylinePoints = [];
    for (var step in _navigationSteps) {
      allPolylinePoints.addAll(step.polylinePoints);
    }
    
    if (allPolylinePoints.length >= 2) {
      // Find a point that's at least 100 meters away from start, or use a point 20% along the route
      int targetIndex = (allPolylinePoints.length * 0.2).round().clamp(1, allPolylinePoints.length - 1);
      directionPoint = allPolylinePoints[targetIndex];
      
      // If the point is too close, find a point further along
      double distance = Geolocator.distanceBetween(
        startPoint.latitude,
        startPoint.longitude,
        directionPoint.latitude,
        directionPoint.longitude,
      );
      
      // If less than 100 meters, try to find a point further along
      if (distance < 100 && allPolylinePoints.length > targetIndex + 5) {
        targetIndex = (allPolylinePoints.length * 0.4).round().clamp(1, allPolylinePoints.length - 1);
        directionPoint = allPolylinePoints[targetIndex];
      }
      
      bearing = _calculateBearing(startPoint, directionPoint);
      debugPrint('🧭 Calculated bearing from start to point ${targetIndex}/${allPolylinePoints.length}: ${bearing.toStringAsFixed(1)}°');
    }
    
    // Zoom in more (zoom 19.5) and align camera with polyline direction
    // The padding set on GoogleMap widget will ensure polyline is visible below navigation banner
    final cameraUpdate = CameraUpdate.newLatLngZoom(startPoint, 19.5);
    _mapController!.animateCamera(cameraUpdate).then((_) {
      // Set the bearing after the camera position is set to align with polyline direction
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: startPoint,
          zoom: 18.5,
          tilt: 0,
          bearing: bearing,
        ),
      ));
    });
    
    debugPrint('📍 Centering camera on route start at ${startPoint.latitude}, ${startPoint.longitude} with zoom 19.5 and bearing ${bearing.toStringAsFixed(1)}°');
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

  void _confirmCollection(BuildContext context) async {
    try {
      debugPrint('✅ Confirm Collection button pressed!');
      
      final authState = ref.read(authNotifierProvider);
      final collectorId = authState?.value?.id;

      if (collectorId != null) {
        debugPrint('✅ Confirming collection (completes attempt and adds to timeline)...');
        
        // Confirm collection and get reward information
        final rewardData = await ref
            .read(dropsControllerProvider.notifier)
            .confirmCollectionWithRewards(widget.dropId);

        // Clear transportation mode for this drop after collection
        await _clearTransportationMode();
        
        // Clear route cache for this drop after collection
        await _clearRouteCache();
        
        // Stop location broadcasting
        _stopLocationBroadcasting();

        debugPrint('✅ Collection confirmed successfully!');
        
        // IMMEDIATELY stop the timer
        debugPrint('⏰ Stopping timer immediately...');
        _timer?.cancel();
        _hasTimedOut = true; // Prevent timer from continuing
        
        // IMMEDIATELY stop the timer
        debugPrint('⏰ Stopping timer immediately...');
        _timer?.cancel();
        _hasTimedOut = true; // Prevent timer from continuing
        
        // Show collection success popup with reward information
        debugPrint('🎉 Raw reward data: $rewardData');
        if (rewardData != null && mounted) {
          // Get reward data from the backend response
          final rewardInfo = rewardData['rewardData'] ?? {};
          debugPrint('🎉 Reward info from backend: $rewardInfo');
          final currentTier = rewardInfo['currentTier']?['tier'] ?? 1;
          final tierName = rewardInfo['currentTier']?['name'] ?? 'Bronze Collector';
          final totalPoints = rewardInfo['totalPoints'] ?? 0;
          final pointsAwarded = rewardInfo['pointsAwarded'] ?? 0;
          
          debugPrint('🎉 Reward data: $pointsAwarded points awarded, tier: $tierName');
          debugPrint('🎉 Total points: $totalPoints');
          
          // Show the collection success popup as a dialog
          _showCollectionSuccessDialog(
            pointsAwarded: pointsAwarded,
            tierName: tierName,
            currentTier: currentTier,
            totalPoints: totalPoints,
          );
        }
        
        // Refresh collection attempts to update the session value card
        try {
          ref.read(collectionAttemptsProvider.notifier).refresh();
          debugPrint('✅ Collection attempts refreshed');
        } catch (e) {
          debugPrint('⚠️ Failed to refresh collection attempts: $e');
        }
        
        // CRITICAL: Clear the active collection state to stop the timer
        debugPrint('🧹 Clearing active collection state...');
        await ref.read(navigationControllerProvider.notifier).completeCollection();
        
        // Wait a moment for backend to process earnings
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Refresh user data to get updated earningsHistory (like rewardHistory)
        try {
          await ref.read(authNotifierProvider.notifier).refreshUserData();
          debugPrint('✅ User data refreshed (earningsHistory should be updated)');
        } catch (e) {
          debugPrint('⚠️ Failed to refresh user data: $e');
        }
        
        // Refresh earnings providers to update session value card
        try {
          ref.invalidate(todayEarningsProvider);
          ref.invalidate(earningsHistoryProvider({'page': 1, 'limit': 20}));
          debugPrint('✅ Earnings providers refreshed');
        } catch (e) {
          debugPrint('⚠️ Failed to refresh earnings providers: $e');
        }
        
        // Force refresh the drops list to ensure UI updates
        // Use the correct load method based on user mode to filter out collected drops
        debugPrint('🔄 Force refreshing drops list...');
        final userMode = ref.read(userModeControllerProvider);
        await userMode.whenData((mode) async {
          if (mode == UserMode.collector) {
            // For collectors, load only available drops (excludes collected ones)
            await ref.read(dropsControllerProvider.notifier).loadDropsAvailableForCollectors(
              excludeCollectorId: collectorId,
            );
            debugPrint('✅ Refreshed collector drops (excluding collected)');
          } else {
            // For household, load all user drops (they'll be filtered in the UI)
            await ref.read(dropsControllerProvider.notifier).loadDrops();
            debugPrint('✅ Refreshed household drops');
          }
        });
        
        // Dialog will handle navigation, no need to wait here
        debugPrint('✅ Collection success dialog should be showing now');
      } else {
        debugPrint('❌ No collector ID found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).errorNoCollectorIdFound),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error confirming collection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorConfirmingCollection(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCollectionSuccessDialog({
    required int pointsAwarded,
    required String tierName,
    required int currentTier,
    required int totalPoints,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // Success Title
              Text(
                AppLocalizations.of(context).dropCollected,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 12),

              // Points Awarded
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00695C), Color(0xFF004D40)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).pointsEarned(pointsAwarded),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tier Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00695C).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00695C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tierName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF00695C),
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context).currentTier,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppLocalizations.of(context).totalPoints,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          '$totalPoints',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF00695C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Dismiss Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to home screen
                    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    AppLocalizations.of(context).awesome,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          title: Text(AppLocalizations.of(context).exitNavigation),
          content: Text(AppLocalizations.of(context).exitNavigationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
              },
              child: Text(AppLocalizations.of(context).exit),
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

extension CancellationReasonLocalization on CancellationReason {
  String localizedDisplayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case CancellationReason.NoAccess:
        return l10n.noAccess;
      case CancellationReason.NotFound:
        return l10n.notFound;
      case CancellationReason.AlreadyCollected:
        return l10n.alreadyCollected;
      case CancellationReason.WrongLocation:
        return l10n.wrongLocation;
      case CancellationReason.Unsafe:
        return l10n.unsafeLocation;
      case CancellationReason.Other:
        return l10n.other;
    }
  }
} 
  