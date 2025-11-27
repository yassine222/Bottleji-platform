import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/rewards/data/models/reward_models.dart';
import 'package:botleji/features/auth/data/models/user_data.dart';
import 'package:botleji/features/rewards/presentation/providers/reward_provider.dart';
import 'package:botleji/l10n/app_localizations.dart';

class RewardItemDetailPage extends ConsumerWidget {
  final RewardItem item;
  final UserData user;
  final Function(int) onRedeem;

  const RewardItemDetailPage({
    super.key,
    required this.item,
    required this.user,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardStatsAsync = ref.watch(rewardStatsProvider);
    
    return rewardStatsAsync.when(
      data: (rewardStats) => _buildContent(context, rewardStats.currentPoints),
      loading: () => _buildContent(context, user.currentPoints ?? 0),
      error: (error, stack) => _buildContent(context, user.currentPoints ?? 0),
    );
  }

  Widget _buildContent(BuildContext context, int userPoints) {
    final canAfford = userPoints >= item.pointCost;
    final isInStock = item.stock > 0;
    final canRedeem = canAfford && isInStock && item.isActive;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                      ),
                    )
                  : _buildPlaceholderIcon(),
            ),

            const SizedBox(height: 24),

            // Title and Points
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.pointCost} pts',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Category and Subcategory
            Row(
              children: [
                _buildInfoChip(context, item.category.name, Icons.category),
                const SizedBox(width: 8),
                if (item.subCategory.isNotEmpty) ...[
                  _buildInfoChip(context, item.subCategory, Icons.label),
                  const SizedBox(width: 8),
                ],
                _buildInfoChip(
                  context,
                  item.isActive ? 'Active' : 'Inactive',
                  item.isActive ? Icons.check_circle : Icons.cancel,
                  color: item.isActive ? Colors.green : Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Stock Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Availability',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 20,
                        color: isInStock ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isInStock ? AppLocalizations.of(context).available(item.stock) : AppLocalizations.of(context).outOfStock,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isInStock ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 20,
                        color: canAfford ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your points: $userPoints',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: canAfford ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Order Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canRedeem ? () => onRedeem(userPoints) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRedeem 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: canRedeem ? 2 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canRedeem ? Icons.shopping_cart : Icons.block,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      canRedeem 
                          ? 'Order Now - ${item.pointCost} points'
                          : _getOrderButtonText(context, canAfford, isInStock, item.isActive),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!canRedeem) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getOrderButtonText(context, canAfford, isInStock, item.isActive),
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildInfoChip(
    BuildContext context,
    String label,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (color ?? Theme.of(context).primaryColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.card_giftcard,
        size: 64,
        color: Colors.grey,
      ),
    );
  }

  String _getOrderButtonText(BuildContext context, bool canAfford, bool isInStock, bool isActive) {
    final l10n = AppLocalizations.of(context);
    if (!isActive) return l10n.itemNotAvailable;
    if (!isInStock) return l10n.outOfStock;
    if (!canAfford) return l10n.notEnoughPoints;
    return l10n.orderNow;
  }
}
