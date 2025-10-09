import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/support_ticket_provider.dart';
import '../providers/chat_provider.dart';
import '../../data/models/support_ticket.dart';

class TicketDetailScreenNew extends ConsumerStatefulWidget {
  final SupportTicket ticket;

  const TicketDetailScreenNew({super.key, required this.ticket});

  @override
  ConsumerState<TicketDetailScreenNew> createState() => _TicketDetailScreenNewState();
}

class _TicketDetailScreenNewState extends ConsumerState<TicketDetailScreenNew> {
  late SupportTicket _currentTicket;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  Timer? _typingTimer;
  bool _adminTyping = false;
  bool _adminPresent = false;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    _setupRealtimeChat();
    
    // Auto-scroll to bottom when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    
    // Leave chat room
    final chatService = ref.read(chatServiceProvider);
    chatService.leaveTicket(widget.ticket.id, 'user');
    
    super.dispose();
  }

  void _setupRealtimeChat() {
    final chatService = ref.read(chatServiceProvider);
    debugPrint('🔌 Setting up real-time chat for ticket: ${widget.ticket.id}');
    debugPrint('🔌 Chat service connection status: ${chatService.isConnected}');
    
    // Ensure connection and join room
    _ensureConnectionAndJoin();
    
    // Set up status update callback
    chatService.onStatusUpdate = (statusData) {
      debugPrint('📊 ===== STATUS UPDATE RECEIVED =====');
      debugPrint('📊 Status data: $statusData');
      
      if (statusData['ticketId'] == widget.ticket.id) {
        debugPrint('📊 Status update matches current ticket, updating UI');
        
        final newStatus = statusData['status'] ?? _currentTicket.status;
        debugPrint('📊 Updating ticket status to: $newStatus');
        
        setState(() {
          _currentTicket = SupportTicket(
            id: _currentTicket.id,
            title: _currentTicket.title,
            description: _currentTicket.description,
            status: newStatus,
            priority: _currentTicket.priority,
            category: _currentTicket.category,
            userId: _currentTicket.userId,
            assignedTo: _currentTicket.assignedTo,
            messages: _currentTicket.messages,
            attachments: _currentTicket.attachments,
            internalNotes: _currentTicket.internalNotes,
            createdAt: _currentTicket.createdAt,
            updatedAt: DateTime.now(),
            lastUpdatedBy: _currentTicket.lastUpdatedBy,
            relatedDropId: _currentTicket.relatedDropId,
            relatedCollectionId: _currentTicket.relatedCollectionId,
            relatedApplicationId: _currentTicket.relatedApplicationId,
            contextMetadata: _currentTicket.contextMetadata,
            location: _currentTicket.location,
          );
        });
        
        debugPrint('📊 Ticket status updated successfully in UI');
      }
    };
    
    // Set up message callback
    chatService.onMessageReceived = (messageData) {
      debugPrint('📨 ===== NEW MESSAGE RECEIVED =====');
      debugPrint('📨 Message data: $messageData');
      
      if (messageData['ticketId'] == widget.ticket.id) {
        debugPrint('📨 Message matches current ticket, updating UI');
        
        final newMessage = TicketMessage(
          message: messageData['message'] ?? '',
          senderId: messageData['senderId'] ?? '',
          senderType: messageData['senderType'] ?? 'agent',
          sentAt: DateTime.parse(messageData['sentAt'] ?? DateTime.now().toIso8601String()),
          isInternal: messageData['isInternal'] ?? false,
        );
        
        // Check if message already exists to prevent duplicates
        // Use multiple criteria to ensure we don't miss duplicates
        final messageExists = _currentTicket.messages.any((msg) => 
          msg.message == newMessage.message && 
          msg.senderId == newMessage.senderId &&
          msg.senderType == newMessage.senderType &&
          msg.sentAt.difference(newMessage.sentAt).inSeconds.abs() < 10
        );
        
        if (messageExists) {
          debugPrint('📨 Message already exists, skipping duplicate');
          return;
        }
        
        debugPrint('📨 Adding new message to conversation');
        
        // Update the current ticket with the new message
        setState(() {
          _currentTicket = SupportTicket(
            id: _currentTicket.id,
            title: _currentTicket.title,
            description: _currentTicket.description,
            status: _currentTicket.status,
            priority: _currentTicket.priority,
            category: _currentTicket.category,
            userId: _currentTicket.userId,
            assignedTo: _currentTicket.assignedTo,
            messages: [..._currentTicket.messages, newMessage],
            attachments: _currentTicket.attachments,
            internalNotes: _currentTicket.internalNotes,
            createdAt: _currentTicket.createdAt,
            updatedAt: DateTime.now(),
            lastUpdatedBy: _currentTicket.lastUpdatedBy,
            relatedDropId: _currentTicket.relatedDropId,
            relatedCollectionId: _currentTicket.relatedCollectionId,
            relatedApplicationId: _currentTicket.relatedApplicationId,
            contextMetadata: _currentTicket.contextMetadata,
            location: _currentTicket.location,
          );
        });
        
        // Auto-scroll to bottom when receiving new message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
          debugPrint('📨 Auto-scrolled to bottom after receiving message');
        });
      }
    };

    // Set up typing indicator callback
    chatService.onTypingIndicator = (typingData) {
      debugPrint('⌨️ Typing indicator received: $typingData');
      
      if (typingData['ticketId'] == widget.ticket.id && typingData['senderType'] == 'agent') {
        setState(() {
          _adminTyping = typingData['isTyping'] ?? false;
        });
      }
    };

    // Set up presence indicator callback
    chatService.onUserJoined = (userData) {
      debugPrint('👤 User joined: $userData');
      
      if (userData['ticketId'] == widget.ticket.id && userData['senderType'] == 'agent') {
        setState(() {
          _adminPresent = true;
        });
      }
    };

    chatService.onUserLeft = (userData) {
      debugPrint('👋 User left: $userData');
      
      if (userData['ticketId'] == widget.ticket.id && userData['senderType'] == 'agent') {
        setState(() {
          _adminPresent = false;
          _adminTyping = false;
        });
      }
    };
  }

  void _ensureConnectionAndJoin() async {
    final chatService = ref.read(chatServiceProvider);
    debugPrint('🔌 Ensuring WebSocket connection for ticket: ${widget.ticket.id}');
    
    // If already connected, just join the room
    if (chatService.isConnected) {
      debugPrint('🔌 Already connected, joining ticket room...');
      await chatService.joinTicket(widget.ticket.id, 'user');
      return;
    }
    
    // If connecting, wait for it to complete
    if (chatService.isConnecting) {
      debugPrint('🔌 Connection in progress, waiting...');
      // Wait for connection to complete
      int attempts = 0;
      while (chatService.isConnecting && attempts < 20) { // Max 10 seconds
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
      
      if (chatService.isConnected) {
        debugPrint('🔌 Connection completed, joining ticket room...');
        await chatService.joinTicket(widget.ticket.id, 'user');
        return;
      }
    }
    
    // If not connected and not connecting, establish connection
    debugPrint('🔌 Not connected, establishing connection...');
    try {
      await chatService.connect();
      
      // Wait for connection to be established
      int attempts = 0;
      while (!chatService.isConnected && attempts < 20) { // Max 10 seconds
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
      
      if (chatService.isConnected) {
        debugPrint('🔌 Connection established, joining ticket room...');
        await chatService.joinTicket(widget.ticket.id, 'user');
      } else {
        debugPrint('❌ Failed to establish connection after 10 seconds');
      }
    } catch (error) {
      debugPrint('❌ Error establishing connection: $error');
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    // Stop typing indicator
    _stopTyping();

    try {
      // Send message via API to save to database
      final supportTicketNotifier = ref.read(supportTicketProvider.notifier);
      await supportTicketNotifier.addMessage(ticketId: widget.ticket.id, message: message, isInternal: false);
      
      debugPrint('📤 Message sent via API successfully');
      
      // Don't refresh the ticket data here - let the WebSocket callback handle the UI update
      // This prevents duplicate messages from appearing in the chat
      
    } catch (error) {
      debugPrint('❌ Error sending message: $error');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMessageChanged(String text) {
    if (!_isTyping && text.isNotEmpty) {
      _startTyping();
    } else if (_isTyping && text.isEmpty) {
      _stopTyping();
    }
  }

  void _startTyping() {
    if (_isTyping) return;
    
    setState(() {
      _isTyping = true;
    });

    final chatService = ref.read(chatServiceProvider);
    chatService.startTyping(widget.ticket.id, 'user');

    // Set timer to stop typing after 2 seconds of inactivity
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _stopTyping();
    });
  }

  void _stopTyping() {
    if (!_isTyping) return;
    
    setState(() {
      _isTyping = false;
    });

    final chatService = ref.read(chatServiceProvider);
    chatService.stopTyping(widget.ticket.id, 'user');

    _typingTimer?.cancel();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          debugPrint('📜 Scrolled to bottom - maxScrollExtent: ${_scrollController.position.maxScrollExtent}');
        }
      });
    } else {
      debugPrint('📜 ScrollController has no clients yet');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ref.watch(chatServiceProvider);
    
    // Listen to chat service connection changes
    ref.listen(chatServiceProvider, (previous, next) {
      debugPrint('🔌 Chat service state changed: ${next.isConnected}');
    });
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Support Ticket #${widget.ticket.id.substring(0, 8)}'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  chatService.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: chatService.isConnected ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  chatService.isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: chatService.isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ticket info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentTicket.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentTicket.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_currentTicket.status.toString().split('.').last),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _currentTicket.status.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(_currentTicket.priority.toString().split('.').last),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _currentTicket.priority.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Presence and typing indicators
          if (_adminPresent || _adminTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  if (_adminPresent)
                    const Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Admin is online', style: TextStyle(fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  if (_adminPresent && _adminTyping) const SizedBox(width: 16),
                  if (_adminTyping)
                    const Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('Admin is typing...', style: TextStyle(fontSize: 12, color: Colors.orange)),
                      ],
                    ),
                ],
              ),
            ),
          
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _currentTicket.messages.length,
              itemBuilder: (context, index) {
                final message = _currentTicket.messages[index];
                final isUser = message.senderType == 'user';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF00695C),
                          child: Text(
                            'A',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFF00695C) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.message,
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(message.sentAt),
                                style: TextStyle(
                                  color: isUser ? Colors.white70 : Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[400],
                          child: const Text(
                            'U',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Status Banners
          if (_currentTicket.status == 'resolved')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border(
                  left: BorderSide(color: Colors.green[400]!, width: 4),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✅ This ticket is marked as resolved.',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'You can still reply. Your message will automatically reopen the ticket.',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          if (_currentTicket.status == 'closed')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  left: BorderSide(color: Colors.grey[400]!, width: 4),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔒 This ticket is closed.',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chat is disabled. Please create a new ticket for new issues.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentTicket.status == 'closed' ? Colors.grey[200] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _onMessageChanged,
                    enabled: _currentTicket.status != 'closed',
                    decoration: InputDecoration(
                      hintText: _currentTicket.status == 'closed' 
                          ? 'Chat is disabled...' 
                          : 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: _currentTicket.status == 'closed' 
                          ? Colors.grey[300] 
                          : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_currentTicket.status != 'closed') ? (_) => _sendMessage() : null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _currentTicket.status == 'closed' 
                        ? Colors.grey[400] 
                        : const Color(0xFF00695C),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _currentTicket.status == 'closed' ? null : _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
