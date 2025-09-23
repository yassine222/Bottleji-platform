import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Callback for handling notification taps
  Function(String? payload)? handleNotificationTap;
  
  // Private variable for pending force logout reason
  String? _pendingForceLogoutReason;

  /// Handle notification tap - called when user taps on notification
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    
    print('🔔 LocalNotificationService: Handling notification tap with payload: $payload');
    
    if (payload.startsWith('force_logout:')) {
      final reason = payload.substring('force_logout:'.length);
      print('🔔 LocalNotificationService: Force logout notification tapped, reason: $reason');
      
      // Call the callback if set
      handleNotificationTap?.call(payload);
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'bottleji_notifications',
      'Bottleji Notifications',
      description: 'Notifications from Bottleji app',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    try {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      print('🔔 LocalNotificationService: Notification channel created successfully');
      
      // Check if channel was created
      final channels = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.getNotificationChannels();
      
      print('🔔 LocalNotificationService: Available channels: ${channels?.length ?? 0}');
      if (channels != null) {
        for (final channel in channels) {
          print('🔔 LocalNotificationService: Channel: ${channel.id} - ${channel.name}');
        }
      }
    } catch (e) {
      print('🔔 LocalNotificationService: Error creating notification channel: $e');
    }
  }

  Future<void> initialize() async {
    print('🔔 LocalNotificationService: Starting initialization...');
    
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Don't request permissions automatically - wait for user action
    // await _requestPermissions(); // REMOVED - This was causing the issue!

    // Initialize Android settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Initialize iOS settings - Set to false to prevent auto-request
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Changed to false
      requestBadgePermission: false, // Changed to false
      requestSoundPermission: false, // Changed to false
    );

    // Initialize settings
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('🔔 LocalNotificationService: Notification tapped: ${response.payload}');
        _handleNotificationTap(response.payload);
      },
    );
    
    // Create notification channel for Android
    await _createNotificationChannel();
    
    print('🔔 LocalNotificationService: Initialization completed (permissions not requested)');
  }

  Future<void> _requestPermissions() async {
    print('🔔 LocalNotificationService: Requesting notification permissions...');
    
    // Check current permission status
    final status = await Permission.notification.status;
    print('🔔 LocalNotificationService: Current notification permission status: $status');
    
    if (status.isDenied) {
      print('🔔 LocalNotificationService: Permission denied, requesting...');
      final newStatus = await Permission.notification.request();
      print('🔔 LocalNotificationService: New notification permission status: $newStatus');
      
      // If still denied, show a dialog to guide user to settings
      if (newStatus.isDenied) {
        print('🔔 LocalNotificationService: Permission still denied after request');
      }
    }
  }

  Future<bool> requestNotificationPermission() async {
    print('🔔 LocalNotificationService: Requesting notification permission...');
    
    try {
      // Check current status first
      final currentStatus = await Permission.notification.status;
      print('🔔 LocalNotificationService: Current permission status: $currentStatus');
      
      if (currentStatus.isGranted) {
        print('🔔 LocalNotificationService: Permission already granted');
        return true;
      }
      
      if (currentStatus.isPermanentlyDenied) {
        print('🔔 LocalNotificationService: Permission permanently denied');
        return false;
      }
      
      // For iOS, we need to handle it differently
      if (Platform.isIOS) {
        print('🔔 LocalNotificationService: iOS detected, using notification plugin');
        try {
          final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
          
          if (iosPlugin != null) {
            final granted = await iosPlugin.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
            print('🔔 LocalNotificationService: iOS permission result: $granted');
            return granted == true;
          } else {
            print('🔔 LocalNotificationService: iOS plugin not available');
            return false;
          }
        } catch (e) {
          print('🔔 LocalNotificationService: iOS permission error: $e');
          return false;
        }
      } else {
        // For Android, use permission_handler
        print('🔔 LocalNotificationService: Android detected, using permission_handler');
        try {
          final newStatus = await Permission.notification.request();
          print('🔔 LocalNotificationService: Android permission result: $newStatus');
          return newStatus.isGranted;
        } catch (e) {
          print('🔔 LocalNotificationService: Android permission error: $e');
          return false;
        }
      }
    } catch (e) {
      print('🔔 LocalNotificationService: General error requesting permission: $e');
      return false;
    }
  }

  Future<bool> forceRequestNotificationPermission() async {
    print('🔔 LocalNotificationService: Force requesting notification permission...');
    
    // Try to reset the permission state
    try {
      // Request permission multiple times to ensure it's properly set
      final status1 = await Permission.notification.request();
      print('🔔 LocalNotificationService: First request result: $status1');
      
      if (status1.isGranted) {
        return true;
      }
      
      // Wait a bit and try again
      await Future.delayed(const Duration(milliseconds: 500));
      final status2 = await Permission.notification.request();
      print('🔔 LocalNotificationService: Second request result: $status2');
      
      return status2.isGranted;
    } catch (e) {
      print('🔔 LocalNotificationService: Error requesting permission: $e');
      return false;
    }
  }

  Future<void> openAppSettings() async {
    print('🔔 LocalNotificationService: Opening app settings...');
    await AppSettings.openAppSettings();
  }

  bool isPermissionPermanentlyDenied() {
    // This method can be used to check if we should show settings guidance
    return false; // Will be updated based on the last request result
  }

  String getPermissionGuidanceMessage() {
    return 'Notification permission is permanently denied. Please:\n\n'
           '1. Go to Settings > Notifications > Bottleji\n'
           '2. Enable "Allow Notifications"\n'
           '3. Enable "Lock Screen", "Notification Centre", and "Banners"\n'
           '4. Restart the app';
  }

  /// Check iOS notification settings
  Future<void> checkIOSNotificationSettings() async {
    if (Platform.isIOS) {
      print('🔔 LocalNotificationService: Checking iOS notification settings...');
      try {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (iosPlugin != null) {
          // Check if we can request permissions
          final canRequest = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          print('🔔 LocalNotificationService: iOS can request permissions: $canRequest');
        }
      } catch (e) {
        print('🔔 LocalNotificationService: Error checking iOS settings: $e');
      }
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
    String? payload,
  }) async {
    print('🔔 LocalNotificationService: Showing notification - Title: $title, Body: $body, ID: $id');
    
    // For iOS, use the notification plugin's permission check
    if (Platform.isIOS) {
      print('🔔 LocalNotificationService: iOS detected, checking permission via notification plugin');
      try {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          print('🔔 LocalNotificationService: iOS plugin permission check: $granted');
          
          if (granted != true) {
            print('🔔 LocalNotificationService: iOS permission not granted via plugin');
            return;
          }
        } else {
          print('🔔 LocalNotificationService: iOS plugin not available');
          return;
        }
      } catch (e) {
        print('🔔 LocalNotificationService: iOS permission check error: $e');
        return;
      }
    } else {
      // For Android, use permission_handler
      final permissionStatus = await Permission.notification.status;
      print('🔔 LocalNotificationService: Android permission status: $permissionStatus');
      
      if (permissionStatus.isDenied) {
        print('🔔 LocalNotificationService: Android permission denied, requesting...');
        final newStatus = await Permission.notification.request();
        print('🔔 LocalNotificationService: Android new permission status: $newStatus');
        
        if (!newStatus.isGranted) {
          print('🔔 LocalNotificationService: Android permission still not granted, cannot show notification');
          return;
        }
      } else if (permissionStatus.isPermanentlyDenied) {
        print('🔔 LocalNotificationService: Android permission permanently denied, cannot show notification');
        return;
      }
    }
    
    // Create notification details with more specific iOS settings
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,  // Show alert/banner
      presentBadge: true,  // Show badge
      presentSound: true,  // Play sound
      sound: 'default',    // Use default sound
      badgeNumber: 1,      // Set badge number
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Show the notification
    try {
      print('🔔 LocalNotificationService: About to show notification with details: $details');
      await _notifications.show(id, title, body, details, payload: payload);
      print('🔔 LocalNotificationService: Notification shown successfully');
      
      // Check if notification was actually scheduled
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      print('🔔 LocalNotificationService: Pending notifications count: ${pendingNotifications.length}');
      
    } catch (e) {
      print('🔔 LocalNotificationService: Error showing notification: $e');
    }
  }

  Future<void> showForceLogoutNotification({
    required String reason,
  }) async {
    await showNotification(
      title: 'Session Terminated',
      body: reason,
      id: 999, // Special ID for force logout
      payload: 'force_logout:$reason', // Add payload for handling tap
    );
  }

  /// Show force logout dialog when app is opened from notification
  Future<void> showForceLogoutDialog(String reason) async {
    print('🔔 LocalNotificationService: Showing force logout dialog');
    
    // Use a global key or navigator to show dialog
    // This will be called from the main app when notification is tapped
    // For now, we'll store the reason and let the main app handle it
    _pendingForceLogoutReason = reason;
  }

  /// Get pending force logout reason and clear it
  String? getPendingForceLogoutReason() {
    final reason = _pendingForceLogoutReason;
    _pendingForceLogoutReason = null;
    return reason;
  }

  Future<void> showWelcomeNotification() async {
    print('🔔 LocalNotificationService: Showing welcome notification');
    await showNotification(
      title: 'Connected',
      body: 'You are now connected to real-time notifications',
      id: 1,
    );
    print('🔔 LocalNotificationService: Welcome notification completed');
  }

  /// Schedule a delayed notification to test if iOS shows banners in background
  Future<void> scheduleTestNotification() async {
    print('🔔 LocalNotificationService: Scheduling delayed test notification...');
    
    // Check iOS notification settings first
    await checkIOSNotificationSettings();
    
    // Schedule notification for 5 seconds from now
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    try {
      await _notifications.zonedSchedule(
        1000, // Different ID
        'Scheduled Test Notification',
        'This notification was scheduled 5 seconds ago - should show as banner!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('🔔 LocalNotificationService: Scheduled notification for ${scheduledDate.toString()}');
      
      // Check pending notifications
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      print('🔔 LocalNotificationService: Pending notifications after scheduling: ${pendingNotifications.length}');
      
    } catch (e) {
      print('🔔 LocalNotificationService: Error scheduling notification: $e');
    }
  }

  Future<void> showTestNotification() async {
    print('🔔 LocalNotificationService: Showing test notification');
    
    // Check iOS notification settings first
    await checkIOSNotificationSettings();
    
    // Don't request permission again - just show the notification
    // The permission should already be granted from the previous request
    await showNotification(
      title: 'Test Notification',
      body: 'This is a test notification to verify the system is working!',
      id: 999,
    );
    print('🔔 LocalNotificationService: Test notification completed');
  }

  /// Test method to check if permission requests work
  Future<void> testPermissionRequest() async {
    print('🔔 LocalNotificationService: Testing permission request...');
    
    try {
      // Test basic permission status
      final status = await Permission.notification.status;
      print('🔔 LocalNotificationService: Test - Current status: $status');
      
      // Test if we can request at all
      if (status.isDenied) {
        print('🔔 LocalNotificationService: Test - Attempting to request permission...');
        final newStatus = await Permission.notification.request();
        print('🔔 LocalNotificationService: Test - Request result: $newStatus');
      } else {
        print('🔔 LocalNotificationService: Test - Status is not denied: $status');
      }
    } catch (e) {
      print('🔔 LocalNotificationService: Test - Error: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Show drop expired notification without requiring context (for background scenarios)
  Future<void> showDropExpiredNotificationBackground({
    required String dropId,
    required String dropTitle,
  }) async {
    print('🔔 LocalNotificationService: Starting background notification for drop: $dropId');
    print('🔔 LocalNotificationService: Drop title: $dropTitle');
    
    try {
      // Always show system notification for background scenarios
      print('🔔 LocalNotificationService: Calling showNotification...');
      final notificationId = 3000 + dropId.hashCode % 1000; // Unique ID based on drop ID
      print('🔔 LocalNotificationService: Using notification ID: $notificationId');
      
      await showNotification(
        title: 'Collection Expired',
        body: 'Your collection for "$dropTitle" has expired',
        id: notificationId,
        payload: 'drop_expired:$dropId',
      );
      print('🔔 LocalNotificationService: Background notification sent successfully for drop expiration');
    } catch (e) {
      print('❌ LocalNotificationService: Error sending background notification: $e');
      rethrow;
    }
  }

  /// Show notification that works in both foreground and background
  Future<void> showDropExpiredNotification({
    required String dropId,
    required String dropTitle,
    required BuildContext context,
  }) async {
    print('🔔 LocalNotificationService: Showing drop expired notification for drop: $dropId');
    
    // Check if app is in foreground
    final isInForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    print('🔔 LocalNotificationService: App lifecycle state: ${WidgetsBinding.instance.lifecycleState}');
    print('🔔 LocalNotificationService: Is in foreground: $isInForeground');
    
    if (isInForeground) {
      // Show in-app notification (SnackBar)
      print('🔔 LocalNotificationService: App in foreground - showing SnackBar');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Collection expired: $dropTitle'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to drop details or history
                print('🔔 LocalNotificationService: User tapped view on expired drop');
              },
            ),
          ),
        );
      }
    } else {
      // Show system notification (background)
      print('🔔 LocalNotificationService: App in background - showing system notification');
      await showNotification(
        title: 'Collection Expired',
        body: 'Your collection for "$dropTitle" has expired',
        id: 3000,
        payload: 'drop_expired:$dropId',
      );
    }
  }

  /// Show notification for drop status changes
  Future<void> showDropStatusNotification({
    required String dropId,
    required String dropTitle,
    required String status, // 'accepted', 'collected', 'cancelled', 'expired'
    required BuildContext context,
  }) async {
    print('🔔 LocalNotificationService: Showing drop status notification: $status for drop: $dropId');
    
    // Check if app is in foreground
    final isInForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    
    String title;
    String message;
    Color snackBarColor;
    IconData icon;
    
    switch (status) {
      case 'accepted':
        title = 'Drop Accepted';
        message = 'You accepted to collect: $dropTitle';
        snackBarColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'collected':
        title = 'Drop Collected';
        message = 'Successfully collected: $dropTitle';
        snackBarColor = Colors.green;
        icon = Icons.done_all;
        break;
      case 'cancelled':
        title = 'Drop Cancelled';
        message = 'Collection cancelled for: $dropTitle';
        snackBarColor = Colors.red;
        icon = Icons.cancel;
        break;
      case 'expired':
        title = 'Collection Expired';
        message = 'Collection expired for: $dropTitle';
        snackBarColor = Colors.orange;
        icon = Icons.schedule;
        break;
      default:
        title = 'Drop Update';
        message = 'Status updated for: $dropTitle';
        snackBarColor = Colors.blue;
        icon = Icons.info;
    }
    
    if (isInForeground) {
      // Show in-app notification (SnackBar)
      print('🔔 LocalNotificationService: App in foreground - showing SnackBar');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: snackBarColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to drop details
                print('🔔 LocalNotificationService: User tapped view on drop status');
              },
            ),
          ),
        );
      }
    } else {
      // Show system notification (background)
      print('🔔 LocalNotificationService: App in background - showing system notification');
      await showNotification(
        title: title,
        body: message,
        id: 3000 + status.hashCode, // Unique ID for each status
        payload: 'drop_status:$dropId:$status',
      );
    }
  }

  /// Show application approval notification
  Future<void> showApplicationApprovedNotification({
    required BuildContext context,
  }) async {
    print('🔔 LocalNotificationService: Showing application approved notification');
    
    const title = 'Application Approved!';
    const message = 'Congratulations! Your collector application has been approved. You can now start collecting!';
    
    // Check if app is in foreground
    final isInForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    
    if (isInForeground) {
      // Show in-app notification (SnackBar)
      print('🔔 LocalNotificationService: App in foreground - showing SnackBar');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Start Collecting',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to collector mode or home
                print('🔔 LocalNotificationService: User tapped start collecting');
              },
            ),
          ),
        );
      }
    } else {
      // Show system notification (background)
      print('🔔 LocalNotificationService: App in background - showing system notification');
      await showNotification(
        title: title,
        body: message,
        id: 4000,
        payload: 'application_approved',
      );
    }
  }

  /// Show application rejection notification
  Future<void> showApplicationRejectedNotification({
    required String reason,
    required BuildContext context,
  }) async {
    print('🔔 LocalNotificationService: Showing application rejected notification');
    
    const title = 'Application Update';
    final message = 'Your collector application was not approved: $reason';
    
    // Check if app is in foreground
    final isInForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    
    if (isInForeground) {
      // Show in-app notification (SnackBar)
      print('🔔 LocalNotificationService: App in foreground - showing SnackBar');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'View Details',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to application details or support
                print('🔔 LocalNotificationService: User tapped view details');
              },
            ),
          ),
        );
      }
    } else {
      // Show system notification (background)
      print('🔔 LocalNotificationService: App in background - showing system notification');
      await showNotification(
        title: title,
        body: message,
        id: 4001,
        payload: 'application_rejected:$reason',
      );
    }
  }

  /// Check if app is in foreground
  bool isAppInForeground() {
    return WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }
}