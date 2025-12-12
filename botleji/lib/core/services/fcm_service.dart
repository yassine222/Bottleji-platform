import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart' as api;
import 'local_notification_service.dart';
import 'notification_service.dart';

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
  String? _pendingToken; // Store token that needs to be saved when user logs in

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
          
          // Save token to backend (will save if logged in, or queue for later if not)
          _saveTokenToBackend(newToken);
          
          // Also save locally for later use (async, don't await to avoid blocking)
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('fcm_token', newToken);
          });
          
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
        debugPrint('🔔 FCMService: Checking APNS configuration...');
        
        // Try multiple times with increasing delays (iOS can be slow to generate token)
        String? apnsToken;
        for (int attempt = 1; attempt <= 5; attempt++) {
          try {
            debugPrint('🔔 FCMService: APNS token attempt $attempt/5...');
            apnsToken = await _firebaseMessaging.getAPNSToken();
            if (apnsToken != null) {
              debugPrint('✅ FCMService: APNS Token received: $apnsToken');
              break;
            } else {
              if (attempt < 5) {
                debugPrint('⚠️ FCMService: APNS token null, waiting ${attempt * 2} seconds before retry...');
                await Future.delayed(Duration(seconds: attempt * 2));
              }
            }
          } catch (e) {
            debugPrint('⚠️ FCMService: Error getting APNS token (attempt $attempt): $e');
            if (attempt < 5) {
              await Future.delayed(Duration(seconds: attempt * 2));
            }
          }
        }
        
        if (apnsToken == null) {
          debugPrint('❌ FCMService: APNS token is still null after 5 attempts');
          debugPrint('🔍 FCMService: Diagnostic checklist:');
          debugPrint('   1. Is app running on PHYSICAL device? (Simulator won\'t work)');
          debugPrint('   2. Is Push Notifications enabled in App ID? (Apple Developer Portal)');
          debugPrint('   3. Does provisioning profile include Push Notifications?');
          debugPrint('   4. Is APNs key uploaded to Firebase Console?');
          debugPrint('   5. Did you rebuild app after adding Push Notifications capability?');
          debugPrint('   6. Check Xcode → Signing & Capabilities for any errors');
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
        debugPrint('🔔 FCMService: No auth token, token will be saved when user logs in');
        debugPrint('🔔 FCMService: Storing token locally for later save: $token');
        // Store token locally - will be saved when user logs in
        _pendingToken = token;
        await prefs.setString('fcm_token', token);
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
        // Clear pending token since it's now saved
        _pendingToken = null;
      } catch (e) {
        debugPrint('❌ FCMService: Error saving FCM token to backend: $e');
        // Keep as pending token to retry later
        _pendingToken = token;
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

      // Convert FCM message to NotificationPayload and route to NotificationService
      _handleFCMNotification(message);
    });

    // Handle notification taps (when app is opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 FCMService: Notification tapped - app opened from notification');
      debugPrint('🔔 Data: ${message.data}');
      
      // Convert and handle the notification
      _handleFCMNotification(message);
    });

    // Check if app was opened from a notification (when app was terminated)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 FCMService: App opened from terminated state via notification');
        debugPrint('🔔 Data: ${message.data}');
        _handleFCMNotification(message);
      }
    });
  }

  /// Handle FCM notification by converting it to NotificationPayload and routing to NotificationService
  void _handleFCMNotification(RemoteMessage message) {
    try {
      // Extract notification type and data from FCM message
      final type = message.data['type'] ?? '';
      final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
      final body = message.notification?.body ?? message.data['message'] ?? '';
      
      // Extract timestamp from data or use current time
      DateTime timestamp;
      if (message.data['timestamp'] != null) {
        try {
          timestamp = DateTime.parse(message.data['timestamp']);
        } catch (e) {
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }

      // Extract data payload (excluding type, title, message, timestamp)
      final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
      data.remove('type');
      data.remove('title');
      data.remove('message');
      data.remove('timestamp');

      debugPrint('🔔 FCMService: Converting FCM message to NotificationPayload');
      debugPrint('🔔 Type: $type');
      debugPrint('🔔 Title: $title');
      debugPrint('🔔 Message: $body');

      // Route to NotificationService to handle it (it has all the callbacks and logic)
      // We'll simulate a WebSocket notification event
      final notificationService = NotificationService();
      
      // Convert to the format NotificationService expects from WebSocket
      final wsNotificationData = {
        'type': type,
        'title': title,
        'message': body,
        'data': data.isEmpty ? null : data,
        'timestamp': timestamp.toIso8601String(),
      };

      // Manually trigger the notification handler that WebSocket would normally trigger
      // This reuses all existing notification handling logic
      debugPrint('🔔 FCMService: Routing notification to NotificationService handlers');
      notificationService.handleNotificationFromFCM(wsNotificationData);
      
    } catch (e) {
      debugPrint('❌ FCMService: Error handling FCM notification: $e');
      // Fallback: show basic local notification
      final localNotificationService = LocalNotificationService();
      if (message.notification != null) {
        localNotificationService.showNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          id: message.hashCode,
          payload: message.data.toString(),
        );
      }
    }
  }

  /// Save FCM token to backend (public method to call after login)
  Future<void> saveTokenToBackend() async {
    // First, try to save any pending token (from token refresh while logged out)
    if (_pendingToken != null) {
      debugPrint('🔔 FCMService: Saving pending token that was queued: $_pendingToken');
      await _saveTokenToBackend(_pendingToken!);
    }
    
    // Also save current token if available
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

  /// Get current FCM token and log it (for debugging)
  Future<String?> getCurrentToken() async {
    try {
      if (_fcmToken == null) {
        // Try to get token if we don't have it
        await _getFCMToken();
      }
      
      if (_fcmToken != null) {
        debugPrint('🔔 FCMService: Current FCM Token: $_fcmToken');
        return _fcmToken;
      } else {
        debugPrint('⚠️ FCMService: No FCM token available');
        return null;
      }
    } catch (e) {
      debugPrint('❌ FCMService: Error getting current token: $e');
      return null;
    }
  }
}

