import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/core/services/live_activity_service.dart';
import 'package:botleji/features/drops/domain/utils/drop_value_calculator.dart';

/// Global manager for Live Activity that monitors active collection state
/// This ensures Live Activity is always shown when there's an active collection,
/// regardless of which screen the user is on
class GlobalLiveActivityManager {
  static final GlobalLiveActivityManager _instance = GlobalLiveActivityManager._internal();
  factory GlobalLiveActivityManager() => _instance;
  GlobalLiveActivityManager._internal();

  final LiveActivityService _liveActivityService = LiveActivityService();
  Timer? _updateTimer;
  Ref? _ref;
  bool _isInitialized = false;
  String? _currentDropId;
  String? _currentDropAddress;
  String? _currentRouteDuration;
  double _currentDistance = 0.0;
  double _initialDistance = 0.0; // Store initial distance for progress calculation
  LatLng? _currentDestination;

  /// Initialize the manager with a Riverpod ref
  Future<void> initialize(Ref ref) async {
    if (_isInitialized) return;
    
    _ref = ref;
    await _liveActivityService.initialize();
    
    // Start monitoring active collection state
    _startMonitoring();
    
    _isInitialized = true;
    debugPrint('✅ GlobalLiveActivityManager initialized');
  }

  /// Start monitoring active collection state
  void _startMonitoring() {
    if (_ref == null) return;

    // Listen to active collection changes
    _ref!.listen(
      navigationControllerProvider,
      (previous, next) {
        if (next == null) {
          // Collection ended (collected, expired, or cancelled)
          debugPrint('🛑 Collection ended - stopping Live Activity');
          _stopLiveActivity();
        } else if (previous == null || previous.dropId != next.dropId) {
          // New collection started
          debugPrint('▶️ New collection started - starting Live Activity');
          _startLiveActivity(next);
        } else {
          // Collection updated (route info, etc.)
          _currentRouteDuration = next.routeDuration;
          _updateLiveActivity(next);
        }
      },
    );

    // Also check if there's already an active collection
    final currentCollection = _ref!.read(navigationControllerProvider);
    if (currentCollection != null) {
      _startLiveActivity(currentCollection);
    }
  }

  /// Start Live Activity for active collection
  Future<void> _startLiveActivity(ActiveCollection collection) async {
    if (!_liveActivityService.isSupported()) {
      debugPrint('⚠️ Live Activity not supported on this device');
      return;
    }

    try {
      _currentDropId = collection.dropId;
      _currentDestination = collection.destination;
      _currentRouteDuration = collection.routeDuration;
      
      // Get address for the drop
      _currentDropAddress = await _getAddressFromCoordinates(collection.destination);
      
      // Calculate initial distance
      await _updateDistance();
      
      // Store initial distance for progress calculation
      _initialDistance = _currentDistance;
      
      // Try to get route distance from collection, otherwise use initial distance
      if (collection.routeDistance != null && collection.routeDistance!.isNotEmpty) {
        final routeDistanceMeters = _parseRouteDistance(collection.routeDistance!);
        if (routeDistanceMeters > 0) {
          _initialDistance = routeDistanceMeters;
          debugPrint('📍 Using route distance: ${_initialDistance.toStringAsFixed(2)}m');
        }
      }
      
      debugPrint('📍 Initial distance for progress: ${_initialDistance.toStringAsFixed(2)}m');

      // Calculate elapsed time
      final elapsedTime = DateTime.now().difference(collection.acceptedAt);
      
      // Calculate countdown ETA (for display)
      final eta = _calculateCountdownETA(collection);
      
      // Calculate remaining time until expiration (for countdown timer)
      final remainingTime = _calculateRemainingTime(collection);
      
      // Calculate estimated value
      final estimatedValue = _calculateEstimatedValue(collection);
      
      // Calculate progress percentage (based on distance traveled)
      final progressPercentage = _calculateProgressPercentage();

      final data = CollectionActivityData(
        dropId: collection.dropId,
        dropAddress: _currentDropAddress ?? 'Drop ${collection.dropId.substring(0, 8)}...',
        elapsedTime: remainingTime, // Use remaining time for countdown timer
        distanceToDestination: _currentDistance,
        eta: eta,
        transportMode: 'driving', // Default, can be updated if stored
        estimatedValue: estimatedValue,
        progressPercentage: progressPercentage,
      );

      await _liveActivityService.startCollectionActivity(data);
      debugPrint('✅ Global Live Activity started for drop: ${collection.dropId}');

      // Start periodic updates
      _startUpdateTimer(collection);
    } catch (e) {
      debugPrint('❌ Error starting global Live Activity: $e');
    }
  }

