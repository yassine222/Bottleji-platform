import 'dart:async';
import 'package:flutter/material.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/activity_update.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart' as api;

/// Service using live_activities package
/// This replaces the custom implementation with the official package
class LiveActivitiesPackageService {
  static final LiveActivitiesPackageService _instance = LiveActivitiesPackageService._internal();
  factory LiveActivitiesPackageService() => _instance;
  LiveActivitiesPackageService._internal();

  final LiveActivities _liveActivities = LiveActivities();
  bool _isInitialized = false;
  StreamSubscription<ActivityUpdate>? _activityUpdateSubscription;
  final Map<String, String> _activityIdMap = {}; // Maps dropId -> activityId
  final _uuid = const Uuid();

  /// Initialize the service with App Group ID
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if Live Activities are supported
      final isSupported = await _liveActivities.areActivitiesEnabled();
      if (!isSupported) {
        debugPrint('⚠️ Live Activities not supported or not enabled on this device');
        return;
      }

      // Initialize with App Group ID
      await _liveActivities.init(appGroupId: 'group.com.example.botleji');
      debugPrint('✅ Live Activities package initialized successfully');

      // Set up activity update stream listener for push tokens
      _setupActivityUpdateStream();

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Error initializing Live Activities package: $e');
    }
  }

  /// Set up stream listener for push tokens and status updates
  void _setupActivityUpdateStream() {
    _activityUpdateSubscription?.cancel();
    _activityUpdateSubscription = _liveActivities.activityUpdateStream.listen((update) {
      debugPrint('📱 Live Activity update received: ${update.runtimeType}');

      update.map(
        active: (activeUpdate) {
          // Push token received - send to backend
          _handlePushTokenUpdate(activeUpdate);
        },
        ended: (endedUpdate) {
          // Activity ended - cleanup (this covers both ended and dismissed)
          _handleActivityEnded(endedUpdate);
        },
        stale: (staleUpdate) {
          debugPrint('⚠️ Activity ${staleUpdate.activityId} became stale');
        },
        unknown: (unknownUpdate) {
          debugPrint('⚠️ Activity ${unknownUpdate.activityId} has unknown state');
        },
      );
    });
  }

  /// Handle push token update - send to backend
  Future<void> _handlePushTokenUpdate(ActiveActivityUpdate update) async {
    try {
      // Find dropId from activityId
      final dropId = _activityIdMap.entries
          .firstWhere((entry) => entry.value == update.activityId,
              orElse: () => MapEntry('', ''))
          .key;

      if (dropId.isEmpty) {
        debugPrint('⚠️ Could not find dropId for activityId: ${update.activityId}');
        return;
      }

      debugPrint('📤 Sending Live Activity push token to backend: dropId=$dropId, activityId=${update.activityId}');
      final dio = api.ApiClientConfig.createDio();

      await dio.post(
        '${api.ApiClientConfig.baseUrl}/dropoffs/$dropId/live-activity-token',
        data: {
          'activityId': update.activityId,
          'pushToken': update.activityToken,
        },
      );

      debugPrint('✅ Live Activity push token sent to backend successfully');
    } catch (e) {
      debugPrint('❌ Error sending Live Activity push token to backend: $e');
    }
  }

  /// Handle activity ended/dismissed
  void _handleActivityEnded(ActivityUpdate update) {
    debugPrint('📱 Activity ended/dismissed: ${update.activityId}');
    _activityIdMap.removeWhere((key, value) => value == update.activityId);
  }

  /// Check if Live Activities are supported
  Future<bool> areActivitiesEnabled() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _liveActivities.areActivitiesEnabled();
  }

  /// Start collection activity (collector mode)
  Future<String?> startCollectionActivity({
    required String dropId,
    required String dropAddress,
    required String elapsedTime, // "12:34" format
    required String distance, // "2.5 km"
    required String eta, // "5 min"
    required String transportMode, // "walking", "driving", "bicycling"
    required String estimatedValue, // "2.50 TND"
    required int progressPercentage, // 0-100
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Check if already have an activity for this drop
      if (_activityIdMap.containsKey(dropId)) {
        // Update existing activity instead
        return await updateCollectionActivity(
          dropId: dropId,
          elapsedTime: elapsedTime,
          distance: distance,
          eta: eta,
          progressPercentage: progressPercentage,
        );
      }

      // Generate activity ID
      final activityId = _uuid.v4();

      // Combine all data into a single map (both static attributes and dynamic content)
      final data = {
        // Static attributes
        'dropId': dropId,
        'dropAddress': dropAddress,
        'estimatedValue': estimatedValue,
        'transportMode': transportMode,
        // Dynamic content state
        'activityType': 'collection',
        'elapsedTime': elapsedTime,
        'distance': distance,
        'eta': eta,
        'progressPercentage': progressPercentage,
      };

      final createdActivityId = await _liveActivities.createActivity(
        activityId,
        data,
        removeWhenAppIsKilled: false,
      );

      if (createdActivityId != null) {
        _activityIdMap[dropId] = createdActivityId;
        debugPrint('✅ Collection activity started: $createdActivityId');
        return createdActivityId;
      } else {
        debugPrint('⚠️ Activity creation returned null');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error starting collection activity: $e');
      return null;
    }
  }

  /// Update collection activity
  Future<String?> updateCollectionActivity({
    required String dropId,
    required String elapsedTime,
    required String distance,
    required String eta,
    required int progressPercentage,
  }) async {
    final activityId = _activityIdMap[dropId];
    if (activityId == null) {
      debugPrint('⚠️ No activity found for dropId: $dropId');
      return null;
    }

    try {
      // Update only the dynamic content state
      final data = {
        'activityType': 'collection',
        'elapsedTime': elapsedTime,
        'distance': distance,
        'eta': eta,
        'progressPercentage': progressPercentage,
      };

      await _liveActivities.updateActivity(activityId, data);

      debugPrint('✅ Collection activity updated: $activityId');
      return activityId;
    } catch (e) {
      debugPrint('❌ Error updating collection activity: $e');
      return null;
    }
  }

  /// End collection activity
  Future<void> endCollectionActivity({String? dropId}) async {
    String? activityId;

    if (dropId != null) {
      activityId = _activityIdMap[dropId];
      if (activityId == null) {
        debugPrint('⚠️ No activity found for dropId: $dropId');
        return;
      }
    } else {
      // End the first activity if dropId not provided
      if (_activityIdMap.isEmpty) {
        debugPrint('⚠️ No activities to end');
        return;
      }
      activityId = _activityIdMap.values.first;
    }

    try {
      await _liveActivities.endActivity(activityId);
      if (dropId != null) {
        _activityIdMap.remove(dropId);
      } else {
        _activityIdMap.removeWhere((key, value) => value == activityId);
      }
      debugPrint('✅ Collection activity ended: $activityId');
    } catch (e) {
      debugPrint('❌ Error ending collection activity: $e');
    }
  }

  /// Start drop timeline activity (household mode)
  Future<String?> startDropTimelineActivity({
    required String dropId,
    required String dropAddress,
    required String estimatedValue,
    required String status,
    required String statusText,
    String? collectorName,
    required String timeAgo,
    required String createdAt,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Check if already have an activity for this drop
      if (_activityIdMap.containsKey(dropId)) {
        // Update existing activity instead
        return await updateDropTimelineActivity(
          dropId: dropId,
          status: status,
          statusText: statusText,
          collectorName: collectorName,
          timeAgo: timeAgo,
        );
      }

      // Generate activity ID
      final activityId = _uuid.v4();

      // Combine all data into a single map
      final data = {
        // Static attributes
        'dropId': dropId,
        'dropAddress': dropAddress,
        'estimatedValue': estimatedValue,
        'createdAt': createdAt,
        // Dynamic content state
        'activityType': 'dropTimeline',
        'status': status,
        'statusText': statusText,
        'collectorName': collectorName ?? '',
        'timeAgo': timeAgo,
      };

      final createdActivityId = await _liveActivities.createActivity(
        activityId,
        data,
        removeWhenAppIsKilled: false,
      );

      if (createdActivityId != null) {
        _activityIdMap[dropId] = createdActivityId;
        debugPrint('✅ Drop timeline activity started: $createdActivityId');
        return createdActivityId;
      } else {
        debugPrint('⚠️ Activity creation returned null');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error starting drop timeline activity: $e');
      return null;
    }
  }

  /// Update drop timeline activity
  Future<String?> updateDropTimelineActivity({
    required String dropId,
    required String status,
    required String statusText,
    String? collectorName,
    required String timeAgo,
  }) async {
    final activityId = _activityIdMap[dropId];
    if (activityId == null) {
      debugPrint('⚠️ No activity found for dropId: $dropId');
      return null;
    }

    try {
      // Update only the dynamic content state
      final data = {
        'activityType': 'dropTimeline',
        'status': status,
        'statusText': statusText,
        'collectorName': collectorName ?? '',
        'timeAgo': timeAgo,
      };

      await _liveActivities.updateActivity(activityId, data);

      debugPrint('✅ Drop timeline activity updated: $activityId');
      return activityId;
    } catch (e) {
      debugPrint('❌ Error updating drop timeline activity: $e');
      return null;
    }
  }

  /// End drop timeline activity
  Future<void> endDropTimelineActivity({String? dropId}) async {
    await endCollectionActivity(dropId: dropId); // Same logic
  }

  /// Get all active activity IDs
  Future<List<String>> getAllActivitiesIds() async {
    try {
      return await _liveActivities.getAllActivitiesIds();
    } catch (e) {
      debugPrint('❌ Error getting all activities: $e');
      return [];
    }
  }

  /// End all activities
  Future<void> endAllActivities() async {
    try {
      await _liveActivities.endAllActivities();
      _activityIdMap.clear();
      debugPrint('✅ All activities ended');
    } catch (e) {
      debugPrint('❌ Error ending all activities: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _activityUpdateSubscription?.cancel();
    _activityUpdateSubscription = null;
  }

  // Helper methods for formatting (same as old service)

  /// Format elapsed time as "MM:SS"
  static String formatElapsedTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format time ago string
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }

  /// Get status text from DropStatus
  static String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Created';
      case 'accepted':
        return 'Accepted';
      case 'on_way':
        return 'On his way';
      case 'collected':
        return 'Collected';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

