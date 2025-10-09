import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/support_ticket.dart';
import '../providers/support_ticket_provider.dart';
import 'ticket_detail_screen_new.dart';
import 'create_ticket_screen.dart';

class MyTicketsScreen extends ConsumerStatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  ConsumerState<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends ConsumerState<MyTicketsScreen> {
  String _statusFilter = 'All'; // All | Closed
  @override
  void initState() {
    super.initState();
    // Load tickets when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supportTicketProvider.notifier).loadMyTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketsState = ref.watch(supportTicketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Support Tickets'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _statusFilter = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'All',
                child: Row(
                  children: [
                    Icon(Icons.list, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('All Tickets'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Open',
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Open'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'InProgress',
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('In Progress'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Resolved',
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Resolved'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Closed',
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Closed'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(supportTicketProvider.notifier).loadMyTickets();
            },
          ),
        ],
      ),
      body: ticketsState.when(
        data: (tickets) {
          final filteredTickets = _statusFilter == 'All'
              ? tickets
              : tickets.where((t) {
                  switch (_statusFilter) {
                    case 'Open':
                      return t.status == TicketStatus.open;
                    case 'InProgress':
                      return t.status == TicketStatus.inProgress;
                    case 'Resolved':
                      return t.status == TicketStatus.resolved;
                    case 'Closed':
                      return t.status == TicketStatus.closed;
                    default:
                      return true;
                  }
                }).toList();
          if (tickets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No support tickets yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first support ticket if you need help',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(supportTicketProvider.notifier).loadMyTickets();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTickets.length,
              itemBuilder: (context, index) {
                final ticket = filteredTickets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      ticket.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          ticket.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatusChip(ticket.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${_formatDate(ticket.createdAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TicketDetailScreenNew(ticket: ticket),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading tickets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(supportTicketProvider.notifier).loadMyTickets();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTicketScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF00695C),
        child: const Icon(Icons.add, color: Colors.white),
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
        color = Colors.yellow[700]!;
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
