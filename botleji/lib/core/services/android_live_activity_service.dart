import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'live_activity_service.dart';

/// Android persistent notification service for live activities
/// Works on Android 8.0+ (API 26+)
class AndroidLiveActivityService {
  static const int COLLECTION_NOTIFICATION_ID = 1001;
  static const String CHANNEL_ID = 'collection_live_activity';
  static const String CHANNEL_NAME = 'Active Collection';
  static const String CHANNEL_DESCRIPTION = 'Shows real-time collection progress';

  FlutterLocalNotificationsPlugin? _notifications;
  bool _isInitialized = false;
  bool _isNotificationActive = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Platform.isAndroid) {
        _notifications = FlutterLocalNotificationsPlugin();

        // Create notification channel for Android 8.0+
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          CHANNEL_ID,
          CHANNEL_NAME,
          description: CHANNEL_DESCRIPTION,
          importance: Importance.high,
          showBadge: false,
          playSound: false,
          enableVibration: false,
        );

        await _notifications!.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

        _isInitialized = true;
        debugPrint('✅ Android Live Activity service initialized');
      }
    } catch (e) {
      debugPrint('❌ Error initializing Android Live Activity service: $e');
      _isInitialized = false;
    }
  }

  /// Check if live activities are supported
  bool isSupported() {
    if (!Platform.isAndroid) return false;
    // Android 8.0+ (API 26+) supports expanded notifications
    return _isInitialized;
  }

  /// Show persistent notification for collection activity
  Future<void> showCollectionActivity(CollectionActivityData data) async {
    if (!isSupported()) {
      debugPrint('⚠️ Android Live Activity not supported, skipping show');
      return;
    }

    try {
      final elapsedTimeStr = LiveActivityService.formatElapsedTime(data.elapsedTime);
      final distanceStr = LiveActivityService.formatDistance(data.distanceToDestination);
      final etaStr = data.eta ?? 'N/A';

      // Build notification content
      final title = 'Collection in Progress';
      final body = '⏱️ $elapsedTimeStr  📍 $distanceStr  🚗 $etaStr';

      // Expanded notification with more details
      final bigTextStyle = BigTextStyleInformation(
        '⏱️ Timer: $elapsedTimeStr\n'
        '📍 Distance: $distanceStr\n'
        '🚗 ETA: $etaStr',
        contentTitle: title,
        summaryText: 'Active Collection',
      );

      final androidDetails = AndroidNotificationDetails(
        CHANNEL_ID,
        CHANNEL_NAME,
        channelDescription: CHANNEL_DESCRIPTION,
        importance: Importance.high,
        ongoing: true, // Cannot be dismissed
        autoCancel: false,
        showWhen: false,
        styleInformation: bigTextStyle,
        icon: '@mipmap/ic_launcher',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notifications!.show(
        COLLECTION_NOTIFICATION_ID,
        title,
        body,
        notificationDetails,
      );

      _isNotificationActive = true;
      debugPrint('✅ Android Live Activity notification shown');
    } catch (e) {
      debugPrint('❌ Error showing Android Live Activity: $e');
      _isNotificationActive = false;
    }
  }

  /// Update notification with new data
  Future<void> updateCollectionActivity(CollectionActivityData data) async {
    if (!isSupported() || !_isNotificationActive) {
      return;
    }

    try {
      final elapsedTimeStr = LiveActivityService.formatElapsedTime(data.elapsedTime);
      final distanceStr = LiveActivityService.formatDistance(data.distanceToDestination);
      final etaStr = data.eta ?? 'N/A';

      // Build notification content
      final title = 'Collection in Progress';
      final body = '⏱️ $elapsedTimeStr  📍 $distanceStr  🚗 $etaStr';

      // Expanded notification with more details
      final bigTextStyle = BigTextStyleInformation(
        '⏱️ Timer: $elapsedTimeStr\n'
        '📍 Distance: $distanceStr\n'
        '🚗 ETA: $etaStr',
        contentTitle: title,
        summaryText: 'Active Collection',
      );

      final androidDetails = AndroidNotificationDetails(
        CHANNEL_ID,
        CHANNEL_NAME,
        channelDescription: CHANNEL_DESCRIPTION,
        importance: Importance.high,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        styleInformation: bigTextStyle,
        icon: '@mipmap/ic_launcher',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notifications!.show(
        COLLECTION_NOTIFICATION_ID,
        title,
        body,
        notificationDetails,
      );

      debugPrint('✅ Android Live Activity notification updated');
    } catch (e) {
      debugPrint('❌ Error updating Android Live Activity: $e');
    }
  }

  /// Dismiss notification
  Future<void> dismissCollectionActivity() async {
    if (!_isNotificationActive) {
      return;
    }

    try {
      await _notifications?.cancel(COLLECTION_NOTIFICATION_ID);
      _isNotificationActive = false;
      debugPrint('✅ Android Live Activity notification dismissed');
    } catch (e) {
      debugPrint('❌ Error dismissing Android Live Activity: $e');
      _isNotificationActive = false;
    }
  }
}

