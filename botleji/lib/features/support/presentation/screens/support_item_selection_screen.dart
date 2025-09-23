import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/drops/controllers/drops_controller.dart';
import 'package:botleji/features/collector/controllers/collector_application_controller.dart';
import 'package:botleji/features/support/presentation/screens/create_ticket_screen.dart';

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
            case 'drops':
              await ref
                  .read(dropsControllerProvider.notifier)
                  .loadUserDrops(user.id);
              break;
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
        backgroundColor: theme.colorScheme.surface,
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
      default:
        return _buildGeneralOptions();
    }
  }

  Widget _buildDropsList() {
    final dropsAsync = ref.watch(dropsControllerProvider);

    return dropsAsync.when(
      data: (drops) {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final recentDrops = drops.where((drop) {
          final dropDate = DateTime.parse(drop.createdAt.toString());
          return dropDate.isAfter(threeDaysAgo);
        }).toList();

        if (recentDrops.isEmpty) {
          return _buildEmptyState(
            icon: Icons.local_drink,
            title: 'No Recent Drops',
            description: 'You don\'t have any drops from the last 3 days.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Drops (Last 3 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appGreenColor,
              ),
            ),
            const SizedBox(height: 16),
            ...recentDrops.map((drop) => _buildDropCard(drop)).toList(),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading drops: $error')),
    );
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
            'createdAt': application.createdAt,
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
    final status = drop.status;
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
          itemTitle: 'Drop #${drop.id.substring(0, 8)}',
          itemDescription: 'Status: $statusText\nBottles: ${drop.numberOfBottles}\nCans: ${drop.numberOfCans}',
          metadata: {
            'dropId': drop.id,
            'status': status,
            'numberOfBottles': drop.numberOfBottles,
            'numberOfCans': drop.numberOfCans,
            'bottleType': drop.bottleType,
            'location': drop.location,
            'createdAt': drop.createdAt,
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
                  Icons.local_drink,
                  color: statusColor,
                  size: 20,
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
                      '${drop.numberOfBottles} bottles, ${drop.numberOfCans} cans • ${_formatDate(drop.createdAt)}',
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

    

  // ... keep your _buildDropCard, _buildApplicationCard, _buildGeneralSupportCard, 
  // _buildGeneralSupportOption, _buildEmptyState, _navigateToCreateTicket, 
  // and helpers (_getCategoryIcon, etc.) the same but wrap metadata in {} properly 
  // and remove duplicate return statements.
}

    
