import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/rewards/presentation/providers/reward_shop_provider.dart';
import 'package:botleji/features/rewards/data/models/reward_models.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';

class RewardShopWidget extends ConsumerWidget {
  const RewardShopWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(rewardShopProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.value;

    if (user == null) {
      return const Center(child: Text('Please log in to view rewards'));
    }

    // Load reward items on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shopState.items.isEmpty && !shopState.isLoading) {
        ref.read(rewardShopProvider.notifier).loadRewardItems();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reward Shop',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => ref.read(rewardShopProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),

        // Category Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildCategoryFilter(context, ref),
        ),

        const SizedBox(height: 16),

        // Content
        if (shopState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (shopState.error != null)
          Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('Failed to load rewards'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.read(rewardShopProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (shopState.items.isEmpty)
          _buildEmptyState(context)
        else
          _buildRewardItems(context, ref, shopState.items, user),
      ],
    );
  }

  Widget _buildCategoryFilter(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(rewardShopProvider);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            context,
            label: 'All',
            isSelected: shopState.selectedCategory == null,
            onSelected: () => ref.read(rewardShopProvider.notifier).setCategory(null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            label: 'Collector',
            isSelected: shopState.selectedCategory == 'collector',
            onSelected: () => ref.read(rewardShopProvider.notifier).setCategory('collector'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            label: 'Household',
            isSelected: shopState.selectedCategory == 'household',
            onSelected: () => ref.read(rewardShopProvider.notifier).setCategory('household'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Rewards Available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for exciting rewards!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItems(BuildContext context, WidgetRef ref, List<RewardItem> items, user) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildRewardCard(context, ref, item, user);
      },
    );
  }

  Widget _buildRewardCard(BuildContext context, WidgetRef ref, RewardItem item, user) {
    final canAfford = user.currentPoints >= item.pointCost;
    final isInStock = item.stock > 0;
    final canRedeem = canAfford && isInStock && item.isActive;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: canRedeem ? () => _showRedeemDialog(context, ref, item, user) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                          ),
                        )
                      : _buildPlaceholderIcon(),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Name
              Text(
                item.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Points
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.pointCost} pts',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Stock status
              if (!isInStock)
                Text(
                  'Out of Stock',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (!canAfford)
                Text(
                  'Not enough points',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  'Tap to redeem',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.card_giftcard,
        size: 32,
        color: Colors.grey,
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, WidgetRef ref, RewardItem item, user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${item.description}'),
            const SizedBox(height: 8),
            Text('Cost: ${item.pointCost} points'),
            const SizedBox(height: 8),
            Text('Your points: ${user.currentPoints}'),
            const SizedBox(height: 8),
            Text('Stock: ${item.stock} available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _redeemReward(context, ref, item);
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemReward(BuildContext context, WidgetRef ref, RewardItem item) async {
    try {
      await ref.read(redeemRewardProvider(item.id).future);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully redeemed ${item.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to redeem reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
