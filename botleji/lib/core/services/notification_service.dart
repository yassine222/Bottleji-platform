// Removed unused: import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
// Removed unused: import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_service.dart';
import '../config/server_config.dart';

enum NotificationType {
  // User management
  userDeleted,
  userBanned,
  userUnbanned,
  roleChanged,
  
  // Drop management
  dropAccepted,
  dropCollected,
  dropCancelled,
  dropExpired,
  dropNearExpiring,
  newDropAvailable,
  
  // Support
  ticketResponse,
  ticketStatusChanged,
  
  // Applications
  applicationApproved,
  applicationRejected,
  
  // Training
  newTrainingContent,
  trainingCompleted,
  
  // Rewards
  pointsEarned,
  pointsSpent,
  
  // System
  systemMaintenance,
  announcement,
  
  // Connection
  connectionEstablished,
  forceLogout,
}

class NotificationPayload {
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final String? userId;
  final DateTime timestamp;

  NotificationPayload({
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.userId,
    required this.timestamp,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),);
  }
}

class NotificationService extends ChangeNotifier {
  // Removed unused _namespace
  
  IO.Socket? _socket;
  bool _isConnected = false;
  // Removed unused _currentUserId
  final List<NotificationPayload> _notifications = [];
  final LocalNotificationService _localNotificationService = LocalNotificationService();
  final Map<String, DateTime> _recentNotificationKeys = {};
  