  /// Update Live Activity with current data
  Future<void> _updateLiveActivity(ActiveCollection collection) async {
    if (!_liveActivityService.isSupported() || _currentDropId == null) {
      return;
    }

    try {
      // Update distance
      final previousDistance = _currentDistance;
      await _updateDistance();
      
      debugPrint('📍 Live Activity Update:');
      debugPrint('   Previous distance: ${previousDistance.toStringAsFixed(2)}m');
      debugPrint('   New distance: ${_currentDistance.toStringAsFixed(2)}m');
      debugPrint('   Distance change: ${(_currentDistance - previousDistance).toStringAsFixed(2)}m');

      // Calculate elapsed time
      final elapsedTime = DateTime.now().difference(collection.acceptedAt);
      
      // Calculate countdown ETA (for display)
      final eta = _calculateCountdownETA(collection);
      
      // Calculate remaining time until expiration (for countdown timer)
      final remainingTime = _calculateRemainingTime(collection);
      
      // Calculate estimated value
      final estimatedValue = _calculateEstimatedValue(collection);
      
      // Calculate progress percentage (based on distance traveled)
      final progressPercentage = _calculateProgressPercentage();
      
      debugPrint('   Elapsed time: ${elapsedTime.inMinutes}m ${elapsedTime.inSeconds % 60}s');
      debugPrint('   Remaining time: ${remainingTime.inMinutes}m ${remainingTime.inSeconds % 60}s');
      debugPrint('   Countdown ETA: $eta');
      debugPrint('   Estimated value: $estimatedValue');
      debugPrint('   Progress: $progressPercentage%');

      final data = CollectionActivityData(
        dropId: collection.dropId,
        dropAddress: _currentDropAddress ?? 'Drop ${collection.dropId.substring(0, 8)}...',
        elapsedTime: remainingTime, // Use remaining time for countdown timer
        distanceToDestination: _currentDistance,
        eta: eta,
        transportMode: 'driving',
        estimatedValue: estimatedValue,
        progressPercentage: progressPercentage,
      );

      await _liveActivityService.updateCollectionActivity(data);
      debugPrint('✅ Live Activity updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating global Live Activity: $e');
    }
  }

