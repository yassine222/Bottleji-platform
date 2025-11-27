import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/support_ticket.dart';
import '../providers/support_ticket_provider.dart';
import 'ticket_detail_screen_new.dart';
import 'support_categories_screen.dart';
import 'package:botleji/l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context).mySupportTickets),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter and Reload Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Filter Button
                Expanded(
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      setState(() {
                        _statusFilter = value;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.filter_list, size: 20, color: Color(0xFF00695C)),
                              const SizedBox(width: 8),
                              Text(
                                _statusFilter == 'All'
                                    ? AppLocalizations.of(context).allTickets
                                    : _statusFilter == 'Open'
                                        ? AppLocalizations.of(context).open
                                        : _statusFilter == 'InProgress'
                                            ? AppLocalizations.of(context).inProgress
                                            : _statusFilter == 'Resolved'
                                                ? AppLocalizations.of(context).resolved
                                                : AppLocalizations.of(context).closed,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'All',
                        child: Row(
                          children: [
                            const Icon(Icons.list, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context).allTickets),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'Open',
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 12, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context).open),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'InProgress',
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 12, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context).inProgress),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'Resolved',
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 12, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context).resolved),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'Closed',
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 12, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context).closed),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tickets List
          Expanded(
            child: ticketsState.when(
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.support_agent,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).noSupportTicketsYet,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).createFirstSupportTicket,
                          style: const TextStyle(color: Colors.grey),
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
                                '${AppLocalizations.of(context).created}: ${_formatDate(ticket.createdAt)}',
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
                    Text(
                      AppLocalizations.of(context).errorLoadingTickets,
                      style: const TextStyle(
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
                      child: Text(AppLocalizations.of(context).retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Support Categories screen to start the ticket creation flow
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SupportCategoriesScreen(),
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

    final l10n = AppLocalizations.of(context);
    switch (status) {
      case TicketStatus.open:
        color = Colors.blue;
        text = l10n.open;
        break;
      case TicketStatus.inProgress:
        color = Colors.orange;
        text = l10n.inProgress;
        break;
      case TicketStatus.onHold:
        color = Colors.yellow[700]!;
        text = l10n.onHold;
        break;
      case TicketStatus.resolved:
        color = Colors.green;
        text = l10n.resolved;
        break;
      case TicketStatus.closed:
        color = Colors.grey;
        text = l10n.closed;
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
    final l10n = AppLocalizations.of(context);
    Color color;
    String text;

    switch (priority) {
      case TicketPriority.low:
        color = Colors.green;
        text = l10n.lowPriority;
        break;
      case TicketPriority.medium:
        color = Colors.orange;
        text = l10n.mediumPriority;
        break;
      case TicketPriority.high:
        color = Colors.red;
        text = l10n.highPriority;
        break;
      case TicketPriority.urgent:
        color = Colors.purple;
        text = l10n.urgent;
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
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return l10n.daysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return l10n.minutesAgo(difference.inMinutes);
    } else {
      return l10n.justNow;
    }
  }
}
