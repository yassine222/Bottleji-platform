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
    if (_isInitialized) {
      debugPrint('✅ iOS ActivityKit already initialized');
      return;
    }

    try {
      if (Platform.isIOS) {
        debugPrint('🔵 iOS: Checking ActivityKit availability...');
        // Check if ActivityKit is available
        final bool isAvailable = await _channel.invokeMethod('isActivityKitAvailable') ?? false;
        debugPrint('🔵 iOS: ActivityKit available: $isAvailable');
        
        if (isAvailable) {
          _isInitialized = true;
          debugPrint('✅ iOS ActivityKit initialized successfully');
        } else {
          debugPrint('⚠️ iOS ActivityKit not available on this device');
          debugPrint('⚠️ This might be because:');
          debugPrint('   - Device is not iPhone 14 Pro or later');
          debugPrint('   - iOS version is below 16.1');
          debugPrint('   - Live Activities are disabled in Settings');
        }
      } else {
        debugPrint('⚠️ Not iOS platform, skipping ActivityKit initialization');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing iOS ActivityKit: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  /// Check if Dynamic Island is supported
  bool isSupported() {
    if (!Platform.isIOS) {
      debugPrint('⚠️ Not iOS platform');
      return false;
    }
    if (!_isInitialized) {
      debugPrint('⚠️ iOS ActivityKit not initialized');
      return false;
    }
    debugPrint('✅ iOS ActivityKit is supported');
    return true;
  }

  /// Start Dynamic Island activity
  Future<void> startCollectionActivity(CollectionActivityData data) async {
    debugPrint('🔵 iOS: Attempting to start live activity...');
    debugPrint('🔵 iOS: isSupported() = ${isSupported()}');
    
    if (!isSupported()) {
      debugPrint('⚠️ Dynamic Island not supported, skipping start');
      return;
    }

    try {
      final elapsedTimeStr = LiveActivityService.formatElapsedTime(data.elapsedTime);
      final distanceStr = LiveActivityService.formatDistance(data.distanceToDestination);

      debugPrint('🔵 iOS: Calling native startActivity with:');
      debugPrint('   - elapsedTime: $elapsedTimeStr');
      debugPrint('   - distance: $distanceStr');
      debugPrint('   - eta: ${data.eta ?? 'N/A'}');

      final result = await _channel.invokeMethod('startActivity', {
        'dropId': data.dropId,
        'dropAddress': data.dropAddress,
        'elapsedTime': elapsedTimeStr, // "12:34"
        'distance': distanceStr, // "1.2 km"
        'eta': data.eta ?? 'N/A', // "5 min"
        'transportMode': data.transportMode,
      });

      _isActivityActive = true;
      debugPrint('✅ Dynamic Island activity started successfully');
      debugPrint('🔵 iOS: Native method result: $result');
    } catch (e, stackTrace) {
      debugPrint('❌ Error starting Dynamic Island activity: $e');
      debugPrint('❌ Stack trace: $stackTrace');
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
    if (!isSupported()) {
      debugPrint('⚠️ ActivityKit not supported, skipping end activity');
      return;
    }

    if (!_isActivityActive) {
      debugPrint('⚠️ No active activity to end');
      return;
    }

    try {
      debugPrint('🛑 Ending Dynamic Island activity...');
      await _channel.invokeMethod('endActivity');
      _isActivityActive = false;
      debugPrint('✅ Dynamic Island activity ended successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error ending Dynamic Island activity: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      // Still mark as inactive even if there was an error
      _isActivityActive = false;
    }
  }
  
  // MARK: - Drop Timeline Activity (Household Mode)
  
  /// Start drop timeline activity
  Future<void> startDropTimelineActivity({
    required String dropId,
    required String dropAddress,
    required String estimatedValue,
    required String status,
    required String statusText,
    String? collectorName,
    required String timeAgo,
    required String createdAt,
  }) async {
    if (!isSupported()) {
      return;
    }

    try {
      await _channel.invokeMethod('startDropTimelineActivity', {
        'dropId': dropId,
        'dropAddress': dropAddress,
        'estimatedValue': estimatedValue,
        'status': status,
        'statusText': statusText,
        'collectorName': collectorName,
        'timeAgo': timeAgo,
        'createdAt': createdAt,
      });
      debugPrint('✅ Drop Timeline activity started');
    } catch (e) {
      debugPrint('❌ Error starting Drop Timeline activity: $e');
    }
  }
  
  /// Update drop timeline activity
  Future<void> updateDropTimelineActivity({
    required String status,
    required String statusText,
    String? collectorName,
    required String timeAgo,
  }) async {
    if (!isSupported()) {
      return;
    }

    try {
      await _channel.invokeMethod('updateDropTimelineActivity', {
        'status': status,
        'statusText': statusText,
        'collectorName': collectorName,
        'timeAgo': timeAgo,
      });
      debugPrint('✅ Drop Timeline activity updated');
    } catch (e) {
      debugPrint('❌ Error updating Drop Timeline activity: $e');
    }
  }
  
  /// End drop timeline activity
  Future<void> endDropTimelineActivity({String? dropId}) async {
    if (!isSupported()) {
      return;
    }

    try {
      if (dropId != null) {
        await _channel.invokeMethod('endDropTimelineActivity', {'dropId': dropId});
      } else {
        await _channel.invokeMethod('endDropTimelineActivity');
      }
      debugPrint('✅ Drop Timeline activity ended');
    } catch (e) {
      debugPrint('❌ Error ending Drop Timeline activity: $e');
    }
  }
}

