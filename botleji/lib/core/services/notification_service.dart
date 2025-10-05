import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _namespace = '/notifications';
  
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  final List<NotificationPayload> _notifications = [];
  final LocalNotificationService _localNotificationService = LocalNotificationService();
  
  // Getters
  bool get isConnected => _isConnected;
  List<NotificationPayload> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.data?['read'] ?? false).length;
  bool get hasSocket => _socket != null;

  // Callbacks
  Function(String reason)? onForceLogout;
  Function(NotificationPayload)? onNotificationReceived;
  Function()? onConnectionEstablished;
  Function()? onConnectionLost;
  Function(String status, Map<String, dynamic> data)? onApplicationStatusUpdate;
  Function(String ticketId, Map<String, dynamic> message)? onTicketMessageReceived;
  Function(String ticketId, bool isTyping, String senderType)? onTypingIndicator;
  Function(String ticketId, bool isPresent, String senderType)? onPresenceIndicator;

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
      final socketUrl = ServerConfig.socketUrl;
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
        debugPrint('🔔 Notification received: ${data['type']}');
        debugPrint('🔔 Full notification data: $data');
        
        // Handle ticket message notifications
        if (data['type'] == 'ticket_message') {
          debugPrint('📨 NotificationService: Ticket message notification received!');
          final ticketId = data['data']?['ticketId'] ?? '';
          final message = data['message'] ?? 'You have a new message on your support ticket';
          debugPrint('📨 NotificationService: Ticket ID: $ticketId');
          debugPrint('📨 NotificationService: Message: $message');
          debugPrint('📨 NotificationService: Full data: ${data['data']}');
          debugPrint('📨 NotificationService: Message data: ${data['data']?['message']}');
          
          // Show push notification
          _localNotificationService.showNotification(
            title: data['title'] ?? 'New Support Message',
            body: message,
            id: 5000 + ticketId.hashCode % 1000, // Unique ID for each ticket
            payload: 'ticket:$ticketId',
          );
          
          // Call the ticket message callback for real-time updates
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
        } else {
          debugPrint('📨 NotificationService: Received notification of type: ${data['type']} (not ticket_message)');
        }
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
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('✅ Connected to notifications server');
      
      // Don't automatically request permissions - let user decide
      // _requestPermissionAndShowWelcome(); // REMOVED - This was causing the issue!
      
      onConnectionEstablished?.call();
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('❌ Disconnected from notifications server');
      onConnectionLost?.call();
      notifyListeners();
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ Connection error: $error');
      _isConnected = false;
      notifyListeners();
    });

    // Notification events
    _socket!.on('notification', (data) {
      try {
        final notification = NotificationPayload.fromJson(data);
        _handleNotification(notification);
      } catch (e) {
        debugPrint('❌ Error parsing notification: $e');
      }
    });

    // Force logout event
    _socket!.on('force_logout', (data) {
      final reason = data['reason'] ?? 'Session terminated';
      debugPrint('🚪 Force logout received: $reason');
      
      // Show force logout notification
      _localNotificationService.showForceLogoutNotification(reason: reason);
      
      onForceLogout?.call(reason);
    });

    // Ping/Pong for connection health
    _socket!.on('pong', (data) {
      debugPrint('🏓 Pong received: ${data['timestamp']}');
    });
  }

  /// Handle incoming notifications
  void _handleNotification(NotificationPayload notification) {
    debugPrint('📨 Notification received: ${notification.type} - ${notification.title}');
    
    // Add to notifications list
    _notifications.insert(0, notification);
    
    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
    
    // Show local notification
    debugPrint('🔔 NotificationService: About to show local notification');
    _localNotificationService.showNotification(
      title: notification.title,
      body: notification.message,
      id: _notifications.length,);
    debugPrint('🔔 NotificationService: Local notification call completed');
    
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
        return null;
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
} 