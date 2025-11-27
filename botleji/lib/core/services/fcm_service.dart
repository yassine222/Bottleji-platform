import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'local_notification_service.dart';
import '../config/server_config.dart';
import '../api/api_client.dart' as api;

/// Top-level function to handle background messages
/// Must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 FCM Background Message received: ${message.messageId}');
  debugPrint('🔔 Title: ${message.notification?.title}');
  debugPrint('🔔 Body: ${message.notification?.body}');
  debugPrint('🔔 Data: ${message.data}');
  
  // Show local notification for background messages
  final localNotificationService = LocalNotificationService();
  await localNotificationService.initialize();
  
  if (message.notification != null) {
    await localNotificationService.showNotification(
      title: message.notification!.title ?? 'Notification',
      body: message.notification!.body ?? '',
      id: message.hashCode,
      payload: message.data.toString(),
    );
  }
}

class FCMService extends ChangeNotifier {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;
  bool _initialized = false;

  String? get fcmToken => _fcmToken;
  bool get initialized => _initialized;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('🔔 FCMService: Already initialized');
      return;
    }

    try {
      debugPrint('🔔 FCMService: Initializing Firebase Cloud Messaging...');

      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔔 FCMService: Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 FCMService: User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('🔔 FCMService: User granted provisional permission');
      } else {
        debugPrint('🔔 FCMService: User denied or has not accepted permission');
        // Continue anyway - we'll try to get token but it might not work
      }

      // Get FCM token (will fail gracefully on iOS without APNs)
      await _getFCMToken();

      // Set up message handlers (only if we have a token or on Android)
      if (_fcmToken != null || Platform.isAndroid) {
        _setupMessageHandlers();

        // Set up token refresh listener
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔔 FCMService: Token refreshed: $newToken');
          _fcmToken = newToken;
          _saveTokenToBackend(newToken);
          notifyListeners();
        });
      } else {
        debugPrint('⚠️ FCMService: Skipping message handlers setup - no FCM token available');
        debugPrint('ℹ️ FCMService: Push notifications will not work until FCM is properly configured');
        debugPrint('ℹ️ FCMService: On iOS, this requires Apple Developer Program membership and APNs configuration');
        debugPrint('ℹ️ FCMService: On Android, this should work automatically');
      }

      _initialized = true;
      debugPrint('🔔 FCMService: Initialization completed (FCM may not be fully functional)');
    } catch (e) {
      debugPrint('❌ FCMService: Error initializing: $e');
      debugPrint('ℹ️ FCMService: App will continue to work, but push notifications may not be available');
      // Mark as initialized anyway so we don't keep retrying
      _initialized = true;
    }
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      // On iOS, we need to get APNS token first
      if (Platform.isIOS) {
        debugPrint('🔔 FCMService: iOS detected - getting APNS token first...');
        try {
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            debugPrint('🔔 FCMService: APNS Token: $apnsToken');
          } else {
            debugPrint('⚠️ FCMService: APNS token is null - notifications may not work on iOS');
            debugPrint('⚠️ FCMService: This is normal if running on simulator or if APNs is not configured');
            // Wait a bit and try again
            await Future.delayed(const Duration(seconds: 2));
            final retryApnsToken = await _firebaseMessaging.getAPNSToken();
            if (retryApnsToken != null) {
              debugPrint('🔔 FCMService: APNS Token (retry): $retryApnsToken');
            } else {
              debugPrint('⚠️ FCMService: APNS token still null after retry');
            }
          }
        } catch (e) {
          debugPrint('⚠️ FCMService: Error getting APNS token: $e');
          debugPrint('⚠️ FCMService: This is normal if running on simulator or if APNs is not configured');
        }
      }

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔔 FCMService: FCM Token: $_fcmToken');
      
      if (_fcmToken != null) {
        await _saveTokenToBackend(_fcmToken!);
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      } else {
        debugPrint('⚠️ FCMService: FCM token is null');
        if (Platform.isIOS) {
          debugPrint('⚠️ FCMService: On iOS, this usually means APNs is not configured or running on simulator');
        }
      }
      
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ FCMService: Error getting FCM token: $e');
      if (Platform.isIOS) {
        debugPrint('💡 FCMService: iOS tip: Make sure APNs is configured in Firebase Console');
        debugPrint('💡 FCMService: iOS tip: Physical device is required for push notifications (simulator won\'t work)');
      }
      return null;
    }
  }

  /// Save FCM token to backend
  Future<void> _saveTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      
      if (authToken == null || authToken.isEmpty) {
        debugPrint('🔔 FCMService: No auth token, skipping token save to backend');
        return;
      }

      debugPrint('🔔 FCMService: Saving FCM token to backend...');
      final dio = api.ApiClientConfig.createDio();
      
      try {
        await dio.post(
          '${api.ApiClientConfig.baseUrl}/auth/fcm-token',
          data: {'fcmToken': token},
        );
        debugPrint('🔔 FCMService: FCM token saved to backend successfully');
      } catch (e) {
        debugPrint('❌ FCMService: Error saving FCM token to backend: $e');
      }
    } catch (e) {
      debugPrint('❌ FCMService: Error in _saveTokenToBackend: $e');
    }
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 FCMService: Foreground message received');
      debugPrint('🔔 Title: ${message.notification?.title}');
      debugPrint('🔔 Body: ${message.notification?.body}');
      debugPrint('🔔 Data: ${message.data}');

      // Show local notification for foreground messages
      final localNotificationService = LocalNotificationService();
      if (message.notification != null) {
        localNotificationService.showNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          id: message.hashCode,
          payload: message.data.toString(),
        );
      }
    });

    // Handle notification taps (when app is opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 FCMService: Notification tapped - app opened from notification');
      debugPrint('🔔 Data: ${message.data}');
      
      // Handle navigation based on notification data
      _handleNotificationTap(message.data);
    });

    // Check if app was opened from a notification (when app was terminated)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 FCMService: App opened from terminated state via notification');
        debugPrint('🔔 Data: ${message.data}');
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    // Handle different notification types
    if (data['type'] == 'ticket_message') {
      final ticketId = data['ticketId'];
      debugPrint('🔔 FCMService: Navigate to ticket: $ticketId');
      // Navigation will be handled by the app's routing
    } else if (data['type'] == 'drop_status_update') {
      final dropId = data['dropId'];
      debugPrint('🔔 FCMService: Navigate to drop: $dropId');
      // Navigation will be handled by the app's routing
    }
  }

  /// Save FCM token to backend (public method to call after login)
  Future<void> saveTokenToBackend() async {
    if (_fcmToken != null) {
      await _saveTokenToBackend(_fcmToken!);
    } else {
      // Try to get token if we don't have it yet
      final token = await _getFCMToken();
      if (token != null) {
        await _saveTokenToBackend(token);
      } else {
        debugPrint('⚠️ FCMService: Cannot save token - FCM token not available');
        debugPrint('ℹ️ FCMService: This is normal on iOS without APNs configuration');
        debugPrint('ℹ️ FCMService: Push notifications will not work, but app will function normally');
      }
    }
  }

  /// Delete FCM token (on logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      debugPrint('🔔 FCMService: FCM token deleted');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ FCMService: Error deleting FCM token: $e');
    }
  }
}

