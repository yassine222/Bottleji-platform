import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/support_ticket_provider.dart';
import '../providers/chat_provider.dart';
import '../../data/models/support_ticket.dart';
import '../../../../core/api/api_client.dart';
import 'package:botleji/l10n/app_localizations.dart';

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
  bool _showHeader = true;

  // Auto-scroll to bottom function
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    _setupRealtimeChat();
    // Removed scroll listener - header visibility now only controlled by typing
    
    // Auto-scroll to bottom on load
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
        
        // Auto-scroll to bottom when new message is received
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
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
    // Don't allow sending if ticket is closed
    if (_currentTicket.status == TicketStatus.closed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).cannotSendMessageTicketClosed),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
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
      
      // Auto-scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      
    } catch (error) {
      debugPrint('❌ Error sending message: $error');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).failedToSendMessage(error.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMessageChanged(String text) {
    // Don't send typing indicator if ticket is closed
    if (_currentTicket.status == TicketStatus.closed) return;
    
    if (!_isTyping && text.isNotEmpty) {
      _startTyping();
      // Don't hide header when typing - keep drop details visible
    } else if (_isTyping && text.isEmpty) {
      _stopTyping();
      // Don't change header visibility when stopping typing
    }
  }

  void _startTyping() {
    if (_isTyping) return;
    
    setState(() {
      _isTyping = true;
    });

    final chatService = ref.read(chatServiceProvider);
    chatService.startTyping(widget.ticket.id, 'user');
    // Don't hide header - keep drop details card visible

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
    // Don't change header visibility - keep it consistent

    _typingTimer?.cancel();
  }

  // Removed auto-scroll function

  @override
  Widget build(BuildContext context) {
    // Debug: Print current ticket status on every build
    debugPrint('🔍 BUILD: Current ticket status = "${_currentTicket.status}"');
    debugPrint('🔍 BUILD: Is closed check = ${_currentTicket.status == 'closed'}');
    
    final chatService = ref.watch(chatServiceProvider);
    
    // Listen to chat service connection changes
    ref.listen(chatServiceProvider, (previous, next) {
      debugPrint('🔌 Chat service state changed: ${next.isConnected}');
    });
    
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).supportTicket),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
        children: [
          if (_showHeader && !isKeyboardOpen)
            _buildCompactHeader(),
          
          // Presence and typing indicators
          if (_adminPresent || _adminTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  if (_adminPresent)
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context).adminIsOnline, style: const TextStyle(fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  if (_adminPresent && _adminTyping) const SizedBox(width: 16),
                  if (_adminTyping)
                    Row(
                      children: [
                        const Icon(Icons.edit, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context).adminIsTyping, style: const TextStyle(fontSize: 12, color: Colors.orange)),
                      ],
                    ),
                ],
              ),
            ),
          
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(), // Reduce bounce effect
              padding: const EdgeInsets.all(16),
              itemCount: _currentTicket.messages.length,
              itemBuilder: (context, index) {
                final message = _currentTicket.messages[index];
                final isUser = message.senderType == 'user';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    // User messages on right, agent messages on left
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      // Agent avatar on the left (for agent/received messages)
                      if (!isUser) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF00695C),
                          child: const Text(
                            'A',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            // User's own messages: green on right, Received messages: gray on left
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
                      // User avatar on the right (for user's own messages)
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
          
          // Connection Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: chatService.isConnected ? Colors.green[50] : Colors.red[50],
              border: Border(
                bottom: BorderSide(
                  color: chatService.isConnected ? Colors.green[200]! : Colors.red[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: chatService.isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  chatService.isConnected ? 'Connected' : 'Connecting...',
                  style: TextStyle(
                    color: chatService.isConnected ? Colors.green[800] : Colors.red[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Status Banners
          if (_currentTicket.status == TicketStatus.resolved)
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
          
          if (_currentTicket.status == TicketStatus.closed)
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
              color: _currentTicket.status == TicketStatus.closed ? Colors.grey[200] : Colors.white,
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
                    onChanged: _currentTicket.status == TicketStatus.closed ? null : _onMessageChanged,
                    readOnly: _currentTicket.status == TicketStatus.closed,
                    decoration: InputDecoration(
                      hintText: _currentTicket.status == TicketStatus.closed 
                          ? 'Chat is disabled...' 
                          : 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: _currentTicket.status == TicketStatus.closed 
                          ? Colors.grey[300] 
                          : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _currentTicket.status == TicketStatus.closed ? null : (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _currentTicket.status == TicketStatus.closed 
                        ? Colors.grey[400] 
                        : const Color(0xFF00695C),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _currentTicket.status == TicketStatus.closed ? null : _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildCompactHeader() {
    final relatedDropId = _currentTicket.relatedDropId ?? _currentTicket.relatedCollectionId;
    if (relatedDropId == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: Colors.grey[100],
        child: Row(
          children: [
            Expanded(child: _buildTitleOnly()),
          ],
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDropDetails(relatedDropId),
      builder: (context, snapshot) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Image and Map side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image - bigger size
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[200],
                      child: (snapshot.hasData && (snapshot.data!['imageUrl']?.toString().isNotEmpty == true))
                          ? Image.network(snapshot.data!['imageUrl'], fit: BoxFit.cover)
                          : const Icon(Icons.image, color: Colors.grey, size: 40),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Map preview - bigger size
                  Expanded(
                    child: _buildCompactMapPreview(snapshot.data?['location'] as Map<String, dynamic>?),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // Bottom section: Title, item info, status badges, address
              _buildTitleOnly(),
              const SizedBox(height: 12),
              
              if (snapshot.hasData) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _miniInfoChipWithAsset('assets/icons/water-bottle.png', '${snapshot.data!['numberOfBottles'] ?? 0} bottles'),
                    _miniInfoChipWithAsset('assets/icons/can.png', '${snapshot.data!['numberOfCans'] ?? 0} cans'),
                    if (snapshot.data!['bottleType'] != null)
                      _miniInfoChip(Icons.category, snapshot.data!['bottleType'].toString()),
                    if (snapshot.data!['leaveOutside'] == true)
                      _miniInfoChip(Icons.door_front_door, 'Leave outside'),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatusBadges(),
                const SizedBox(height: 12),
                if (snapshot.data!['address'] != null && snapshot.data!['address'] != 'Address not available')
                  Text(
                    snapshot.data!['address'].toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleOnly() {
    return Text(
      _currentTicket.title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatusBadges() {
    return Row(
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
    );
  }

  Widget _miniInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _miniInfoChipWithAsset(String assetPath, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            assetPath,
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[800])),
        ],
      ),
    );
  }

  // Compact static map with pin using Google Static Maps
  Widget _buildCompactMapPreview(Map<String, dynamic>? location) {
    String _staticMapUrl(double lat, double lng) {
      const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
      final baseUrl = 'https://maps.googleapis.com/maps/api/staticmap';
      final params = {
        'center': '$lat,$lng',
        'zoom': '16',
        'size': '300x200',
        'maptype': 'roadmap',
        'markers': 'color:0x00695C|size:mid|$lat,$lng',
        'key': apiKey,
      };
      return Uri.parse(baseUrl).replace(queryParameters: params).toString();
    }

    if (location == null || location['lat'] == null || location['lng'] == null) {
      print('🚫 No location data available for map');
      return Container(
        height: 120,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.map, color: Colors.grey, size: 40),
      );
    }

    final lat = (location['lat'] as num).toDouble();
    final lng = (location['lng'] as num).toDouble();
    print('📍 Map location: lat=$lat, lng=$lng');
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(_staticMapUrl(lat, lng), height: 120, fit: BoxFit.cover),
    );
  }

  Future<Map<String, dynamic>> _fetchDropDetails(String dropId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiClientConfig.baseUrl}/dropoffs/$dropId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 Drop details fetched: $data'); // Debug log
        
        // Convert GeoJSON location to lat/lng format
        Map<String, dynamic>? locationData;
        if (data['location'] != null) {
          final location = data['location'];
          if (location['type'] == 'Point' && location['coordinates'] != null) {
            final coordinates = location['coordinates'] as List;
            if (coordinates.length >= 2) {
              // GeoJSON format: [longitude, latitude]
              locationData = {
                'lng': coordinates[0],
                'lat': coordinates[1],
              };
              print('📍 Converted location: lat=${locationData['lat']}, lng=${locationData['lng']}');
            }
          }
        }
        
        return {
          'imageUrl': data['imageUrl'],
          'numberOfBottles': data['numberOfBottles'],
          'numberOfCans': data['numberOfCans'],
          'bottleType': data['bottleType'],
          'address': data['address'] ?? 'Address not available',
          'leaveOutside': data['leaveOutside'] ?? false,
          'location': locationData, // Converted location for map
        };
      } else {
        print('❌ Failed to fetch drop details: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('❌ Error fetching drop details: $e');
      return {};
    }
  }
}
