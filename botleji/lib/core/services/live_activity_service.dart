import 'dart:io';
import 'ios_activity_service.dart';
import 'android_live_activity_service.dart';

/// Data model for collection activity
class CollectionActivityData {
  final String dropId;
  final String dropAddress;
  final Duration elapsedTime; // Time elapsed since collection started
  final double distanceToDestination; // in meters
  final String? eta; // "5 min" or null
  final String transportMode; // "walking", "driving", "bicycling"

  CollectionActivityData({
    required this.dropId,
    required this.dropAddress,
    required this.elapsedTime,
    required this.distanceToDestination,
    this.eta,
    required this.transportMode,
  });
}

/// Unified service for Live Activities (iOS Dynamic Island & Android Notifications)
class LiveActivityService {
  static final LiveActivityService _instance = LiveActivityService._internal();
  factory LiveActivityService() => _instance;
  LiveActivityService._internal();

  IOSActivityService? _iosService;
  AndroidLiveActivityService? _androidService;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (Platform.isIOS) {
      _iosService = IOSActivityService();
      await _iosService?.initialize();
    } else if (Platform.isAndroid) {
      _androidService = AndroidLiveActivityService();
      await _androidService?.initialize();
    }

    _isInitialized = true;
  }

  /// Check if live activities are supported on this device
  bool isSupported() {
    if (Platform.isIOS) {
      return _iosService?.isSupported() ?? false;
    } else if (Platform.isAndroid) {
      return _androidService?.isSupported() ?? true; // Android 8.0+ supports notifications
    }
    return false;
  }

  /// Start live activity for collection
  Future<void> startCollectionActivity(CollectionActivityData data) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (Platform.isIOS && _iosService != null) {
      await _iosService!.startCollectionActivity(data);
    } else if (Platform.isAndroid && _androidService != null) {
      await _androidService!.showCollectionActivity(data);
    }
  }

  /// Update live activity with new data
  Future<void> updateCollectionActivity(CollectionActivityData data) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (Platform.isIOS && _iosService != null) {
      await _iosService!.updateCollectionActivity(data);
    } else if (Platform.isAndroid && _androidService != null) {
      await _androidService!.updateCollectionActivity(data);
    }
  }

  /// End live activity
  Future<void> endCollectionActivity() async {
    if (Platform.isIOS && _iosService != null) {
      await _iosService!.endCollectionActivity();
    } else if (Platform.isAndroid && _androidService != null) {
      await _androidService!.dismissCollectionActivity();
    }
  }

  /// Format elapsed time as "MM:SS"
  static String formatElapsedTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format distance in meters to readable string
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
}

