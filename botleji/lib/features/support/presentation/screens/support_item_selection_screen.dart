import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/drops/controllers/drops_controller.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'package:botleji/features/collector/controllers/collector_application_controller.dart';
import 'package:botleji/features/support/presentation/screens/create_ticket_screen.dart';
import 'package:botleji/features/support/presentation/providers/support_ticket_provider.dart';
import 'package:botleji/features/stats/data/models/collector_stats.dart';
import 'package:botleji/features/stats/data/repositories/stats_repository.dart';
import 'package:botleji/features/stats/data/datasources/stats_api_client.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/core/api/api_client.dart';
import 'package:botleji/core/utils/json_converters.dart';

const appGreenColor = Color(0xFF00695C);

class SupportItemSelectionScreen extends ConsumerStatefulWidget {
  final String category;
  final String categoryTitle;

  const SupportItemSelectionScreen({
    super.key,
    required this.category,
    required this.categoryTitle,
  });

  @override
  ConsumerState<SupportItemSelectionScreen> createState() =>
      _SupportItemSelectionScreenState();
}

class _SupportItemSelectionScreenState
    extends ConsumerState<SupportItemSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      authState.whenData((user) async {
        if (user != null) {
          switch (widget.category) {
            case 'applications':
              await ref
                  .read(collectorApplicationControllerProvider.notifier)
                  .getMyApplication();
              break;
            default:
              break;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appGreenColor.withOpacity(0.1),
                        appGreenColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: appGreenColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: appGreenColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(),
                          color: appGreenColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select an item to get help',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: appGreenColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getCategoryDescription(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Items List
                _buildItemsList(),
                const SizedBox(height: 24),

                // General Support Option
                _buildGeneralSupportOption(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    switch (widget.category) {
      case 'drops':
        return _buildDropsList();
      case 'applications':
        return _buildApplicationsList();
      case 'payments':
        return _buildPaymentsList();
      default:
        return _buildGeneralOptions();
    }
  }

  Widget _buildDropsList() {
    final authState = ref.watch(authNotifierProvider);
    final userMode = ref.watch(userModeControllerProvider);

    return authState.when(
      data: (user) {
        if (user?.id == null) {
          return _buildEmptyState(
            icon: Icons.error,
            title: 'Authentication Error',
            description: 'Please log in again to view your items.',
          );
        }

        return userMode.when(
          data: (mode) {
            if (mode == UserMode.collector) {
              // Show collections for collectors
              return _buildCollectionsList(user?.id ?? '');
            } else {
              // Show drops for households
              return _buildUserDropsList(user?.id ?? '');
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildCollectionsList(String userId) {
    return FutureBuilder<CollectorHistory>(
      future: _getCollectorHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading collections: ${snapshot.error}'));
        }

        final history = snapshot.data;
        if (history == null || history.interactions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inventory_2,
            title: 'No Collections Found',
            description: 'You don\'t have any collections to report issues for.',
          );
        }

        // Group interactions by drop (same logic as history page)
        final groupedInteractions = _groupInteractionsByDrop(history.interactions);
        
        // Filter to last 3 days and exclude collections with existing tickets
        final cutoff = DateTime.now().subtract(const Duration(days: 3));
        final filteredCollections = groupedInteractions.where((interactions) {
          // Check if any interaction in the group is within 3 days
          final hasRecentInteraction = interactions.any((interaction) => 
              interaction.interactionTime.isAfter(cutoff));
          return hasRecentInteraction;
        }).toList();
        
        // Sort by most recent interaction
        filteredCollections.sort((a, b) {
          final aLatest = a.map((i) => i.interactionTime).reduce((a, b) => a.isAfter(b) ? a : b);
          final bLatest = b.map((i) => i.interactionTime).reduce((a, b) => a.isAfter(b) ? a : b);
          return bLatest.compareTo(aLatest);
        });

        print('🔍 Support: Found ${groupedInteractions.length} total collections, ${filteredCollections.length} available for support (last 3 days)');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Collections (Last 3 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appGreenColor,
              ),
            ),
            const SizedBox(height: 16),
            ...filteredCollections.map((interactions) => _buildCollectionCard(interactions)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildUserDropsList(String userId) {
    return FutureBuilder<List<Drop>>(
      future: _getUserDropsForSupport(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading drops: ${snapshot.error}'));
        }

        final drops = snapshot.data ?? [];
        
        if (drops.isEmpty) {
          return _buildEmptyState(
            icon: Icons.local_drink,
            title: 'No Drops Found',
            description: 'You don\'t have any drops to report issues for.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Drops (Last 3 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appGreenColor,
              ),
            ),
            const SizedBox(height: 16),
            ...drops.map((drop) => _buildDropCard(drop)).toList(),
          ],
        );
      },
    );
  }

  Future<List<Drop>> _getUserDropsForSupport(String userId) async {
    try {
      // Load tickets first to ensure we have the latest data
      await ref.read(supportTicketProvider.notifier).loadMyTickets();
      
      // Get all user drops
      final allDrops = await ref.read(dropsControllerProvider.notifier).getUserDropsForSupport(userId);
      
      // Get existing tickets to filter out drops that already have tickets
      final ticketsState = ref.read(supportTicketProvider);
      final tickets = ticketsState.value ?? [];
      final existingDropIds = tickets
          .where((ticket) => ticket.relatedDropId != null)
          .map((ticket) => ticket.relatedDropId!)
          .toSet();
      
      // Filter to last 3 days, exclude drops with existing tickets, and sort by most recent
      final cutoff = DateTime.now().subtract(const Duration(days: 3));
      final filteredDrops = allDrops
          .where((d) => 
              d.createdAt.isAfter(cutoff) && 
              !existingDropIds.contains(d.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('🔍 Support: Found ${allDrops.length} total drops, ${filteredDrops.length} available for support (after 3-day and existing ticket filters)');
      
      return filteredDrops;
    } catch (e) {
      print('❌ Error getting user drops for support: $e');
      return [];
    }
  }

  Widget _buildApplicationsList() {
    final applicationAsync = ref.watch(collectorApplicationControllerProvider);

    return applicationAsync.when(
      data: (application) {
        if (application == null) {
          return _buildEmptyState(
            icon: Icons.assignment_ind,
            title: 'No Applications',
            description: 'You don\'t have any collector applications.',
          );
        }

        final isRejected = application.status == 'rejected';
        final isPendingTooLong = application.status == 'pending' &&
            DateTime.now()
                    .difference(DateTime.parse(application.createdAt.toString()))
                    .inDays >
                3;

        if (!isRejected && !isPendingTooLong) {
          return _buildEmptyState(
            icon: Icons.assignment_ind,
            title: 'No Issues Found',
            description: 'Your application is being processed normally.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Issues',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appGreenColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildApplicationCard(application),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading application: $error')),
    );
  }

  Widget _buildPaymentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Issues',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: appGreenColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildEmptyState(
          icon: Icons.payment,
          title: 'No Payments Yet',
          description: 'Payment feature is not available yet. Select a payment to get help with payment-related issues.',
        ),
        const SizedBox(height: 16),
        _buildPaymentSupportCard(),
      ],
    );
  }

  Widget _buildPaymentSupportCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToCreateTicket(
          context: context,
          category: widget.category,
          itemId: null,
          itemTitle: 'Payment Support',
          itemDescription: 'Get help with payment-related issues',
          metadata: {
            'ticketType': 'payment_issue',
            'context': 'payment_support',
            'category': widget.category,
            'categoryTitle': widget.categoryTitle,
            'issueContext': 'payment_support_request',
          },
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Support',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Get help with payment-related issues',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: appGreenColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildGeneralSupportCard(),
      ],
    );
  }
  Widget _buildApplicationCard(dynamic application) {
    final status = application.status;
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToCreateTicket(
          context: context,
          category: widget.category,
          itemId: application.id,
          itemTitle: 'Collector Application',
          itemDescription: 'Status: $statusText\nApplied: ${_formatDate(application.createdAt.toString())}',
          metadata: {
            'applicationId': application.id,
            'status': status,
            'idCardType': application.idCardType,
            'createdAt': application.createdAt.toString(),
            'rejectionReason': application.rejectionReason,
          },
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assignment_ind,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Collector Application',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: $statusText',
                      style: TextStyle(
                        fontSize: 14,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Applied: ${_formatDate(application.createdAt.toString())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  
  IconData _getCategoryIcon() {
    switch (widget.category) {
      case 'drops':
        return Icons.local_drink;
      case 'applications':
        return Icons.assignment_ind;
      case 'account':
        return Icons.account_circle;
      case 'technical':
        return Icons.bug_report;
      case 'payments':
        return Icons.payment;
      case 'general':
        return Icons.help_outline;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getCategoryDescription() {
    switch (widget.category) {
      case 'drops':
        return 'Select a drop from the last 3 days to get help';
      case 'applications':
        return 'Select your collector application to get help';
      case 'account':
        return 'Get help with your account issues';
      case 'technical':
        return 'Get help with technical problems';
      case 'payments':
        return 'Get help with payment issues';
      case 'general':
        return 'Get help with any other issue';
      default:
        return 'Select an item to get help';
    }
  }

Widget _buildGeneralSupportOption() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToCreateTicket(
          context: context,
          category: 'general',
          itemId: null,
          itemTitle: 'General Support',
          itemDescription: 'Get help with any other issue',
          metadata: {
            'context': 'general',
            'category': widget.category,
            'categoryTitle': widget.categoryTitle,
          },
           
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'General Support',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Get help with any other issue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
    }
    void _navigateToCreateTicket({
    required BuildContext context,
    required String category,
    required String? itemId,
    required String itemTitle,
    required String itemDescription,
    required Map<String, dynamic> metadata,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTicketScreen(
          preFilledData: {
            'category': category,
            'itemId': itemId,
            'itemTitle': itemTitle,
            'itemDescription': itemDescription,
            'metadata': metadata,
          },
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
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
    } catch (e) {
      return 'Unknown';
    }
  }
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'approved':
        return Colors.green;
      case 'collected':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'approved':
        return 'Approved';
      default:
        return status;
    }
  }

  Widget _buildDropCard(dynamic drop) {
    final status = drop.status.toString().split('.').last; // Convert enum to string
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToCreateTicket(
          context: context,
          category: widget.category,
          itemId: drop.id,
          itemTitle: 'Drop Issue - #${drop.id.substring(0, 8)}',
          itemDescription: 'Issue with drop created on ${_formatDate(drop.createdAt.toString())}\nStatus: $statusText\nBottles: ${drop.numberOfBottles}, Cans: ${drop.numberOfCans}',
          metadata: {
            'ticketType': 'drop_issue',
            'dropId': drop.id,
            'drop': {
              'id': drop.id,
              'status': status,
              'numberOfBottles': drop.numberOfBottles,
              'numberOfCans': drop.numberOfCans,
              'bottleType': drop.bottleType.toString().split('.').last,
              'notes': drop.notes ?? '',
              'leaveOutside': drop.leaveOutside,
              'createdAt': drop.createdAt.toString(),
            },
            'location': LatLngConverter().toJson(drop.location),
            'issueContext': 'household_drop_last_3_days',
            'createdAt': drop.createdAt.toString(),
          },
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Drop image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: drop.imageUrl != null && drop.imageUrl.isNotEmpty
                      ? Image.network(
                          drop.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.local_drink,
                                color: statusColor,
                                size: 24,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: statusColor.withOpacity(0.1),
                          child: Icon(
                            Icons.local_drink,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drop #${drop.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${drop.numberOfBottles + drop.numberOfCans} items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(drop.createdAt.toString()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (drop.notes != null && drop.notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        drop.notes,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSupportCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToCreateTicket(
          context: context,
          category: widget.category,
          itemId: null,
          itemTitle: 'General ${widget.categoryTitle}',
          itemDescription: 'Get help with ${widget.categoryTitle.toLowerCase()}',
          metadata: {
            'ticketType': 'general_support',
            'context': 'general',
            'category': widget.category,
            'categoryTitle': widget.categoryTitle,
            'issueContext': 'general_support_request',
          },
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: appGreenColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(),
                  color: appGreenColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'General ${widget.categoryTitle}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get help with ${widget.categoryTitle.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get collector history
  Future<CollectorHistory> _getCollectorHistory(String userId) async {
    final repository = StatsRepository(StatsApiClient(ApiClientConfig.createDio()));
    return await repository.getCollectorHistory(
      userId,
      status: null, // Get all statuses
      timeRange: null, // Get all time ranges
      page: 1,
      limit: 20,
    );
  }

  // Helper to group interactions by drop (same logic as history page)
  List<List<CollectorInteraction>> _groupInteractionsByDrop(List<CollectorInteraction> interactions) {
    final Map<String, List<CollectorInteraction>> grouped = {};
    
    for (final interaction in interactions) {
      String dropKey = '';
      
      if (interaction.dropoff?.id.isNotEmpty == true) {
        dropKey = interaction.dropoff!.id;
      } else if (interaction.dropoffId.isNotEmpty) {
        dropKey = interaction.dropoffId;
      } else {
        dropKey = interaction.id;
      }
      
      if (dropKey.isNotEmpty) {
        grouped.putIfAbsent(dropKey, () => []).add(interaction);
      }
    }
    
    // Sort each group by interaction time
    for (final group in grouped.values) {
      group.sort((a, b) => a.interactionTime.compareTo(b.interactionTime));
    }
    
    // Create pairs from each group
    List<List<CollectorInteraction>> pairs = [];
    
    for (final group in grouped.values) {
      final acceptedInteractions = group.where((i) => i.interactionType == 'accepted').toList();
      
      if (acceptedInteractions.isNotEmpty) {
        for (int i = 0; i < acceptedInteractions.length; i++) {
          final accepted = acceptedInteractions[i];
          
          final subsequentInteractions = group.where((interaction) {
            return (interaction.interactionType == 'expired' || 
                    interaction.interactionType == 'collected' || 
                    interaction.interactionType == 'cancelled') &&
                   interaction.interactionTime.isAfter(accepted.interactionTime);
          }).toList();
          
          if (subsequentInteractions.isNotEmpty) {
            subsequentInteractions.sort((a, b) => a.interactionTime.compareTo(b.interactionTime));
            pairs.add([accepted, subsequentInteractions.first]);
          } else {
            pairs.add([accepted]);
          }
        }
      } else {
        for (final interaction in group) {
          if (interaction.interactionType == 'cancelled' || 
              interaction.interactionType == 'collected' || 
              interaction.interactionType == 'expired') {
            pairs.add([interaction]);
          }
        }
      }
    }
    
    // Sort pairs by the most recent interaction time (descending order)
    pairs.sort((a, b) => b.last.interactionTime.compareTo(a.last.interactionTime));
    
    return pairs;
  }

  Widget _buildCollectionCard(List<CollectorInteraction> interactions) {
    final firstInteraction = interactions.first;
    final lastInteraction = interactions.last;
    final dropoff = firstInteraction.dropoff;
    
    String status = lastInteraction.interactionType;
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToCreateTicket(
          context: context,
          category: widget.category,
          itemId: firstInteraction.id,
          itemTitle: 'Collection Issue - #${firstInteraction.id.substring(0, 8)}',
          itemDescription: 'Issue with collection ${statusText.toLowerCase()} on ${_formatDate(lastInteraction.interactionTime.toString())}\nDrop: ${dropoff?.id.substring(0, 8) ?? 'Unknown'}',
          metadata: {
            'ticketType': 'collection_issue',
            'collectionId': firstInteraction.id.split('_')[0], // Extract actual CollectionAttempt ID (remove _accepted suffix)
            'dropoffId': firstInteraction.dropoffId,
            'interaction': {
              'id': firstInteraction.id,
              'acceptedInteraction': {
                'id': firstInteraction.id,
                'type': firstInteraction.interactionType,
                'time': firstInteraction.interactionTime.toString(),
                'notes': firstInteraction.notes,
              },
              'finalInteraction': {
                'id': lastInteraction.id,
                'type': lastInteraction.interactionType,
                'time': lastInteraction.interactionTime.toString(),
                'cancellationReason': lastInteraction.cancellationReason,
                'notes': lastInteraction.notes,
              },
              'status': status,
            },
            'dropoff': dropoff?.toJson(),
            'issueContext': 'collector_interaction_last_3_days',
            'interactionTime': lastInteraction.interactionTime.toString(),
          },
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Drop image from the collection
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: dropoff?.imageUrl != null && dropoff!.imageUrl.isNotEmpty
                      ? Image.network(
                          dropoff.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: statusColor.withOpacity(0.1),
                              child: Icon(
                                Icons.inventory_2,
                                color: statusColor,
                                size: 24,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: statusColor.withOpacity(0.1),
                          child: Icon(
                            Icons.inventory_2,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection #${firstInteraction.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (dropoff != null)
                          Text(
                            '${dropoff.numberOfBottles + dropoff.numberOfCans} items',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Drop: ${dropoff?.id.substring(0, 8) ?? 'Unknown'} • ${_formatDate(lastInteraction.interactionTime.toString())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

    

  // ... keep your _buildDropCard, _buildApplicationCard, _buildGeneralSupportCard, 
  // _buildGeneralSupportOption, _buildEmptyState, _navigateToCreateTicket, 
  // and helpers (_getCategoryIcon, etc.) the same but wrap metadata in {} properly 
  // and remove duplicate return statements.
}

    
