import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_client.dart' as api;

/// Native Live Activity service using MethodChannel
/// Follows the article's approach for custom platform channel implementation
class LiveActivityNativeService {
  static final LiveActivityNativeService _instance = LiveActivityNativeService._internal();
  factory LiveActivityNativeService() => _instance;
  LiveActivityNativeService._internal();

  static const MethodChannel _channel = MethodChannel('com.botleji/live_activity');
  static const EventChannel _eventChannel = EventChannel('com.botleji/live_activity_events');
  bool _isInitialized = false;
  final Map<String, String> _activityIdMap = {}; // Maps dropId -> activityId (or dropId temporarily)
  final Map<String, String> _activityIdToDropIdMap = {}; // Maps activityId -> dropId (reverse mapping)
  StreamSubscription? _eventSubscription; // For listening to push tokens

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if Live Activities are supported
      final isSupported = await _channel.invokeMethod<bool>('isActivityKitAvailable') ?? false;
      if (!isSupported) {
        debugPrint('⚠️ Live Activities not supported or not enabled on this device');
        return;
      }

      // Start listening to push tokens (for backend API)
      _startListeningToPushTokens();

      debugPrint('✅ Live Activities native service initialized successfully');
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Error initializing Live Activities native service: $e');
    }
  }

  /// Start listening to push tokens via EventChannel (for backend API)
  void _startListeningToPushTokens() {
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) async {
        try {
          final data = event as Map<dynamic, dynamic>;
          final eventType = data['eventType'] as String?;
          final tokenValue = data['value'] as String?;
          final activityId = data['activityId'] as String?;

          switch (eventType) {
            case 'pushToStartToken':
              debugPrint('📱 Received pushToStartToken: $tokenValue');
              // This token is used to START new activities
              // You can send this to your backend if needed
              break;

            case 'pushToUpdateToken':
              final dropId = data['dropId'] as String?; // Get dropId from event
              debugPrint('📱 Received pushToUpdateToken: $tokenValue for activity: $activityId, dropId: $dropId');
              // This token is used to UPDATE/END activities
              // Store mappings and send token to backend
              if (activityId != null && tokenValue != null && dropId != null) {
                // Store both forward and reverse mappings
                _activityIdMap[dropId] = activityId;
                _activityIdToDropIdMap[activityId] = dropId;
                await _sendPushTokenToBackendForActivity(activityId, tokenValue, dropId);
              } else if (activityId != null && tokenValue != null) {
                // Fallback: try to find dropId from existing mappings
                await _sendPushTokenToBackendForActivity(activityId, tokenValue);
              }
              break;
          }
        } catch (e) {
          debugPrint('❌ Error handling push token event: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ Error in push token stream: $error');
      },
    );
  }

  /// Send push token to backend for a specific activity
  Future<void> _sendPushTokenToBackendForActivity(String activityId, String pushToken, [String? dropId]) async {
    try {
      // Use provided dropId or find it from mappings
      String? foundDropId = dropId ?? _activityIdToDropIdMap[activityId];
      
      // If not found, try to find it in the forward map (backward compatibility)
      if (foundDropId == null) {
        _activityIdMap.forEach((key, value) {
          if (value == activityId) {
            foundDropId = key;
          }
        });
      }

      if (foundDropId == null) {
        debugPrint('⚠️ Could not find dropId for activityId: $activityId');
        debugPrint('⚠️ Current activityIdMap: $_activityIdMap');
        debugPrint('⚠️ Current reverseMap: $_activityIdToDropIdMap');
        return;
      }
      
      // Store the mapping for future use
      final finalDropId = foundDropId!; // We know it's not null at this point
      _activityIdToDropIdMap[activityId] = finalDropId;
      _activityIdMap[finalDropId] = activityId; // Update forward map with real activityId
      
      debugPrint('📤 Sending push token to backend: dropId=$finalDropId, activityId=$activityId');
      final dio = api.ApiClientConfig.createDio();

      await dio.post(
        '${api.ApiClientConfig.baseUrl}/dropoffs/$finalDropId/live-activity-token',
        data: {
          'activityId': activityId,
          'pushToken': pushToken,
        },
      );

      debugPrint('✅ Push token sent to backend successfully');
    } catch (e) {
      debugPrint('❌ Error sending push token to backend: $e');
    }
  }

  /// Check if Live Activities are enabled
  Future<bool> areActivitiesEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isActivityKitAvailable') ?? false;
    } catch (e) {
      debugPrint('❌ Error checking Live Activities availability: $e');
      return false;
    }
  }

  /// Start drop timeline Live Activity (household mode)
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
    try {
      debugPrint('🔄 startDropTimelineActivity called: dropId=$dropId, status=$status');

      final result = await _channel.invokeMethod<String>('startDropTimelineActivity', {
        'dropId': dropId,
        'dropAddress': dropAddress,
        'estimatedValue': estimatedValue,
        'status': status,
        'statusText': statusText,
        'collectorName': collectorName ?? '',
        'timeAgo': timeAgo,
        'createdAt': createdAt,
      });

      if (result != null) {
        _activityIdMap[dropId] = result;
        debugPrint('✅ Drop timeline activity started successfully!');
        debugPrint('Activity ID: $result');
        debugPrint('Drop ID: $dropId');
        debugPrint('Status: $status');

        // Send push token to backend
        _sendPushTokenToBackend(dropId, result);

        return result;
      } else {
        debugPrint('⚠️ Activity started but no activityId returned');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error starting drop timeline activity: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Update drop timeline Live Activity
  Future<String?> updateDropTimelineActivity({
    required String dropId,
    required String status,
    required String statusText,
    String? collectorName,
    required String timeAgo,
    double? distanceRemaining,
  }) async {
    try {
      debugPrint('🔄 updateDropTimelineActivity called: dropId=$dropId, status=$status, statusText=$statusText, distanceRemaining=$distanceRemaining');
      
      // The native side uses dropId to find the activity directly, no need to check activityIdMap
      await _channel.invokeMethod('updateDropTimelineActivity', {
        'dropId': dropId, // Native side uses dropId to find the activity
        'status': status,
        'statusText': statusText,
        'collectorName': collectorName ?? '',
        'timeAgo': timeAgo,
        'distanceRemaining': distanceRemaining,
      });

      debugPrint('✅ Drop timeline activity update called for dropId: $dropId');
      return dropId;
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating drop timeline activity: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// End drop timeline Live Activity
  Future<void> endDropTimelineActivity({String? dropId}) async {
    try {
      if (dropId != null) {
        final activityId = _activityIdMap[dropId];
        if (activityId != null) {
          await _channel.invokeMethod('endDropTimelineActivity', {
            'dropId': dropId,
          });
          _activityIdMap.remove(dropId);
          debugPrint('✅ Drop timeline activity ended: $activityId');
        } else {
          debugPrint('⚠️ ActivityId not found for dropId: $dropId');
        }
      } else {
        await _channel.invokeMethod('endDropTimelineActivity');
        _activityIdMap.clear();
        debugPrint('✅ All drop timeline activities ended');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error ending drop timeline activity: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Start collection Live Activity (collector mode)
  Future<String?> startCollectionActivity({
    required String dropId,
    required String dropAddress,
    required String transportMode,
    required String estimatedValue,
    required String elapsedTime,
    required String distance,
    required String eta,
    required int progressPercentage,
  }) async {
    try {
      debugPrint('🔄 startCollectionActivity called: dropId=$dropId');

      final result = await _channel.invokeMethod<String>('startActivity', {
        'dropId': dropId,
        'dropAddress': dropAddress,
        'elapsedTime': elapsedTime,
        'distance': distance,
        'eta': eta,
        'transportMode': transportMode,
        'estimatedValue': estimatedValue,
        'progressPercentage': progressPercentage,
      });

      if (result != null) {
        _activityIdMap[dropId] = result;
        debugPrint('✅ Collection activity started successfully!');
        return result;
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Error starting collection activity: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Update collection Live Activity
  Future<void> updateCollectionActivity({
    required String elapsedTime,
    required String distance,
    required String eta,
    required int progressPercentage,
  }) async {
    try {
      await _channel.invokeMethod('updateActivity', {
        'elapsedTime': elapsedTime,
        'distance': distance,
        'eta': eta,
        'progressPercentage': progressPercentage,
      });
      debugPrint('✅ Collection activity updated successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating collection activity: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// End collection Live Activity
  Future<void> endCollectionActivity() async {
    try {
      await _channel.invokeMethod('endActivity');
      _activityIdMap.clear();
      debugPrint('✅ Collection activity ended');
    } catch (e, stackTrace) {
      debugPrint('❌ Error ending collection activity: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Send push token to backend
  Future<void> _sendPushTokenToBackend(String dropId, String activityId) async {
    try {
      // Get push token from native side
      final pushToken = await _channel.invokeMethod<String>('getPushToken', {
        'activityId': activityId,
      });

      if (pushToken != null && pushToken.isNotEmpty) {
        debugPrint('📤 Sending Live Activity push token to backend: dropId=$dropId, activityId=$activityId');
        final dio = api.ApiClientConfig.createDio();

        await dio.post(
          '${api.ApiClientConfig.baseUrl}/dropoffs/$dropId/live-activity-token',
          data: {
            'activityId': activityId,
            'pushToken': pushToken,
          },
        );

        debugPrint('✅ Live Activity push token sent to backend successfully');
      } else {
        debugPrint('⚠️ No push token received from native side');
      }
    } catch (e) {
      debugPrint('❌ Error sending Live Activity push token to backend: $e');
    }
  }

  /// Get all activity IDs (for debugging)
  Future<List<String>> getAllActivitiesIds() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getAllActivitiesIds');
      return result?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      debugPrint('❌ Error getting all activity IDs: $e');
      return [];
    }
  }

  /// Dispose and cleanup
  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _activityIdMap.clear();
    _isInitialized = false;
  }

  /// Static helper methods
  static String formatElapsedTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String getStatusText(String statusKey) {
    switch (statusKey) {
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
        return statusKey;
    }
  }

  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }
}


