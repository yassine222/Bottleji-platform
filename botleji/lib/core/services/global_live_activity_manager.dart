import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/core/services/live_activity_service.dart';

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
          // Collection ended
          _stopLiveActivity();
        } else if (previous == null || previous.dropId != next.dropId) {
          // New collection started
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

      // Calculate elapsed time
      final elapsedTime = DateTime.now().difference(collection.acceptedAt);
      
      // Calculate countdown ETA
      final eta = _calculateCountdownETA(collection);

      final data = CollectionActivityData(
        dropId: collection.dropId,
        dropAddress: _currentDropAddress ?? 'Drop ${collection.dropId.substring(0, 8)}...',
        elapsedTime: elapsedTime,
        distanceToDestination: _currentDistance,
        eta: eta,
        transportMode: 'driving', // Default, can be updated if stored
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
      await _updateDistance();

      // Calculate elapsed time
      final elapsedTime = DateTime.now().difference(collection.acceptedAt);
      
      // Calculate countdown ETA
      final eta = _calculateCountdownETA(collection);

      final data = CollectionActivityData(
        dropId: collection.dropId,
        dropAddress: _currentDropAddress ?? 'Drop ${collection.dropId.substring(0, 8)}...',
        elapsedTime: elapsedTime,
        distanceToDestination: _currentDistance,
        eta: eta,
        transportMode: 'driving',
      );

      await _liveActivityService.updateCollectionActivity(data);
    } catch (e) {
      debugPrint('❌ Error updating global Live Activity: $e');
    }
  }

  /// Start periodic update timer
  void _startUpdateTimer(ActiveCollection collection) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final currentCollection = _ref?.read(navigationControllerProvider);
      if (currentCollection == null || currentCollection.dropId != collection.dropId) {
        timer.cancel();
        return;
      }
      await _updateLiveActivity(currentCollection);
    });
  }

  /// Stop Live Activity
  Future<void> _stopLiveActivity() async {
    _updateTimer?.cancel();
    _updateTimer = null;
    _currentDropId = null;
    _currentDropAddress = null;
    _currentRouteDuration = null;
    _currentDistance = 0.0;
    _currentDestination = null;
    
    await _liveActivityService.endCollectionActivity();
    debugPrint('✅ Global Live Activity stopped');
  }

  /// Update distance to destination
  Future<void> _updateDistance() async {
    if (_currentDestination == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final currentLocation = LatLng(position.latitude, position.longitude);
      
      _currentDistance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        _currentDestination!.latitude,
        _currentDestination!.longitude,
      );
    } catch (e) {
      debugPrint('⚠️ Error updating distance: $e');
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

  /// Calculate countdown ETA
  String _calculateCountdownETA(ActiveCollection collection) {
    if (_currentRouteDuration == null || _currentRouteDuration!.isEmpty || _currentRouteDuration == 'N/A') {
      return 'N/A';
    }

    try {
      // Parse route duration to get total minutes
      int totalMinutes = 0;
      final durationParts = _currentRouteDuration!.split(' ');
      if (durationParts.length >= 2) {
        if (durationParts[1].contains('hour')) {
          totalMinutes = int.parse(durationParts[0]) * 60;
          if (durationParts.length >= 4) {
            totalMinutes += int.parse(durationParts[2]);
          }
        } else {
          totalMinutes = int.parse(durationParts[0]);
        }
      }

      // Calculate elapsed time
      final elapsedTime = DateTime.now().difference(collection.acceptedAt);
      final elapsedMinutes = elapsedTime.inMinutes;

      // Calculate remaining time
      final remainingMinutes = totalMinutes - elapsedMinutes;
      
      if (remainingMinutes <= 0) {
        return 'Arriving';
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
      debugPrint('⚠️ Error calculating countdown ETA: $e');
      return _currentRouteDuration ?? 'N/A';
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