  /// Start periodic update timer
  void _startUpdateTimer(ActiveCollection collection) {
    _updateTimer?.cancel();
    debugPrint('⏰ Starting Live Activity update timer (every 5 seconds)');
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      debugPrint('⏰ Timer tick - updating Live Activity...');
      final currentCollection = _ref?.read(navigationControllerProvider);
      if (currentCollection == null || currentCollection.dropId != collection.dropId) {
        debugPrint('🛑 Collection ended or changed - stopping update timer');
        timer.cancel();
        // Explicitly stop Live Activity if collection is null
        if (currentCollection == null) {
          await _stopLiveActivity();
        }
        return;
      }
      await _updateLiveActivity(currentCollection);
    });
  }

  /// Stop Live Activity
  Future<void> _stopLiveActivity() async {
    if (_currentDropId == null) {
      // Already stopped or never started
      debugPrint('⚠️ Live Activity already stopped or never started');
      return;
    }
    
    debugPrint('🛑 Stopping Live Activity for drop: $_currentDropId');
    
    // Cancel update timer first
    _updateTimer?.cancel();
    _updateTimer = null;
    
    // Clear state
    final dropId = _currentDropId;
    _currentDropId = null;
    _currentDropAddress = null;
    _currentRouteDuration = null;
    _currentDistance = 0.0;
    _initialDistance = 0.0;
    _currentDestination = null;
    
    // End the Live Activity
    try {
      await _liveActivityService.endCollectionActivity();
      debugPrint('✅ Live Activity stopped successfully for drop: $dropId');
    } catch (e) {
      debugPrint('❌ Error stopping Live Activity: $e');
    }
  }
  
  /// Public method to stop Live Activity (can be called explicitly if needed)
  Future<void> stopLiveActivity() async {
    await _stopLiveActivity();
  }

  /// Update distance to destination
  Future<void> _updateDistance() async {
    if (_currentDestination == null) {
      debugPrint('⚠️ Cannot update distance: destination is null');
      return;
    }

    try {
      debugPrint('🗺️ Getting current position for distance calculation...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final currentLocation = LatLng(position.latitude, position.longitude);
      
      debugPrint('   Current location: ${currentLocation.latitude.toStringAsFixed(6)}, ${currentLocation.longitude.toStringAsFixed(6)}');
      debugPrint('   Destination: ${_currentDestination!.latitude.toStringAsFixed(6)}, ${_currentDestination!.longitude.toStringAsFixed(6)}');
      
      _currentDistance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        _currentDestination!.latitude,
        _currentDestination!.longitude,
      );
      
      debugPrint('   Calculated distance: ${_currentDistance.toStringAsFixed(2)}m (${(_currentDistance / 1000).toStringAsFixed(2)}km)');
    } catch (e) {
      debugPrint('⚠️ Error updating distance: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
  }

  /// Get address from coordinates using Google Maps Geocoding API
  Future<String?> _getAddressFromCoordinates(LatLng position) async {
    try {
      const apiKey = "AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E";
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final formattedAddress = result['formatted_address'];
          return formattedAddress;
        } else {
          return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        }
      } else {
        return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }
    } catch (e) {
      debugPrint('⚠️ Error getting address: $e');
      return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    }
  }

  /// Calculate remaining time until expiration as Duration
  /// This is used for the countdown timer display (MM:SS format)
  Duration _calculateRemainingTime(ActiveCollection collection) {
    try {
      // Parse route duration from the active collection's route info
      int routeDurationMinutes = 15; // Default fallback - 15 minutes
      
      if (collection.routeDuration != null && collection.routeDuration!.isNotEmpty && collection.routeDuration != 'N/A') {
        final durationText = collection.routeDuration!;
        
        // Parse duration like "15 mins" or "1 hour 30 mins"
        final durationParts = durationText.split(' ');
        if (durationParts.length >= 2) {
          try {
            if (durationParts[1].contains('hour')) {
              // Format: "1 hour 30 mins" or "1 hour"
              routeDurationMinutes = int.parse(durationParts[0]) * 60;
              if (durationParts.length >= 4 && durationParts[3].contains('mins')) {
                routeDurationMinutes += int.parse(durationParts[2]);
              }
            } else {
              // Parse minutes from duration text like "15 mins"
              routeDurationMinutes = int.parse(durationParts[0]);
            }
          } catch (e) {
            debugPrint('⚠️ Error parsing route duration: $e, using default 15 minutes');
            routeDurationMinutes = 15;
          }
        }
      } else {
        // When routeDuration is null, use a conservative default
        final elapsed = DateTime.now().difference(collection.acceptedAt);
        final elapsedMinutes = elapsed.inMinutes;
        
        if (elapsedMinutes > 10) {
          routeDurationMinutes = 10;
        } else {
          routeDurationMinutes = 15;
        }
      }
      
      // Fixed buffer based on route duration (same as navigation screen)
      int bufferMinutes;
      if (routeDurationMinutes <= 5) {
        bufferMinutes = 10; // Short routes: +10 minutes
      } else if (routeDurationMinutes <= 15) {
        bufferMinutes = 15; // Medium routes: +15 minutes
      } else {
        bufferMinutes = 20; // Long routes: +20 minutes
      }
      
      // Calculate total timeout based on route duration + buffer
      var totalTimeoutMinutes = routeDurationMinutes + bufferMinutes;
      
      // Calculate how much time has already passed since collection was accepted
      final timeElapsed = DateTime.now().difference(collection.acceptedAt);
      final elapsedSeconds = timeElapsed.inSeconds;
      
      // If routeDuration was null, ensure we don't extend the timeout too much
      if (collection.routeDuration == null || collection.routeDuration!.isEmpty || collection.routeDuration == 'N/A') {
        final maxReasonableTimeout = (elapsedSeconds / 60).round() + 20;
        if (totalTimeoutMinutes > maxReasonableTimeout) {
          totalTimeoutMinutes = maxReasonableTimeout;
        }
      }
      
      // Calculate remaining time in seconds
      final totalTimeoutSeconds = totalTimeoutMinutes * 60;
      final remainingSeconds = totalTimeoutSeconds - elapsedSeconds;
      
      // Return Duration, clamped to non-negative
      if (remainingSeconds <= 0) {
        return Duration.zero;
      }
      return Duration(seconds: remainingSeconds);
    } catch (e) {
      debugPrint('⚠️ Error calculating remaining time: $e');
      return Duration.zero;
    }
  }

  /// Calculate collection completion countdown timer
  /// This shows the time remaining to complete the collection before it expires
  String _calculateCountdownETA(ActiveCollection collection) {
    try {
      // Parse route duration from the active collection's route info
      int routeDurationMinutes = 15; // Default fallback - 15 minutes
      
      if (collection.routeDuration != null && collection.routeDuration!.isNotEmpty && collection.routeDuration != 'N/A') {
        final durationText = collection.routeDuration!;
        
        // Parse duration like "15 mins" or "1 hour 30 mins"
        final durationParts = durationText.split(' ');
        if (durationParts.length >= 2) {
          try {
            if (durationParts[1].contains('hour')) {
              // Format: "1 hour 30 mins" or "1 hour"
              routeDurationMinutes = int.parse(durationParts[0]) * 60;
              if (durationParts.length >= 4 && durationParts[3].contains('mins')) {
                routeDurationMinutes += int.parse(durationParts[2]);
              }
            } else {
              // Parse minutes from duration text like "15 mins"
              routeDurationMinutes = int.parse(durationParts[0]);
            }
          } catch (e) {
            debugPrint('⚠️ Error parsing route duration: $e, using default 15 minutes');
            routeDurationMinutes = 15;
          }
        }
      } else {
        // When routeDuration is null, use a conservative default
        final elapsed = DateTime.now().difference(collection.acceptedAt);
        final elapsedMinutes = elapsed.inMinutes;
        
        if (elapsedMinutes > 10) {
          routeDurationMinutes = 10;
        } else {
          routeDurationMinutes = 15;
        }
      }
      
      // Fixed buffer based on route duration (same as navigation screen)
      int bufferMinutes;
      if (routeDurationMinutes <= 5) {
        bufferMinutes = 10; // Short routes: +10 minutes
      } else if (routeDurationMinutes <= 15) {
        bufferMinutes = 15; // Medium routes: +15 minutes
      } else {
        bufferMinutes = 20; // Long routes: +20 minutes
      }
      
      // Calculate total timeout based on route duration + buffer
      var totalTimeoutMinutes = routeDurationMinutes + bufferMinutes;
      
      // Calculate how much time has already passed since collection was accepted
      final timeElapsed = DateTime.now().difference(collection.acceptedAt);
      final elapsedMinutes = timeElapsed.inMinutes;
      
      // If routeDuration was null, ensure we don't extend the timeout too much
      if (collection.routeDuration == null || collection.routeDuration!.isEmpty || collection.routeDuration == 'N/A') {
        final maxReasonableTimeout = elapsedMinutes + 20;
        if (totalTimeoutMinutes > maxReasonableTimeout) {
          totalTimeoutMinutes = maxReasonableTimeout;
        }
      }
      
      // Calculate remaining time
      final remainingMinutes = totalTimeoutMinutes - elapsedMinutes;
      
      if (remainingMinutes <= 0) {
        return 'Expired';
      } else if (remainingMinutes < 60) {
        return '$remainingMinutes min';
      } else {
        final hours = remainingMinutes ~/ 60;
        final minutes = remainingMinutes % 60;
        if (minutes == 0) {
          return '$hours hour${hours > 1 ? 's' : ''}';
        } else {
          return '$hours h $minutes min';
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error calculating collection countdown: $e');
      return 'N/A';
    }
  }

  /// Calculate estimated value from collection data
  String _calculateEstimatedValue(ActiveCollection collection) {
    try {
      final value = DropValueCalculator.calculateEstimatedValue(
        plasticBottleCount: collection.numberOfBottles,
        cansCount: collection.numberOfCans,
      );
      return DropValueCalculator.formatEstimatedValue(value);
    } catch (e) {
      debugPrint('⚠️ Error calculating estimated value: $e');
      return '0.00 TND';
    }
  }

  /// Parse route distance string to meters
  /// Handles formats like "2.5 km", "1500 m", "1.2 mi", etc.
  double _parseRouteDistance(String routeDistance) {
    try {
      final distanceText = routeDistance.trim().toLowerCase();
      
      // Remove commas and extra spaces
      final cleaned = distanceText.replaceAll(',', '').replaceAll(RegExp(r'\s+'), ' ');
      
      if (cleaned.contains('km')) {
        // Format: "2.5 km" or "2 km"
        final parts = cleaned.split('km');
        final value = double.tryParse(parts[0].trim()) ?? 0.0;
        return value * 1000; // Convert km to meters
      } else if (cleaned.contains('m') && !cleaned.contains('km')) {
        // Format: "1500 m" or "1500m"
        final parts = cleaned.split('m');
        return double.tryParse(parts[0].trim()) ?? 0.0;
      } else if (cleaned.contains('mi')) {
        // Format: "1.2 mi" or "1 mi"
        final parts = cleaned.split('mi');
        final value = double.tryParse(parts[0].trim()) ?? 0.0;
        return value * 1609.34; // Convert miles to meters
      } else {
        // Try to parse as plain number (assume meters)
        return double.tryParse(cleaned) ?? 0.0;
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing route distance "$routeDistance": $e');
      return 0.0;
    }
  }

  /// Calculate progress percentage based on distance traveled
  /// Progress = ((Initial Distance - Current Distance) / Initial Distance) × 100
  int _calculateProgressPercentage() {
    try {
      // If initial distance is 0 or invalid, return 0
      if (_initialDistance <= 0) {
        debugPrint('⚠️ Initial distance is 0 or invalid, cannot calculate progress');
        return 0;
      }
      
      // If current distance is greater than initial (moved away), return 0
      if (_currentDistance >= _initialDistance) {
        return 0;
      }
      
      // Calculate distance traveled
      final distanceTraveled = _initialDistance - _currentDistance;
      
      // Calculate percentage: (distance traveled / initial distance) × 100
      final percentage = ((distanceTraveled / _initialDistance) * 100).round().clamp(0, 100);
      
      debugPrint('📍 Progress calculation:');
      debugPrint('   Initial distance: ${_initialDistance.toStringAsFixed(2)}m');
      debugPrint('   Current distance: ${_currentDistance.toStringAsFixed(2)}m');
      debugPrint('   Distance traveled: ${distanceTraveled.toStringAsFixed(2)}m');
      debugPrint('   Progress: $percentage%');
      
      return percentage;
    } catch (e) {
      debugPrint('⚠️ Error calculating progress percentage: $e');
      return 0;
    }
  }

  /// Dispose resources
  void dispose() {
    _updateTimer?.cancel();
    _isInitialized = false;
  }
}

// Provider for global Live Activity manager
final globalLiveActivityManagerProvider = Provider<GlobalLiveActivityManager>((ref) {
  final manager = GlobalLiveActivityManager();
  // Initialize when provider is created
  manager.initialize(ref);
  ref.onDispose(() => manager.dispose());
  return manager;
});