  // Getters
  bool get isConnected => _isConnected;
  List<NotificationPayload> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !(n.data?['read'] == true)).length;
  bool get hasSocket => _socket != null;
  IO.Socket? get socket => _socket; // Expose socket for location updates

  // Callbacks
  Function(String reason)? onForceLogout;
  Function(NotificationPayload)? onNotificationReceived;
  Function()? onConnectionEstablished;
  Function()? onConnectionLost;
  Function(String status, Map<String, dynamic> data)? onApplicationStatusUpdate;
  Function(String ticketId, Map<String, dynamic> message)? onTicketMessageReceived;
  Function(String ticketId, bool isTyping, String senderType)? onTypingIndicator;
  Function(String ticketId, bool isPresent, String senderType)? onPresenceIndicator;
  Function(bool isLocked, DateTime? lockedUntil, int warningCount)? onAccountLockStatusUpdate;
  Function(String orderId, String itemName, String rejectionReason, int pointsRefunded)? onOrderRejected;
  Function(String orderId, String itemName, String? trackingNumber)? onOrderApproved;
  Function()? onAccountPermanentlyDisabled;
  Function()? onAccountDeleted; // Callback for permanent account disable (to show dialog)
  Function(String dropId, String reason)? onDropCensored;
  Function(String dropId, String status, Map<String, dynamic> data)? onDropStatusUpdate;
  Function(NotificationPayload)? onDropCollectedForHousehold;

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize local notifications only
    await _localNotificationService.initialize();
    
    // Don't automatically connect to WebSocket - wait for explicit connect call
    debugPrint('🔌 NotificationService: Initialized (WebSocket connection will be established on login)');
  }

  /// Connect to WebSocket notifications
  Future<void> connect(String token) async {
    try {
      debugPrint('🔌 NotificationService: Connecting to WebSocket...');
      debugPrint('🔌 NotificationService: Token provided: ${token.isNotEmpty}');
      debugPrint('🔌 NotificationService: Token preview: ${token.length > 20 ? token.substring(0, 20) + '...' : token}');
      
      // Disconnect any existing connection first
      if (_socket != null) {
        debugPrint('🔌 NotificationService: Disconnecting existing socket...');
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }
      
      // Initialize Socket.IO client with better error handling
      final socketUrl = await ServerConfig.socketUrl;
      debugPrint('🔌 NotificationService: Using socket URL: $socketUrl');
      _socket = IO.io('$socketUrl/notifications', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false, // Don't auto-connect, we'll connect manually
        'timeout': 10000, // 10 second timeout
        'reconnection': true,
        'reconnectionAttempts': 3,
        'reconnectionDelay': 1000,
        'auth': {
          'token': token,
      }});

      // Connection events
      _socket!.onConnect((_) {
        debugPrint('🔌 WebSocket connected');
        _isConnected = true;
        notifyListeners();
        _socket!.emit('ping');
      });

      _socket!.onDisconnect((_) {
        debugPrint('🔌 WebSocket disconnected');
        _isConnected = false;
        notifyListeners();
      });

      _socket!.onConnectError((error) {
        debugPrint('❌ WebSocket connection error: $error');
        _isConnected = false;
        notifyListeners();
      });

      // Catch-all listener for debugging
      _socket!.onAny((event, data) {
        debugPrint('🔍 ===== RECEIVED ANY EVENT =====');
        debugPrint('🔍 Event name: $event');
        debugPrint('🔍 Event data: $data');
        debugPrint('🔍 Event data type: ${data.runtimeType}');
        debugPrint('🔍 ================================');
      });

      // Listen for pong responses
      _socket!.on('pong', (data) {
        debugPrint('🏓 Pong received: $data');
      });

      // Notification events
      _socket!.on('notification', (data) {
        debugPrint('🔔 ===== NOTIFICATION EVENT RECEIVED (from WebSocket) =====');
        // Route to shared handler (same logic as FCM)
        handleNotificationFromFCM(data);
      });
      
      // Legacy handler logic (kept for reference, but now using shared method above)
      // The _handleNotificationFromFCM method handles all notification types
      _socket!.on('notification_legacy', (data) {
        debugPrint('🔔 ===== NOTIFICATION EVENT RECEIVED (LEGACY) =====');
        debugPrint('🔔 Notification type: ${data['type']}');
        debugPrint('🔔 Notification title: ${data['title']}');
        debugPrint('🔔 Notification message: ${data['message']}');
        debugPrint('🔔 Full notification data: $data');
        debugPrint('🔔 ========================================');

        // De-dup: ignore if same type+timestamp+id seen in last 10s
        // For ticket messages and account lock/unlock, bypass de-duplication entirely to ensure all messages are shown
        final type = (data['type'] ?? '').toString();
        
        // Skip de-duplication for ticket messages and account lock/unlock - they should always be shown
        if (type != 'ticket_message' && type != 'account_locked' && type != 'account_unlocked') {
          try {
            final ts = (data['timestamp'] ?? '').toString();
            final idHint = (data['data']?['ticketId'] ?? data['data']?['dropId'] ?? data['userId'] ?? '').toString();
            final key = '$type|$ts|$idHint';
            
            // Clean old entries
            _recentNotificationKeys.removeWhere((_, t) => DateTime.now().difference(t) > const Duration(seconds: 20));
            
            if (_recentNotificationKeys.containsKey(key)) {
              debugPrint('🔁 Duplicate notification suppressed: $key');
              debugPrint('🔁 This notification was already shown in the last 20 seconds');
              return;
            }
            _recentNotificationKeys[key] = DateTime.now();
            debugPrint('🔔 Notification key: $key (not a duplicate, proceeding)');
          } catch (e) {
            debugPrint('⚠️ Error in de-duplication logic: $e');
          }
        } else {
          if (type == 'ticket_message') {
            debugPrint('🔔 Ticket message notification - bypassing de-duplication to ensure delivery');
          } else if (type == 'account_locked' || type == 'account_unlocked') {
            debugPrint('🔔 Account lock/unlock notification - bypassing de-duplication to ensure delivery');
          }
        }
        
        // Handle account lock/unlock notifications
        if (data['type'] == 'account_locked' || data['type'] == 'account_unlocked') {
          debugPrint('🔒 ===== ACCOUNT LOCK/UNLOCK NOTIFICATION RECEIVED =====');
          debugPrint('🔒 Notification type: ${data['type']}');
          debugPrint('🔒 Title: ${data['title']}');
          debugPrint('🔒 Message: ${data['message']}');
          debugPrint('🔒 Full data: $data');
          
          final isLocked = data['data']?['isAccountLocked'] ?? false;
          final lockedUntilValue = data['data']?['accountLockedUntil'];
          final warningCount = data['data']?['warningCount'] ?? 0;
          
          debugPrint('🔒 Raw lockedUntil value: $lockedUntilValue (type: ${lockedUntilValue.runtimeType})');
          
          DateTime? lockedUntil;
          // Handle null, empty string, or "null" string
          if (lockedUntilValue != null && 
              lockedUntilValue.toString().isNotEmpty && 
              lockedUntilValue.toString().toLowerCase() != 'null') {
            try {
              lockedUntil = DateTime.parse(lockedUntilValue.toString());
            } catch (e) {
              debugPrint('❌ Error parsing lockedUntil date: $e');
              debugPrint('❌ Value was: $lockedUntilValue');
            }
          } else {
            debugPrint('🔒 lockedUntil is null/empty - this is a PERMANENT lock');
            lockedUntil = null;
          }
          
          debugPrint('🔒 Lock status: $isLocked, Until: $lockedUntil, Warnings: $warningCount');
          
          // Check if this is a permanent disable (isLocked = true and lockedUntil = null)
          final isPermanentlyDisabled = isLocked && lockedUntil == null;
          debugPrint('🔒 Is permanently disabled: $isPermanentlyDisabled');
          
          // Show push notification
          // Use different notification IDs for lock vs unlock to ensure both show up
          final notificationId = isLocked ? 9000 : 9001;
          final payload = isLocked ? 'account_locked' : 'account_unlocked';
          
          debugPrint('🔒 Attempting to show local notification for ${isLocked ? "LOCK" : "UNLOCK"}...');
          debugPrint('🔒 Notification ID: $notificationId');
          _localNotificationService.showNotification(
            title: data['title'] ?? (isLocked ? 'Account Locked' : 'Account Unlocked'),
            body: data['message'] ?? '',
            id: notificationId,
            payload: payload,
          );
          debugPrint('🔒 Local notification service called - ${isLocked ? "LOCK" : "UNLOCK"} notification should now be visible');
          
          // Call the callback to update user state
          if (onAccountLockStatusUpdate != null) {
            debugPrint('🔒 Calling account lock status update callback');
            onAccountLockStatusUpdate!.call(isLocked, lockedUntil, warningCount);
          } else {
            debugPrint('⚠️ onAccountLockStatusUpdate callback is null');
          }
          
          // If permanently disabled, trigger the permanent disable callback to show dialog
          if (isPermanentlyDisabled) {
            debugPrint('🔒 ===== ACCOUNT PERMANENTLY DISABLED DETECTED =====');
            debugPrint('🔒 Account permanently disabled - triggering permanent disable callback');
            debugPrint('🔒 Callback is null: ${onAccountPermanentlyDisabled == null}');
            if (onAccountPermanentlyDisabled != null) {
              debugPrint('🔒 Calling onAccountPermanentlyDisabled callback NOW');
              try {
                // Call immediately
                onAccountPermanentlyDisabled!.call();
                debugPrint('🔒 Callback executed successfully');
                
                // Also schedule a delayed call as backup (in case first one fails)
                Future.delayed(const Duration(milliseconds: 1000), () {
                  debugPrint('🔒 Backup: Calling onAccountPermanentlyDisabled callback again');
                  try {
                    onAccountPermanentlyDisabled!.call();
                  } catch (e) {
                    debugPrint('❌ Backup callback also failed: $e');
                  }
                });
              } catch (e) {
                debugPrint('❌ Error executing callback: $e');
                // Retry after a delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  debugPrint('🔒 Retrying callback after error');
                  try {
                    onAccountPermanentlyDisabled!.call();
                  } catch (e2) {
                    debugPrint('❌ Retry also failed: $e2');
                  }
                });
              }
            } else {
              debugPrint('⚠️ onAccountPermanentlyDisabled callback is null - popup will not show!');
              debugPrint('⚠️ This means the callback was not set up in main.dart');
            }
            debugPrint('🔒 ====================================================');
          }

          debugPrint('🔒 ====================================================');
          // We've already shown a notification for lock/unlock; skip generic handler
          return;
        }
        
        // Handle account restored notification
        if (data['type'] == 'account_restored') {
          debugPrint('✅ ===== ACCOUNT RESTORED NOTIFICATION RECEIVED =====');
          debugPrint('✅ Notification type: ${data['type']}');
          debugPrint('✅ Title: ${data['title']}');
          debugPrint('✅ Message: ${data['message']}');
          debugPrint('✅ Full data: $data');
          
          // Show push notification
          debugPrint('✅ Attempting to show local notification...');
          _localNotificationService.showNotification(
            title: data['title'] ?? 'Account Restored',
            body: data['message'] ?? 'Your account has been restored. You can now log in again!',
            id: 9500, // Unique ID for account restored notifications
            payload: 'account_restored',
          );
          debugPrint('✅ Local notification service called');
          
          debugPrint('✅ ====================================================');
          // Skip generic handler to avoid duplicate toast
          return;
        }
        
        // Handle user deleted notification (soft delete by admin)
        if (data['type'] == 'user_deleted') {
          debugPrint('🗑️ ===== USER DELETED NOTIFICATION RECEIVED =====');
          debugPrint('🗑️ Notification type: ${data['type']}');
          debugPrint('🗑️ Title: ${data['title']}');
          debugPrint('🗑️ Message: ${data['message']}');
          debugPrint('🗑️ Full data: $data');
          
          // Show push notification
          debugPrint('🗑️ Attempting to show local notification...');
          _localNotificationService.showNotification(
            title: data['title'] ?? 'Account Deleted',
            body: data['message'] ?? 'Your account has been deleted by an administrator.',
            id: 9200, // Unique ID for user deleted notifications
            payload: 'user_deleted',
          );
          debugPrint('🗑️ Local notification service called');
          
          // Trigger the account deleted callback to show dialog
          debugPrint('🗑️ ===== ACCOUNT DELETED DETECTED =====');
          debugPrint('🗑️ Account deleted - triggering account deleted callback');
          debugPrint('🗑️ Callback is null: ${onAccountDeleted == null}');
          if (onAccountDeleted != null) {
            debugPrint('🗑️ Calling onAccountDeleted callback NOW');
            try {
              // Call immediately
              onAccountDeleted!.call();
              debugPrint('🗑️ Callback executed successfully');
              
              // Also schedule a delayed call as backup (in case first one fails)
              Future.delayed(const Duration(milliseconds: 1000), () {
                debugPrint('🗑️ Backup: Calling onAccountDeleted callback again');
                try {
                  onAccountDeleted!.call();
                } catch (e) {
                  debugPrint('❌ Backup callback also failed: $e');
                }
              });
            } catch (e) {
              debugPrint('❌ Error executing callback: $e');
              // Retry after a delay
              Future.delayed(const Duration(milliseconds: 500), () {
                debugPrint('🗑️ Retrying callback after error');
                try {
                  onAccountDeleted!.call();
                } catch (e2) {
                  debugPrint('❌ Retry also failed: $e2');
                }
              });
            }
          } else {
            debugPrint('⚠️ onAccountDeleted callback is null - popup will not show!');
            debugPrint('⚠️ This means the callback was not set up in main.dart');
          }
          debugPrint('🗑️ ====================================================');
          
          // Skip generic handler to avoid duplicate toast
          return;
        }
        
        // Handle drop censored notification
        if (data['type'] == 'drop_censored') {
          debugPrint('🛑 Drop censored notification received');
          final dropId = data['data']?['dropId']?.toString();
          final reason = data['data']?['reason']?.toString() ?? data['message']?.toString() ?? 'Censored image';
          // Show local notification
          _localNotificationService.showNotification(
            title: data['title'] ?? 'Drop Image Censored',
            body: data['message'] ?? 'Your drop image was censored',
            id: 9100,
            payload: 'drop_censored:${dropId ?? ''}',
          );
          if (dropId != null) {
            onDropCensored?.call(dropId, reason);
          }

          // Skip generic handler to avoid duplicate toast
          return;
        }
        
        // Handle ticket message notifications
        if (data['type'] == 'ticket_message') {
          debugPrint('📨 NotificationService: Ticket message notification received!');
          final ticketId = data['data']?['ticketId'] ?? '';
          final message = data['message'] ?? 'You have a new message on your support ticket';
          debugPrint('📨 NotificationService: Ticket ID: $ticketId');
          debugPrint('📨 NotificationService: Message: $message');
          debugPrint('📨 NotificationService: Full data: ${data['data']}');
          debugPrint('📨 NotificationService: Message data: ${data['data']?['message']}');
          
          // Show push notification with unique ID for each message
          // Use timestamp + message hash to ensure each message gets a unique notification ID
          final messageData = data['data']?['message'];
          final sentAt = messageData?['sentAt']?.toString() ?? DateTime.now().toIso8601String();
          final messageHash = message.hashCode;
          final uniqueNotificationId = 5000 + (ticketId.hashCode + messageHash + sentAt.hashCode) % 100000;
          
          _localNotificationService.showNotification(
            title: data['title'] ?? 'New Support Message',
            body: message,
            id: uniqueNotificationId, // Unique ID for each message
            payload: 'ticket:$ticketId',
          );
          
          // Call the ticket message callback for real-time updates (if user is viewing the ticket)
          debugPrint('📨 NotificationService: Checking callback - onTicketMessageReceived: ${onTicketMessageReceived != null}');
          debugPrint('📨 NotificationService: Data available: ${data['data'] != null}');
          if (onTicketMessageReceived != null && data['data'] != null) {
            debugPrint('📨 NotificationService: Calling ticket message callback for ticket: $ticketId');
            debugPrint('📨 NotificationService: Callback data: ${data['data']}');
            onTicketMessageReceived!(ticketId, data['data']);
            debugPrint('📨 NotificationService: Callback completed');
          } else {
            debugPrint('📨 NotificationService: Callback not set or data missing');
            debugPrint('📨 NotificationService: onTicketMessageReceived is null: ${onTicketMessageReceived == null}');
            debugPrint('📨 NotificationService: data[data] is null: ${data['data'] == null}');
          }
          // Skip generic handler to avoid duplicate toast
          return;
        }
        
        // Handle order approved notification
        if (data['type'] == 'order_approved') {
          debugPrint('🎉 Order approved notification received!');
          final orderId = data['data']?['orderId']?.toString() ?? '';
          final trackingNumber = data['data']?['trackingNumber']?.toString() ?? '';
          final estimatedDelivery = data['data']?['estimatedDelivery']?.toString();
          
          debugPrint('🎉 Order ID: $orderId');
          debugPrint('🎉 Tracking Number: $trackingNumber');
          debugPrint('🎉 Estimated Delivery: $estimatedDelivery');
          
          // Get item name from notification data
          final itemName = data['data']?['rewardItemName']?.toString() ?? 
                          'Your order';
          
          // Show local notification
          _localNotificationService.showNotification(
            title: data['title'] ?? 'Order Approved! 🎉',
            body: data['message'] ?? 'Your order has been approved and is being prepared for shipment',
            id: 9300,
            payload: 'order_approved:$orderId',
          );
          
          // Call callback to show popup
          if (onOrderApproved != null) {
            onOrderApproved!(orderId, itemName, trackingNumber);
          }
          
          // Skip generic handler to avoid duplicate toast
          return;
        }
        
        // Handle order rejected notification
        if (data['type'] == 'order_rejected') {
          debugPrint('❌ Order rejected notification received!');
          final orderId = data['data']?['orderId']?.toString() ?? '';
          final rejectionReason = data['data']?['rejectionReason']?.toString() ?? '';
          final pointsAmount = data['data']?['pointsAmount']?.toString() ?? '';
          
          debugPrint('❌ Order ID: $orderId');
          debugPrint('❌ Rejection Reason: $rejectionReason');
          debugPrint('❌ Points Refunded: $pointsAmount');
          
          // Get item name and points from notification data
          final itemName = data['data']?['rewardItemName']?.toString() ?? 
                          'Your order';
          final pointsRefunded = int.tryParse(pointsAmount) ?? 0;
          
          // Show local notification
          _localNotificationService.showNotification(
            title: data['title'] ?? 'Order Rejected',
            body: data['message'] ?? 'Your order was rejected and points have been refunded',
            id: 9400,
            payload: 'order_rejected:$orderId',
          );
          
          // Call callback to show popup
          if (onOrderRejected != null) {
            onOrderRejected!(orderId, itemName, rejectionReason.isEmpty ? 'No reason provided' : rejectionReason, pointsRefunded);
          }
          
          // Skip generic handler to avoid duplicate toast
          return;
        }

        // Fallback: for other notification types, use the generic handler once
        debugPrint('📨 NotificationService: Received notification of type: ${data['type']} (generic handler)');
        debugPrint('📨 NotificationService: Raw notification data: $data');
        try {
          final notification = NotificationPayload(
            type: data['type'] ?? 'unknown',
            title: data['title'] ?? 'Notification',
            message: data['message'] ?? '',
            data: data['data'],
            timestamp: DateTime.parse(data['timestamp']),
          );
          _handleNotification(notification);
        } catch (e) {
          debugPrint('❌ Error parsing notification: $e');
        }
      });

      // Force logout event
      _socket!.on('force_logout', (data) {
        debugPrint('🚪 NotificationService: Force logout event received!');
        debugPrint('🚪 NotificationService: Force logout data: $data');
        debugPrint('🚪 NotificationService: Force logout data type: ${data.runtimeType}');
        debugPrint('🚪 NotificationService: Force logout data keys: ${data is Map ? data.keys.toList() : 'Not a Map'}');
        
        final reason = data['reason'] ?? 'Session terminated';
        debugPrint('🚪 NotificationService: Force logout reason: $reason');
        
        // Show force logout notification
        debugPrint('🔔 NotificationService: About to show force logout notification');
        _localNotificationService.showForceLogoutNotification(reason: reason);
        debugPrint('🔔 NotificationService: Force logout notification sent');
        
        debugPrint('🚪 NotificationService: Calling onForceLogout callback');
        onForceLogout?.call(reason);
        debugPrint('🚪 NotificationService: onForceLogout callback completed');
      });

      // Typing indicator event
      _socket!.on('typing_indicator', (data) {
        debugPrint('📝 NotificationService: ===== TYPING INDICATOR RECEIVED =====');
        debugPrint('📝 NotificationService: Typing indicator received: $data');
        debugPrint('📝 NotificationService: onTypingIndicator callback: ${onTypingIndicator != null}');
        debugPrint('📝 NotificationService: ticketId: ${data['ticketId']}');
        if (onTypingIndicator != null && data['ticketId'] != null) {
          debugPrint('📝 NotificationService: Calling typing indicator callback');
          onTypingIndicator!(
            data['ticketId'],
            data['isTyping'] ?? false,
            data['senderType'] ?? 'agent'
          );
          debugPrint('📝 NotificationService: Typing indicator callback completed');
        } else {
          debugPrint('📝 NotificationService: Typing indicator callback not set or ticketId missing');
        }
      });

      // Presence indicator event
      _socket!.on('presence_indicator', (data) {
        debugPrint('👤 NotificationService: ===== PRESENCE INDICATOR RECEIVED =====');
        debugPrint('👤 NotificationService: Presence indicator received: $data');
        debugPrint('👤 NotificationService: onPresenceIndicator callback: ${onPresenceIndicator != null}');
        debugPrint('👤 NotificationService: ticketId: ${data['ticketId']}');
        if (onPresenceIndicator != null && data['ticketId'] != null) {
          debugPrint('👤 NotificationService: Calling presence indicator callback');
          onPresenceIndicator!(
            data['ticketId'],
            data['isPresent'] ?? false,
            data['senderType'] ?? 'agent'
          );
          debugPrint('👤 NotificationService: Presence indicator callback completed');
        } else {
          debugPrint('👤 NotificationService: Presence indicator callback not set or ticketId missing');
        }
      });

      // Application approval event
      _socket!.on('application_approved', (data) {
        debugPrint('🎉 NotificationService: Application approved event received!');
        debugPrint('🎉 NotificationService: Application approved data: $data');
        
        // Show application approved notification (background only)
        debugPrint('🔔 NotificationService: About to show application approved notification');
        _localNotificationService.showNotification(
          title: 'Application Approved!',
          body: 'Congratulations! Your collector application has been approved. You can now start collecting!',
          id: 4000,
          payload: 'application_approved',
        );
        debugPrint('🔔 NotificationService: Application approved notification sent');
        
        // Call the callback to update shared preferences
        if (onApplicationStatusUpdate != null) {
          onApplicationStatusUpdate!('approved', data);
        }
        
        // Call notification callback
        onNotificationReceived?.call(NotificationPayload(
          type: 'application_approved',
          title: 'Application Approved!',
          message: 'Congratulations! Your collector application has been approved.',
          data: data,
          timestamp: DateTime.parse(data['timestamp']),
        ));
      });

      // Application rejection event
      _socket!.on('application_rejected', (data) {
        debugPrint('❌ NotificationService: Application rejected event received!');
        debugPrint('❌ NotificationService: Application rejected data: $data');
        
        final reason = data['reason'] ?? 'Application was not approved';
        debugPrint('❌ NotificationService: Application rejection reason: $reason');
        
        // Show application rejected notification (background only)
        debugPrint('🔔 NotificationService: About to show application rejected notification');
        _localNotificationService.showNotification(
          title: 'Application Update',
          body: 'Your collector application was not approved: $reason',
          id: 4001,
          payload: 'application_rejected:$reason',
        );
        debugPrint('🔔 NotificationService: Application rejected notification sent');
        
        // Call the callback to update shared preferences
        if (onApplicationStatusUpdate != null) {
          onApplicationStatusUpdate!('rejected', data);
        }
        
        // Call notification callback
        onNotificationReceived?.call(NotificationPayload(
          type: 'application_rejected',
          title: 'Application Update',
          message: 'Your collector application was not approved: $reason',
          data: data,
          timestamp: DateTime.parse(data['timestamp']),
        ));
      });

      // Ping/Pong for connection health
      _socket!.on('pong', (data) {
        debugPrint('🏓 Pong received: ${data['timestamp']}');
      });

      // Catch-all event listener to see if ANY events are being received
      _socket!.onAny((eventName, data) {
        debugPrint('🔍 NotificationService: Received ANY event: $eventName');
        debugPrint('🔍 NotificationService: Event data: $data');
      });
      
      // Now connect manually
      debugPrint('🔌 NotificationService: Attempting to connect...');
      _socket!.connect();
      
      debugPrint('🔌 NotificationService: WebSocket setup completed');
    } catch (e) {
      debugPrint('❌ NotificationService: Error setting up WebSocket: $e');
    }
  }

  /// Setup WebSocket event listeners
  // Removed unused _setupEventListeners (legacy)

  /// Handle notification from FCM (can also be called from WebSocket)
  /// This method processes notification data in the same format as WebSocket notifications
  /// Made public so FCMService can call it
  void handleNotificationFromFCM(Map<String, dynamic> data) {
    debugPrint('🔔 ===== NOTIFICATION EVENT RECEIVED (from FCM) =====');
    debugPrint('🔔 Notification type: ${data['type']}');
    debugPrint('🔔 Notification title: ${data['title']}');
    debugPrint('🔔 Notification message: ${data['message']}');
    debugPrint('🔔 Full notification data: $data');
    debugPrint('🔔 ========================================');

    // De-dup: ignore if same type+timestamp+id seen in last 10s
    // For ticket messages and account lock/unlock, bypass de-duplication entirely to ensure all messages are shown
    final type = (data['type'] ?? '').toString();
    
    // Skip de-duplication for ticket messages and account lock/unlock - they should always be shown
    if (type != 'ticket_message' && type != 'account_locked' && type != 'account_unlocked') {
      try {
        final ts = (data['timestamp'] ?? '').toString();
        final idHint = (data['data']?['ticketId'] ?? data['data']?['dropId'] ?? data['userId'] ?? '').toString();
        final key = '$type|$ts|$idHint';
        
        // Clean old entries
        _recentNotificationKeys.removeWhere((_, t) => DateTime.now().difference(t) > const Duration(seconds: 20));
        
        if (_recentNotificationKeys.containsKey(key)) {
          debugPrint('🔁 Duplicate notification suppressed: $key');
          debugPrint('🔁 This notification was already shown in the last 20 seconds');
          return;
        }
        _recentNotificationKeys[key] = DateTime.now();
        debugPrint('🔔 Notification key: $key (not a duplicate, proceeding)');
      } catch (e) {
        debugPrint('⚠️ Error in de-duplication logic: $e');
      }
    } else {
      if (type == 'ticket_message') {
        debugPrint('🔔 Ticket message notification - bypassing de-duplication to ensure delivery');
      } else if (type == 'account_locked' || type == 'account_unlocked') {
        debugPrint('🔔 Account lock/unlock notification - bypassing de-duplication to ensure delivery');
      }
    }
    
    // Handle account lock/unlock notifications (same logic as WebSocket handler)
    if (data['type'] == 'account_locked' || data['type'] == 'account_unlocked') {
      debugPrint('🔒 ===== ACCOUNT LOCK/UNLOCK NOTIFICATION RECEIVED =====');
      debugPrint('🔒 Notification type: ${data['type']}');
      debugPrint('🔒 Title: ${data['title']}');
      debugPrint('🔒 Message: ${data['message']}');
      debugPrint('🔒 Full data: $data');
      
      final isLocked = data['data']?['isAccountLocked'] ?? false;
      final lockedUntilValue = data['data']?['accountLockedUntil'];
      final warningCount = data['data']?['warningCount'] ?? 0;
      
      debugPrint('🔒 Raw lockedUntil value: $lockedUntilValue (type: ${lockedUntilValue.runtimeType})');
      
      DateTime? lockedUntil;
      if (lockedUntilValue != null && 
          lockedUntilValue.toString().isNotEmpty && 
          lockedUntilValue.toString().toLowerCase() != 'null') {
        try {
          lockedUntil = DateTime.parse(lockedUntilValue.toString());
        } catch (e) {
          debugPrint('❌ Error parsing lockedUntil date: $e');
        }
      } else {
        debugPrint('🔒 lockedUntil is null/empty - this is a PERMANENT lock');
        lockedUntil = null;
      }
      
      final isPermanentlyDisabled = isLocked && lockedUntil == null;
      debugPrint('🔒 Is permanently disabled: $isPermanentlyDisabled');
      
      // Use different notification IDs for lock vs unlock to ensure both show up
      final notificationId = isLocked ? 9000 : 9001;
      final payload = isLocked ? 'account_locked' : 'account_unlocked';
      
      // Create NotificationPayload and add to notifications list
      try {
        final notification = NotificationPayload(
          type: data['type'] ?? (isLocked ? 'account_locked' : 'account_unlocked'),
          title: data['title'] ?? (isLocked ? 'Account Locked' : 'Account Unlocked'),
          message: data['message'] ?? '',
          data: data['data'],
          timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now(),
        );
        _notifications.insert(0, notification);
        if (_notifications.length > 50) {
          _notifications.removeRange(50, _notifications.length);
        }
        debugPrint('🔒 Notification added to notifications list (${isLocked ? "LOCK" : "UNLOCK"})');
      } catch (e) {
        debugPrint('⚠️ Error adding notification to list: $e');
      }
      
      debugPrint('🔒 Showing ${isLocked ? "LOCK" : "UNLOCK"} push notification with ID: $notificationId');
      debugPrint('🔒 Notification title: ${data['title']}');
      debugPrint('🔒 Notification body: ${data['message']}');
      _localNotificationService.showNotification(
        title: data['title'] ?? (isLocked ? 'Account Locked' : 'Account Unlocked'),
        body: data['message'] ?? '',
        id: notificationId,
        payload: payload,
      );
      debugPrint('🔒 Local notification service called - ${isLocked ? "LOCK" : "UNLOCK"} should now be visible as push notification');
      
      // Update badge count
      final currentUnreadCount = unreadCount;
      _localNotificationService.updateBadgeCount(currentUnreadCount);
      debugPrint('🔒 Badge count updated: $currentUnreadCount');
      
      // Call callback to update user state
      if (onAccountLockStatusUpdate != null) {
        debugPrint('🔒 Calling account lock status update callback');
        onAccountLockStatusUpdate!.call(isLocked, lockedUntil, warningCount);
      } else {
        debugPrint('⚠️ onAccountLockStatusUpdate callback is null');
      }
      
      // If permanently disabled, trigger the permanent disable callback to show dialog
      if (isPermanentlyDisabled && onAccountPermanentlyDisabled != null) {
        debugPrint('🔒 Calling permanent disable callback');
        onAccountPermanentlyDisabled!.call();
      }
      
      // Call notification received callback
      try {
        final notification = NotificationPayload(
          type: data['type'] ?? (isLocked ? 'account_locked' : 'account_unlocked'),
          title: data['title'] ?? (isLocked ? 'Account Locked' : 'Account Unlocked'),
          message: data['message'] ?? '',
          data: data['data'],
          timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now(),
        );
        onNotificationReceived?.call(notification);
        debugPrint('🔒 Notification received callback called');
      } catch (e) {
        debugPrint('⚠️ Error calling notification received callback: $e');
      }
      
      notifyListeners();
      debugPrint('🔒 ====================================================');
      return;
    }
    
    // Handle all other notification types using the existing WebSocket handler logic
    // We'll delegate to the WebSocket notification handler by simulating the same data structure
    if (data['type'] == 'account_restored') {
      _localNotificationService.showNotification(
        title: data['title'] ?? 'Account Restored',
        body: data['message'] ?? 'Your account has been restored. You can now log in again!',
        id: 9500,
        payload: 'account_restored',
      );
      return;
    }
    
    if (data['type'] == 'user_deleted') {
      _localNotificationService.showNotification(
        title: data['title'] ?? 'Account Deleted',
        body: data['message'] ?? 'Your account has been deleted by an administrator.',
        id: 9200,
        payload: 'user_deleted',
      );
      if (onAccountDeleted != null) {
        onAccountDeleted!.call();
      }
      return;
    }
    
    if (data['type'] == 'drop_censored') {
      final dropId = data['data']?['dropId']?.toString();
      final reason = data['data']?['reason']?.toString() ?? data['message']?.toString() ?? 'Censored image';
      _localNotificationService.showNotification(
        title: data['title'] ?? 'Drop Image Censored',
        body: data['message'] ?? 'Your drop image was censored',
        id: 9100,
        payload: 'drop_censored:${dropId ?? ''}',
      );
      if (dropId != null) {
        onDropCensored?.call(dropId, reason);
      }
      return;
    }
    
    if (data['type'] == 'ticket_message') {
      final ticketId = data['data']?['ticketId'] ?? '';
      final message = data['message'] ?? 'You have a new message on your support ticket';
      final messageData = data['data']?['message'];
      final sentAt = messageData?['sentAt']?.toString() ?? DateTime.now().toIso8601String();
      final messageHash = message.hashCode;
      final uniqueNotificationId = 5000 + (ticketId.hashCode + messageHash + sentAt.hashCode) % 100000;
      
      _localNotificationService.showNotification(
        title: data['title'] ?? 'New Support Message',
        body: message,
        id: uniqueNotificationId,
        payload: 'ticket:$ticketId',
      );
      
      if (onTicketMessageReceived != null && data['data'] != null) {
        onTicketMessageReceived!(ticketId, data['data']);
      }
      return;
    }
    
    if (data['type'] == 'order_approved') {
      final orderId = data['data']?['orderId']?.toString() ?? '';
      final trackingNumber = data['data']?['trackingNumber']?.toString() ?? '';
      final itemName = data['data']?['rewardItemName']?.toString() ?? 'Your order';
      
      _localNotificationService.showNotification(
        title: data['title'] ?? 'Order Approved! 🎉',
        body: data['message'] ?? 'Your order has been approved and is being prepared for shipment',
        id: 9300,
        payload: 'order_approved:$orderId',
      );
      
      if (onOrderApproved != null) {
        onOrderApproved!(orderId, itemName, trackingNumber);
      }
      return;
    }
    
    if (data['type'] == 'order_rejected') {
      final orderId = data['data']?['orderId']?.toString() ?? '';
      final rejectionReason = data['data']?['rejectionReason']?.toString() ?? '';
      final pointsAmount = data['data']?['pointsAmount']?.toString() ?? '';
      final itemName = data['data']?['rewardItemName']?.toString() ?? 'Your order';
      final pointsRefunded = int.tryParse(pointsAmount) ?? 0;
      
      _localNotificationService.showNotification(
        title: data['title'] ?? 'Order Rejected',
        body: data['message'] ?? 'Your order was rejected and points have been refunded',
        id: 9400,
        payload: 'order_rejected:$orderId',
      );
      
      if (onOrderRejected != null) {
        onOrderRejected!(orderId, itemName, rejectionReason.isEmpty ? 'No reason provided' : rejectionReason, pointsRefunded);
      }
      return;
    }

    // Fallback: for other notification types, use the generic handler
    try {
      final notification = NotificationPayload(
        type: data['type'] ?? 'unknown',
        title: data['title'] ?? 'Notification',
        message: data['message'] ?? '',
        data: data['data'],
        timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now(),
      );
      _handleNotification(notification);
    } catch (e) {
      debugPrint('❌ Error parsing notification: $e');
    }
  }

  /// Handle incoming notifications
  void _handleNotification(NotificationPayload notification) {
    debugPrint('📨 Notification received: ${notification.type} - ${notification.title}');
    
    // Handle drop status updates for real-time updates
    // Map backend notification types to standard drop status types
    String? dropStatusType;
    if (notification.type == 'drop_accepted') {
      dropStatusType = 'drop_accepted';
    } else if (notification.type == 'drop_collected' || 
               notification.type == 'drop_collected_with_rewards' || 
               notification.type == 'drop_collected_with_tier_upgrade') {
      dropStatusType = 'drop_collected';
    } else if (notification.type == 'drop_cancelled') {
      dropStatusType = 'drop_cancelled';
    } else if (notification.type == 'drop_expired') {
      dropStatusType = 'drop_expired';
    } else if (notification.type == 'drop_near_expiring') {
      // Near-expiring doesn't change drop status, just a warning notification
      dropStatusType = null; // Don't trigger status update callback
    }
    
    if (dropStatusType != null) {
      final dropId = notification.data?['dropId']?.toString();
      if (dropId != null) {
        debugPrint('🔄 Drop status update: $dropStatusType for drop $dropId (from notification type: ${notification.type})');
        onDropStatusUpdate?.call(dropId, dropStatusType, notification.data ?? {});
      } else {
        debugPrint('⚠️ Drop status update: dropId is null for notification type: ${notification.type}');
      }
    }
    
    // Add to notifications list
    _notifications.insert(0, notification);
    
    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
    
    // Check if this is a drop collected notification for household users
    // This should trigger a popup in addition to the regular notification
    if (notification.type == 'drop_collected' || 
        notification.type == 'drop_collected_with_rewards' || 
        notification.type == 'drop_collected_with_tier_upgrade') {
      debugPrint('🎉 Drop collected notification detected - triggering household popup callback');
      onDropCollectedForHousehold?.call(notification);
    }
    
    // Show local notification
    debugPrint('🔔 NotificationService: About to show local notification');
    _localNotificationService.showNotification(
      title: notification.title,
      body: notification.message,
      id: _notifications.length,);
    debugPrint('🔔 NotificationService: Local notification call completed');
    
    // Update app icon badge with actual unread count
    final currentUnreadCount = unreadCount;
    _localNotificationService.updateBadgeCount(currentUnreadCount);
    debugPrint('🔔 NotificationService: Updated badge count to $currentUnreadCount');
    
    // Call notification callback
    onNotificationReceived?.call(notification);
    
    notifyListeners();
  }

  /// Send ping to server
  void ping() {
    if (_socket != null && _isConnected) {
      _socket!.emit('ping');
    }
  }

  /// Disconnect from WebSocket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    notifyListeners();
  }

  /// Send typing indicator
  void sendTypingIndicator(String ticketId, bool isTyping) {
    if (_socket != null && _isConnected) {
      debugPrint('📝 NotificationService: Sending typing indicator for ticket $ticketId: $isTyping');
      _socket!.emit('typing_indicator', {
        'ticketId': ticketId,
        'isTyping': isTyping,
        'senderType': 'user',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Send presence indicator
  void sendPresenceIndicator(String ticketId, bool isPresent) {
    if (_socket != null && _isConnected) {
      debugPrint('👤 NotificationService: Sending presence indicator for ticket $ticketId: $isPresent');
      _socket!.emit('presence_indicator', {
        'ticketId': ticketId,
        'isPresent': isPresent,
        'senderType': 'user',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Send test notification
  void sendTestNotification() {
    if (_socket != null && _isConnected) {
      debugPrint('🧪 NotificationService: Sending test notification');
      _socket!.emit('test_notification', {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Send ping to test WebSocket connection
  void sendPing() {
    if (_socket != null && _isConnected) {
      debugPrint('🏓 Sending ping...');
      _socket!.emit('ping');
    } else {
      debugPrint('🏓 Cannot send ping - socket not connected');
    }
  }

  /// Send collector location update via WebSocket
  void sendCollectorLocationUpdate({
    required String attemptId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('collector_location_update', {
        'attemptId': attemptId,
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
      });
      debugPrint('📍 Sent collector location update: $latitude, $longitude');
    } else {
      debugPrint('⚠️ Cannot send location update: WebSocket not connected');
    }
  }

  /// Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  /// Mark notification as read
  void markAsRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications[index] = NotificationPayload(
        type: _notifications[index].type,
        title: _notifications[index].title,
        message: _notifications[index].message,
        data: {...?_notifications[index].data, 'read': true},
        timestamp: _notifications[index].timestamp,);
      
      // Update app icon badge with actual unread count
      final currentUnreadCount = unreadCount;
      _localNotificationService.updateBadgeCount(currentUnreadCount);
      debugPrint('🔔 NotificationService: Updated badge count to $currentUnreadCount after marking as read');
      
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = NotificationPayload(
        type: _notifications[i].type,
        title: _notifications[i].title,
        message: _notifications[i].message,
        data: {...?_notifications[i].data, 'read': true},
        timestamp: _notifications[i].timestamp,);
    }
    
    // Clear app icon badge since all are read
    _localNotificationService.clearBadgeCount();
    debugPrint('🔔 NotificationService: Cleared badge count after marking all as read');
    
    notifyListeners();
  }

  /// Get notification type enum
  NotificationType? getNotificationType(String type) {
    switch (type) {
      case 'user_deleted':
        return NotificationType.userDeleted;
      case 'user_banned':
        return NotificationType.userBanned;
      case 'user_unbanned':
        return NotificationType.userUnbanned;
      case 'role_changed':
        return NotificationType.roleChanged;
      case 'drop_accepted':
        return NotificationType.dropAccepted;
      case 'drop_collected':
        return NotificationType.dropCollected;
      case 'drop_cancelled':
        return NotificationType.dropCancelled;
      case 'drop_expired':
        return NotificationType.dropExpired;
      case 'drop_near_expiring':
        return NotificationType.dropNearExpiring;
      case 'new_drop_available':
        return NotificationType.newDropAvailable;
      case 'ticket_response':
        return NotificationType.ticketResponse;
      case 'ticket_status_changed':
        return NotificationType.ticketStatusChanged;
      case 'application_approved':
        return NotificationType.applicationApproved;
      case 'application_rejected':
        return NotificationType.applicationRejected;
      case 'new_training_content':
        return NotificationType.newTrainingContent;
      case 'training_completed':
        return NotificationType.trainingCompleted;
      case 'points_earned':
        return NotificationType.pointsEarned;
      case 'points_spent':
        return NotificationType.pointsSpent;
      case 'system_maintenance':
        return NotificationType.systemMaintenance;
      case 'announcement':
        return NotificationType.announcement;
      case 'connection_established':
        return NotificationType.connectionEstablished;
      case 'force_logout':
        return NotificationType.forceLogout;
    }
    return null;
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
} 