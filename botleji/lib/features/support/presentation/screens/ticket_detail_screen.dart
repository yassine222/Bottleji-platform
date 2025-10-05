import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/support_ticket.dart';
import '../providers/support_ticket_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/chat_service.dart';
import '../providers/chat_provider.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final SupportTicket ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _messageController = TextEditingController();
  bool _isLoading = false;
  late SupportTicket _currentTicket;
  bool _isTyping = false;
  bool _adminTyping = false;
  bool _adminPresent = false;
  Timer? _typingTimer;
  final ScrollController _scrollController = ScrollController();

  // Function to scroll to bottom
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
    _refreshTicket();
    _setupRealtimeMessaging();
    
    // Auto-scroll to bottom when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _setupRealtimeMessaging() {
    // Set up real-time message callback
    final notificationService = ref.read(notificationServiceProvider);
    debugPrint('Setting up real-time messaging for ticket: ${widget.ticket.id}');
    debugPrint('🔌 WebSocket connected: ${notificationService.isConnected}');
    debugPrint('🔌 WebSocket socket exists: ${notificationService.hasSocket}');
    
    notificationService.sendPresenceIndicator(widget.ticket.id, true);
    
    // Send test notification after 2 seconds to verify WebSocket communication
    Future.delayed(const Duration(seconds: 2), () {
      debugPrint('🧪 Sending test notification...');
      notificationService.sendTestNotification();
    });
    
    // Send a ping every 5 seconds to test WebSocket connection
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        debugPrint('🏓 Sending ping to test WebSocket connection...');
        notificationService.sendPing();
      } else {
        timer.cancel();
      }
    });
    
    debugPrint('📨 Setting up onTicketMessageReceived callback');
    notificationService.onTicketMessageReceived = (ticketId, messageData) {
      debugPrint('📨 ===== CALLBACK TRIGGERED =====');
      debugPrint('📨 Received message for ticket: $ticketId');
      debugPrint('📨 Current ticket ID: ${widget.ticket.id}');
      debugPrint('📨 Message data: $messageData');
      debugPrint('📨 Message data type: ${messageData.runtimeType}');
      debugPrint('📨 Message content: ${messageData['message']}');
      debugPrint('📨 Sender type: ${messageData['senderType']}');
      
      if (ticketId == widget.ticket.id) {
        debugPrint('📨 TicketDetailScreen: Message matches current ticket, updating UI');
        
        final newMessage = TicketMessage(
          message: messageData['message'] ?? '',
          senderId: messageData['senderId'] ?? '',
          senderType: messageData['senderType'] ?? 'agent',
          sentAt: DateTime.parse(messageData['sentAt'] ?? DateTime.now().toIso8601String()),
          isInternal: messageData['isInternal'] ?? false,
        );
        
        // Check if message already exists to prevent duplicates
        final messageExists = _currentTicket.messages.any((msg) => 
          msg.message == newMessage.message && 
          msg.sentAt.difference(newMessage.sentAt).inSeconds.abs() < 5 // Within 5 seconds
        );
        
        if (messageExists) {
          debugPrint('📨 TicketDetailScreen: Message already exists, skipping duplicate');
          return;
        }
        
        debugPrint('📨 TicketDetailScreen: Adding new message to conversation');
        debugPrint('📨 TicketDetailScreen: Current messages count: ${_currentTicket.messages.length}');
        debugPrint('📨 TicketDetailScreen: New message: ${newMessage.message}');
        
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
        
        debugPrint('📨 TicketDetailScreen: setState completed, new messages count: ${_currentTicket.messages.length}');
        
        // Auto-scroll to bottom when receiving new message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
          debugPrint('📨 TicketDetailScreen: Auto-scroll completed');
        });
      } else {
        debugPrint('📨 TicketDetailScreen: Message does not match current ticket');
      }
    };

    // Set up typing indicator callback
    debugPrint('📝 TicketDetailScreen: Setting up onTypingIndicator callback');
    notificationService.onTypingIndicator = (ticketId, isTyping, senderType) {
      debugPrint('📝 TicketDetailScreen: Received typing indicator for ticket: $ticketId, current ticket: ${widget.ticket.id}');
      debugPrint('📝 TicketDetailScreen: isTyping: $isTyping, senderType: $senderType');
      if (ticketId == widget.ticket.id && senderType == 'agent') {
        debugPrint('📝 TicketDetailScreen: Updating admin typing state to: $isTyping');
        setState(() {
          _adminTyping = isTyping;
        });
      } else {
        debugPrint('📝 TicketDetailScreen: Typing indicator not for current ticket or not from agent');
      }
    };

    // Set up presence indicator callback
    debugPrint('👤 TicketDetailScreen: Setting up onPresenceIndicator callback');
    notificationService.onPresenceIndicator = (ticketId, isPresent, senderType) {
      debugPrint('👤 TicketDetailScreen: Received presence indicator for ticket: $ticketId, current ticket: ${widget.ticket.id}');
      debugPrint('👤 TicketDetailScreen: isPresent: $isPresent, senderType: $senderType');
      if (ticketId == widget.ticket.id && senderType == 'agent') {
        debugPrint('👤 TicketDetailScreen: Updating admin presence state to: $isPresent');
        setState(() {
          _adminPresent = isPresent;
        });
      } else {
        debugPrint('👤 TicketDetailScreen: Presence indicator not for current ticket or not from agent');
      }
    };
  }

  @override
  void dispose() {
    // Send presence indicator - user exited chat
    final notificationService = ref.read(notificationServiceProvider);
    notificationService.sendPresenceIndicator(widget.ticket.id, false);
    
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Optimistically update UI - show message immediately
    setState(() {
      _isLoading = true;
      final newMessage = TicketMessage(
        message: messageText,
        senderId: 'current_user', // This will be replaced by the actual response
        senderType: 'user',
        sentAt: DateTime.now(),
        isInternal: false,
      );
      
      _currentTicket = SupportTicket(
        id: _currentTicket.id,
        title: _currentTicket.title,
        description: _currentTicket.description,
        status: _currentTicket.status,
        priority: _currentTicket.priority,
        category: _currentTicket.category,
        userId: _currentTicket.userId,
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

    // Auto-scroll to bottom after adding message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      await ref.read(supportTicketProvider.notifier).addMessage(
            ticketId: widget.ticket.id,
            message: messageText,
          );

      // Stop typing indicator
      _isTyping = false;
      _typingTimer?.cancel();
      final notificationService = ref.read(notificationServiceProvider);
      notificationService.sendTypingIndicator(widget.ticket.id, false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Note: Real-time updates will be handled by WebSocket, no need to refresh
      }
    } catch (e) {
      // Remove the optimistically added message on error
      setState(() {
        _currentTicket = SupportTicket(
          id: _currentTicket.id,
          title: _currentTicket.title,
          description: _currentTicket.description,
          status: _currentTicket.status,
          priority: _currentTicket.priority,
          category: _currentTicket.category,
          userId: _currentTicket.userId,
          messages: _currentTicket.messages.take(_currentTicket.messages.length - 1).toList(),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onMessageChanged(String text) {
    // Send typing indicator
    if (!_isTyping) {
      _isTyping = true;
      final notificationService = ref.read(notificationServiceProvider);
      notificationService.sendTypingIndicator(widget.ticket.id, true);
    }

    // Clear existing timer
    _typingTimer?.cancel();

    // Set new timer to stop typing indicator
    _typingTimer = Timer(const Duration(seconds: 1), () {
      _isTyping = false;
      final notificationService = ref.read(notificationServiceProvider);
      notificationService.sendTypingIndicator(widget.ticket.id, false);
    });
  }

  Future<void> _refreshTicket() async {
    try {
      final ticket = await ref.read(supportTicketProvider.notifier)
          .getTicketById(widget.ticket.id);
      if (mounted) {
        setState(() {
          _currentTicket = ticket;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot reach the server. Please ensure the backend is running.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInputBar() {
    if (_currentTicket.status == TicketStatus.closed) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  onChanged: _onMessageChanged,
                ),
                
                // Typing and Presence Indicators
                if (_adminPresent || _adminTyping)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        if (_adminPresent)
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Admin is online',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        if (_adminPresent && _adminTyping) const SizedBox(width: 8),
                        if (_adminTyping)
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Admin is typing...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _sendMessage,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF00695C),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${_currentTicket.id.substring(0, 8)}'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Ticket Info Header
          Container(
            width: double.infinity,
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
                Row(
                  children: [
                    _buildStatusChip(_currentTicket.status),
                    const SizedBox(width: 8),
                    _buildPriorityChip(_currentTicket.priority),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: ${_currentTicket.categoryDisplayName}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${_formatDate(_currentTicket.createdAt)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (_currentTicket.assignedTo != null) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Assigned to: Support Agent',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
  
      


          // Messages List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshTicket,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _currentTicket.messages.length,
                itemBuilder: (context, index) {
                  final message = _currentTicket.messages[index];
                  final isUser = message.senderType == 'user';
                  final isFirstMessage = index == 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        // Related item cards (only show in first message)
                        if (isFirstMessage && (
                          _currentTicket.relatedDropId != null ||
                          _currentTicket.relatedCollectionId != null ||
                          _currentTicket.relatedApplicationId != null
                        ))
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                if (_currentTicket.relatedDropId != null)
                                  _buildRelatedDropCard(_currentTicket.relatedDropId!),
                                if (_currentTicket.relatedCollectionId != null)
                                  _buildRelatedCollectionCard(_currentTicket.relatedCollectionId!),
                                if (_currentTicket.relatedApplicationId != null)
                                  _buildRelatedApplicationCard(_currentTicket.relatedApplicationId!),
                              ],
                            ),
                          ),

                        // Message bubble
                        Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF00695C),
                                child: const Icon(
                                  Icons.support_agent,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFF00695C)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.message,
                                      style: TextStyle(
                                        color: isUser ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(message.sentAt),
                                      style: TextStyle(
                                        color: isUser
                                            ? Colors.white70
                                            : Colors.grey[600],
                                        fontSize: 12,
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
                                backgroundColor: Colors.grey[300],
                                child: const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Message Input
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TicketStatus status) {
    Color color;
    String text;

    switch (status) {
      case TicketStatus.open:
        color = Colors.blue;
        text = 'Open';
        break;
      case TicketStatus.inProgress:
        color = Colors.orange;
        text = 'In Progress';
        break;
      case TicketStatus.onHold:
        color = Colors.yellow;
        text = 'On Hold';
        break;
      case TicketStatus.resolved:
        color = Colors.green;
        text = 'Resolved';
        break;
      case TicketStatus.closed:
        color = Colors.grey;
        text = 'Closed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(TicketPriority priority) {
    Color color;
    String text;

    switch (priority) {
      case TicketPriority.low:
        color = Colors.green;
        text = 'Low';
        break;
      case TicketPriority.medium:
        color = Colors.orange;
        text = 'Medium';
        break;
      case TicketPriority.high:
        color = Colors.red;
        text = 'High';
        break;
      case TicketPriority.urgent:
        color = Colors.purple;
        text = 'Urgent';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRelatedDropCard(String dropId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDropDetails(dropId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_drink, color: Colors.green, size: 20),
                SizedBox(width: 12),
                Text('Loading drop details...', style: TextStyle(color: Colors.green)),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_drink, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Drop details unavailable. Check your connection or that the backend is running. (ID: ${dropId.substring(0, 8)}...)',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        final drop = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              // Drop details (left)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_drink, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Drop Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${drop['numberOfBottles'] ?? 0} bottles • ${drop['numberOfCans'] ?? 0} cans',
                      style: TextStyle(color: Colors.green[600], fontSize: 12),
                    ),
                    if (drop['bottleType'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Type: ${drop['bottleType']}',
                        style: TextStyle(color: Colors.green[600], fontSize: 12),
                      ),
                    ],
                    if (drop['address'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        drop['address'],
                        style: TextStyle(color: Colors.green[600], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Drop image (right, fixed size to avoid stretching)
              if (drop['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.network(
                      drop['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_drink, color: Colors.green, size: 28),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_drink, color: Colors.green, size: 28),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRelatedCollectionCard(String collectionId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDropDetails(collectionId), // Treat collectionId as dropoffId
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.collections, color: Colors.blue, size: 20),
                SizedBox(width: 12),
                Text('Loading collection details...', style: TextStyle(color: Colors.blue)),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.collections, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Collection details unavailable. Check your connection or that the backend is running. (ID: ${collectionId.substring(0, 8)}...)',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        final drop = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              // Drop image
              if (drop['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    drop['imageUrl'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.collections, color: Colors.blue, size: 24),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.collections, color: Colors.blue, size: 24),
                ),
              
              const SizedBox(width: 12),
              
              // Collection details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.collections, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Collection Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${drop['numberOfBottles'] ?? 0} bottles • ${drop['numberOfCans'] ?? 0} cans',
                      style: TextStyle(color: Colors.blue[600], fontSize: 12),
                    ),
                    if (drop['bottleType'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Type: ${drop['bottleType']}',
                        style: TextStyle(color: Colors.blue[600], fontSize: 12),
                      ),
                    ],
                    if (drop['address'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        drop['address'],
                        style: TextStyle(color: Colors.blue[600], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRelatedApplicationCard(String applicationId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchApplicationDetails(applicationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.assignment, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Text('Loading application details...', style: TextStyle(color: Colors.orange)),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Application details unavailable. Check your connection or that the backend is running. (ID: ${applicationId.substring(0, 8)}...)',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        final application = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment, color: Colors.orange, size: 24),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Application Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${application['status'] ?? 'Unknown'}',
                      style: TextStyle(color: Colors.orange[600], fontSize: 12),
                    ),
                    if (application['submittedAt'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Submitted: ${_formatDate(DateTime.parse(application['submittedAt']))}',
                        style: TextStyle(color: Colors.orange[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchDropDetails(String dropId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/dropoffs/$dropId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'imageUrl': data['imageUrl'],
          'numberOfBottles': data['numberOfBottles'],
          'numberOfCans': data['numberOfCans'],
          'bottleType': data['bottleType'],
          'address': data['address'] ?? 'Address not available',
        };
      }
    } catch (e) {
      print('Error fetching drop details: $e');
    }
    return {};
  }


  Future<Map<String, dynamic>> _fetchApplicationDetails(String applicationId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/collector-applications/$applicationId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'status': data['status'],
          'submittedAt': data['submittedAt'],
        };
      }
    } catch (e) {
      print('Error fetching application details: $e');
    }
    return {};
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
