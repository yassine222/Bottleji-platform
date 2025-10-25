import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/server_config.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentTicketId;
  String? _currentSenderType;
  
  // Connection retry logic
  int _retryCount = 0;
  static const int _maxRetries = 5;
  Timer? _retryTimer;
  bool _isConnecting = false;
  
  // Callbacks
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onTypingIndicator;
  Function(Map<String, dynamic>)? onUserJoined;
  Function(Map<String, dynamic>)? onUserLeft;
  Function(Map<String, dynamic>)? onStatusUpdate;
  Function(Map<String, dynamic>)? onPresenceIndicator;

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get currentUserId => _currentUserId;
  String? get currentTicketId => _currentTicketId;
  String? get currentSenderType => _currentSenderType;

  /// Initialize chat service
  Future<void> initialize() async {
    debugPrint('🔌 ChatService: Initializing...');
    // Don't auto-connect, wait for explicit connect call
  }

  /// Connect to chat WebSocket with retry logic
  Future<void> connect() async {
    if (_isConnecting) {
      debugPrint('🔌 ChatService: Already connecting, skipping...');
      return;
    }

    _isConnecting = true;
    notifyListeners();

    try {
      debugPrint('🔌 ChatService: Connecting to chat WebSocket...');
      
      // Get token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null || token.isEmpty) {
        debugPrint('❌ ChatService: No auth token found');
        _isConnecting = false;
        notifyListeners();
        return;
      }

      // Disconnect any existing connection
      if (_socket != null) {
        debugPrint('🔌 ChatService: Disconnecting existing socket...');
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }

      // Initialize Socket.IO client
      final socketUrl = ServerConfig.apiBaseUrlSync;
      debugPrint('🔌 ChatService: Connecting to: $socketUrl/chat');
      debugPrint('🔌 ChatService: Token available: ${token.isNotEmpty}');
      _socket = IO.io('$socketUrl/chat', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'timeout': 15000,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'auth': {
          'token': token,
        },
      });

      _setupEventListeners();
      
      // Connect manually
      debugPrint('🔌 ChatService: Attempting to connect...');
      _socket!.connect();
      
    } catch (error) {
      debugPrint('❌ ChatService: Connection error: $error');
      _isConnecting = false;
      notifyListeners();
      _scheduleRetry();
    }
  }

  /// Schedule retry connection with exponential backoff
  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) {
      debugPrint('❌ ChatService: Max retry attempts reached, giving up');
      _isConnecting = false;
      notifyListeners();
      return;
    }

    _retryCount++;
    final delay = Duration(milliseconds: math.min(1000 * math.pow(2, _retryCount).toInt(), 10000));
    debugPrint('🔄 ChatService: Retrying connection in ${delay.inMilliseconds}ms (attempt $_retryCount/$_maxRetries)');
    
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      connect();
    });
  }

  /// Setup WebSocket event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      debugPrint('✅ ChatService: Connected to chat server');
      _isConnected = true;
      _isConnecting = false;
      _retryCount = 0; // Reset retry count on successful connection
      _retryTimer?.cancel();
      notifyListeners();
    });

    _socket!.onDisconnect((reason) {
      debugPrint('❌ ChatService: Disconnected from chat server. Reason: $reason');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      
      // Auto-reconnect on disconnect (unless it's a manual disconnect)
      if (reason != 'io client disconnect') {
        debugPrint('🔄 ChatService: Auto-reconnecting after disconnect...');
        _scheduleRetry();
      }
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ ChatService: Connection error: $error');
      debugPrint('❌ ChatService: Error type: ${error.runtimeType}');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      _scheduleRetry();
    });

    _socket!.onReconnect((attemptNumber) {
      debugPrint('✅ ChatService: Reconnected after $attemptNumber attempts');
      _isConnected = true;
      _isConnecting = false;
      _retryCount = 0;
      notifyListeners();
    });

    _socket!.onReconnectError((error) {
      debugPrint('❌ ChatService: Reconnection error: $error');
    });

    _socket!.onReconnectFailed((_) {
      debugPrint('❌ ChatService: Reconnection failed, will retry manually');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      _scheduleRetry();
    });

    // Chat events
    _socket!.on('chat_connected', (data) {
      debugPrint('🔌 ChatService: Chat connection confirmed: $data');
      _currentUserId = data['userId'];
    });

    _socket!.on('new_message', (data) {
      debugPrint('📨 ChatService: New message received: $data');
      onMessageReceived?.call(data);
    });
    
    _socket!.on('status_update', (data) {
      debugPrint('📊 ChatService: Status update received: $data');
      onStatusUpdate?.call(data);
    });

    _socket!.on('typing_indicator', (data) {
      debugPrint('⌨️ ChatService: Typing indicator received: $data');
      onTypingIndicator?.call(data);
    });

    _socket!.on('user_joined', (data) {
      debugPrint('👤 ChatService: User joined: $data');
      onUserJoined?.call(data);
    });

    _socket!.on('user_left', (data) {
      debugPrint('👋 ChatService: User left: $data');
      onUserLeft?.call(data);
    });

    // Catch-all listener for debugging
    _socket!.onAny((event, data) {
      debugPrint('🔍 ChatService: Received event: $event');
      if (data != null) {
        debugPrint('🔍 ChatService: Event data: $data');
      }
    });
  }

  /// Join a ticket room with retry logic
  Future<void> joinTicket(String ticketId, String senderType) async {
    if (_socket == null || !_isConnected) {
      debugPrint('❌ ChatService: Cannot join ticket - not connected');
      // Try to connect first
      await connect();
      // Wait a bit for connection to establish
      await Future.delayed(Duration(milliseconds: 1000));
      if (_socket == null || !_isConnected) {
        debugPrint('❌ ChatService: Still not connected after retry, cannot join ticket');
        return;
      }
    }

    debugPrint('👤 ChatService: Joining ticket $ticketId as $senderType');
    
    _currentTicketId = ticketId;
    _currentSenderType = senderType;
    
    _socket!.emit('join_ticket', {
      'ticketId': ticketId,
      'senderType': senderType,
    });

    // Send presence indicator
    _socket!.emit('presence_indicator', {
      'ticketId': ticketId,
      'isPresent': true,
      'senderType': senderType,
    });

    debugPrint('👤 ChatService: Successfully joined ticket room and sent presence indicator');
  }

  /// Leave a ticket room
  Future<void> leaveTicket(String ticketId, String senderType) async {
    if (_socket == null || !_isConnected) {
      debugPrint('❌ ChatService: Cannot leave ticket - not connected');
      return;
    }

    debugPrint('👋 ChatService: Leaving ticket $ticketId');
    
    _socket!.emit('leave_ticket', {
      'ticketId': ticketId,
      'senderType': senderType,
    });

    // Send presence indicator that user left
    _socket!.emit('presence_indicator', {
      'ticketId': ticketId,
      'isPresent': false,
      'senderType': senderType,
    });
    
    _currentTicketId = null;
    _currentSenderType = null;
    
    debugPrint('👋 ChatService: Successfully left ticket room and sent presence indicator');
  }

  /// Send a message
  Future<void> sendMessage(String ticketId, String message, String senderType) async {
    if (_socket == null || !_isConnected) {
      debugPrint('❌ ChatService: Cannot send message - not connected');
      return;
    }

    debugPrint('📤 ChatService: Sending message to ticket $ticketId: $message');
    
    _socket!.emit('send_message', {
      'ticketId': ticketId,
      'message': message,
      'senderType': senderType,
    });
  }

  /// Start typing indicator
  Future<void> startTyping(String ticketId, String senderType) async {
    if (_socket == null || !_isConnected) {
      return;
    }

    _socket!.emit('typing_start', {
      'ticketId': ticketId,
      'senderType': senderType,
    });
  }

  /// Stop typing indicator
  Future<void> stopTyping(String ticketId, String senderType) async {
    if (_socket == null || !_isConnected) {
      return;
    }

    _socket!.emit('typing_stop', {
      'ticketId': ticketId,
      'senderType': senderType,
    });
  }

  /// Disconnect from chat
  void disconnect() {
    _retryTimer?.cancel();
    _retryTimer = null;
    
    if (_socket != null) {
      debugPrint('🔌 ChatService: Disconnecting...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _isConnecting = false;
    _retryCount = 0;
    _currentUserId = null;
    _currentTicketId = null;
    _currentSenderType = null;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
