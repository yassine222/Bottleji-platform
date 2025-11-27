import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/reward_models.dart';
import '../providers/order_history_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:botleji/l10n/app_localizations.dart';

class OrderHistoryWidget extends ConsumerWidget {
  const OrderHistoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    
    return authState.when(
      data: (user) {
        if (user == null) {
          return Center(
            child: Text(AppLocalizations.of(context).pleaseLogInToViewOrderHistory),
          );
        }
        
        return _OrderHistoryContent(userId: user.id);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading user: $error'),
      ),
    );
  }
}

class _OrderHistoryContent extends ConsumerStatefulWidget {
  final String userId;
  
  const _OrderHistoryContent({required this.userId});

  @override
  ConsumerState<_OrderHistoryContent> createState() => _OrderHistoryContentState();
}

class _OrderHistoryContentState extends ConsumerState<_OrderHistoryContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderHistoryNotifierProvider.notifier).loadOrderHistory(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderHistoryState = ref.watch(orderHistoryNotifierProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.history,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).orderHistory,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ref.read(orderHistoryNotifierProvider.notifier).refresh(widget.userId);
                },
                icon: const Icon(Icons.refresh),
                tooltip: AppLocalizations.of(context).refresh,
              ),
            ],
          ),
        ),
        
        // Order History List
        Expanded(
          child: orderHistoryState.when(
            data: (redemptions) {
              if (redemptions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).noOrdersYet,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).yourOrderHistoryWillAppearHere,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                itemCount: redemptions.length,
                itemBuilder: (context, index) {
                  final redemption = redemptions[index];
                  return _OrderHistoryCard(redemption: redemption);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
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
                    AppLocalizations.of(context).failedToLoadOrderHistory,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(orderHistoryNotifierProvider.notifier).refresh(widget.userId);
                    },
                    child: Text(AppLocalizations.of(context).retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final RewardRedemption redemption;
  
  const _OrderHistoryCard({required this.redemption});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with item name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    redemption.rewardItemName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(status: redemption.status),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Order details
            _OrderDetailRow(
              icon: Icons.stars,
              label: AppLocalizations.of(context).pointsSpent,
              value: '${redemption.pointsSpent}',
            ),
            
            if (redemption.selectedSize != null) ...[
              const SizedBox(height: 8),
              _OrderDetailRow(
                icon: Icons.straighten,
                label: AppLocalizations.of(context).size,
                value: '${redemption.selectedSize} (${redemption.sizeType})',
              ),
            ],
            
            const SizedBox(height: 8),
            _OrderDetailRow(
              icon: Icons.calendar_today,
              label: AppLocalizations.of(context).orderDate,
              value: _formatDate(context, redemption.createdAt),
            ),
            
            if (redemption.trackingNumber != null) ...[
              const SizedBox(height: 8),
              _OrderDetailRow(
                icon: Icons.local_shipping,
                label: AppLocalizations.of(context).tracking,
                value: redemption.trackingNumber!,
              ),
            ],
            
            if (redemption.estimatedDelivery != null) ...[
              const SizedBox(height: 8),
              _OrderDetailRow(
                icon: Icons.schedule,
                label: AppLocalizations.of(context).estimatedDelivery,
                value: _formatDate(context, redemption.estimatedDelivery!),
              ),
            ],
            
            // Delivery address
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context).deliveryAddress,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${redemption.deliveryAddress.street}\n'
                    '${redemption.deliveryAddress.city}, ${redemption.deliveryAddress.state} ${redemption.deliveryAddress.zipCode}\n'
                    '${redemption.deliveryAddress.country}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (redemption.deliveryAddress.phoneNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Phone: ${redemption.deliveryAddress.phoneNumber}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            
            // Admin notes (if any)
            if (redemption.adminNotes != null && redemption.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note,
                          size: 16,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context).adminNote,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      redemption.adminNotes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    
    if (locale.languageCode == 'ar') {
      // Arabic date format: "15/01/2024"
      return '${date.day}/${date.month}/${date.year}';
    } else {
      // English date format: "01/15/2024" (MM/DD/YYYY)
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

class _OrderDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _OrderDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final RedemptionStatus status;
  
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color backgroundColor;
    Color textColor;
    String statusText;
    switch (status) {
      case RedemptionStatus.pending:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        statusText = l10n.pending;
        break;
      case RedemptionStatus.approved:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        statusText = l10n.approved;
        break;
      case RedemptionStatus.processing:
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        statusText = l10n.processing;
        break;
      case RedemptionStatus.shipped:
        backgroundColor = Colors.indigo[100]!;
        textColor = Colors.indigo[800]!;
        statusText = l10n.shipped;
        break;
      case RedemptionStatus.delivered:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        statusText = l10n.delivered;
        break;
      case RedemptionStatus.cancelled:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        statusText = l10n.cancelled;
        break;
      case RedemptionStatus.rejected:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        statusText = l10n.rejected;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
