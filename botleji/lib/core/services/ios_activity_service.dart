import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'live_activity_service.dart';

/// iOS Dynamic Island service using ActivityKit
/// Note: This requires iOS 16.1+ and iPhone 14 Pro or later
class IOSActivityService {
  static const MethodChannel _channel = MethodChannel('com.botleji/live_activity');

  bool _isInitialized = false;
  bool _isActivityActive = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Platform.isIOS) {
        // Check if ActivityKit is available
        final bool isAvailable = await _channel.invokeMethod('isActivityKitAvailable') ?? false;
        if (isAvailable) {
          _isInitialized = true;
          debugPrint('✅ iOS ActivityKit initialized');
        } else {
          debugPrint('⚠️ iOS ActivityKit not available on this device');
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing iOS ActivityKit: $e');
      _isInitialized = false;
    }
  }

  /// Check if Dynamic Island is supported
  bool isSupported() {
    if (!Platform.isIOS) return false;
    // Dynamic Island is available on iPhone 14 Pro, iPhone 14 Pro Max, iPhone 15 series, iPhone 16 series
    // iOS 16.1+ required
    return _isInitialized;
  }

  /// Start Dynamic Island activity
  Future<void> startCollectionActivity(CollectionActivityData data) async {
    if (!isSupported()) {
      debugPrint('⚠️ Dynamic Island not supported, skipping start');
      return;
    }

    try {
      final elapsedTimeStr = LiveActivityService.formatElapsedTime(data.elapsedTime);
      final distanceStr = LiveActivityService.formatDistance(data.distanceToDestination);

      await _channel.invokeMethod('startActivity', {
        'dropId': data.dropId,
        'dropAddress': data.dropAddress,
        'elapsedTime': elapsedTimeStr, // "12:34"
        'distance': distanceStr, // "1.2 km"
        'eta': data.eta ?? 'N/A', // "5 min"
        'transportMode': data.transportMode,
      });

      _isActivityActive = true;
      debugPrint('✅ Dynamic Island activity started');
    } catch (e) {
      debugPrint('❌ Error starting Dynamic Island activity: $e');
      _isActivityActive = false;
    }
  }

  /// Update Dynamic Island activity
  Future<void> updateCollectionActivity(CollectionActivityData data) async {
    if (!isSupported() || !_isActivityActive) {
      return;
    }

    try {
      final elapsedTimeStr = LiveActivityService.formatElapsedTime(data.elapsedTime);
      final distanceStr = LiveActivityService.formatDistance(data.distanceToDestination);

      await _channel.invokeMethod('updateActivity', {
        'elapsedTime': elapsedTimeStr, // "12:34"
        'distance': distanceStr, // "1.2 km"
        'eta': data.eta ?? 'N/A', // "5 min"
      });

      debugPrint('✅ Dynamic Island activity updated');
    } catch (e) {
      debugPrint('❌ Error updating Dynamic Island activity: $e');
    }
  }

  /// End Dynamic Island activity
  Future<void> endCollectionActivity() async {
    if (!_isActivityActive) {
      return;
    }

    try {
      await _channel.invokeMethod('endActivity');
      _isActivityActive = false;
      debugPrint('✅ Dynamic Island activity ended');
    } catch (e) {
      debugPrint('❌ Error ending Dynamic Island activity: $e');
      _isActivityActive = false;
    }
  }
}

