import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/rewards/presentation/providers/reward_shop_provider.dart';
import 'package:botleji/features/rewards/presentation/providers/reward_provider.dart';
import 'package:botleji/features/rewards/data/models/reward_models.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/rewards/presentation/pages/reward_item_detail_page.dart';
import 'package:botleji/features/rewards/presentation/widgets/redemption_confirmation_dialog.dart';
import 'package:botleji/features/rewards/data/services/reward_service.dart';
import 'package:botleji/l10n/app_localizations.dart';

class RewardShopWidget extends ConsumerWidget {
  const RewardShopWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(rewardShopProvider);
    final authState = ref.watch(authNotifierProvider);
    final rewardStatsAsync = ref.watch(rewardStatsProvider);
    final user = authState.value;

    if (user == null) {
      return Center(child: Text(AppLocalizations.of(context).pleaseLogInToViewOrderHistory));
    }

    // Load items if empty and not loading
    if (shopState.items.isEmpty && !shopState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(rewardShopProvider.notifier).loadRewardItems();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Remove duplicate header - it's now handled in the main screen

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
                Text(AppLocalizations.of(context).failedToLoadOrderHistory),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.read(rewardShopProvider.notifier).refresh(),
                  child: Text(AppLocalizations.of(context).retry),
                ),
              ],
            ),
          )
        else if (shopState.items.isEmpty)
          _buildEmptyState(context)
        else
          rewardStatsAsync.when(
            data: (rewardStats) => _buildRewardItems(context, ref, shopState.items, user, rewardStats.currentPoints),
            loading: () => _buildRewardItems(context, ref, shopState.items, user, user.currentPoints ?? 0),
            error: (error, stack) => _buildRewardItems(context, ref, shopState.items, user, user.currentPoints ?? 0),
          ),
      ],
    );
  }

  Widget _buildCategoryFilter(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(rewardShopProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.value;
    
    // Check if user has collector role
    final hasCollectorRole = user?.roles.contains('collector') ?? false;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            context,
            label: AppLocalizations.of(context).all,
            isSelected: shopState.selectedCategory == null,
            onSelected: () => ref.read(rewardShopProvider.notifier).setCategory(null),
          ),
          const SizedBox(width: 8),
          // Only show collector filter if user has collector role
          if (hasCollectorRole) ...[
            _buildFilterChip(
              context,
              label: AppLocalizations.of(context).collector,
              isSelected: shopState.selectedCategory == 'collector',
              onSelected: () => ref.read(rewardShopProvider.notifier).setCategory('collector'),
            ),
            const SizedBox(width: 8),
          ],
          _buildFilterChip(
            context,
            label: AppLocalizations.of(context).household,
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
            AppLocalizations.of(context).noRewardsAvailable,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).checkBackLaterForRewards,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItems(BuildContext context, WidgetRef ref, List<RewardItem> items, user, int userPoints) {
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
        return _buildRewardCard(context, ref, item, user, userPoints);
      },
    );
  }

  Widget _buildRewardCard(BuildContext context, WidgetRef ref, RewardItem item, user, int userPoints) {
    return _buildRewardCardContent(context, ref, item, user, userPoints);
  }

  Widget _buildRewardCardContent(BuildContext context, WidgetRef ref, RewardItem item, user, int userPoints) {
    final canAfford = userPoints >= item.pointCost;
    final isInStock = item.stock > 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToItemDetail(context, ref, item, user),
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
                  AppLocalizations.of(context).outOfStock,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (!canAfford)
                Text(
                  AppLocalizations.of(context).notEnoughPoints,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  AppLocalizations.of(context).tapToRedeem,
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

  void _navigateToItemDetail(BuildContext context, WidgetRef ref, RewardItem item, user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RewardItemDetailPage(
          item: item,
          user: user,
          onRedeem: (userPoints) => _redeemReward(context, ref, item, userPoints),
        ),
      ),
    );
  }

  Future<void> _redeemReward(BuildContext context, WidgetRef ref, RewardItem item, int userPoints) async {
    // Show confirmation bottom sheet with delivery address form
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RedemptionConfirmationDialog(
        item: item,
        userPoints: userPoints,
        onConfirm: (deliveryAddress, {String? selectedSize, String? sizeType}) async {
          await _processRedemption(context, ref, item, deliveryAddress, selectedSize: selectedSize, sizeType: sizeType);
        },
      ),
    );
  }

  Future<void> _processRedemption(BuildContext context, WidgetRef ref, RewardItem item, DeliveryAddress deliveryAddress, {String? selectedSize, String? sizeType}) async {
    try {
      print('🛒 Starting redemption process...');
      print('🛒 Item: ${item.name} (${item.pointCost} points)');
      print('🛒 User ID: ${ref.read(authNotifierProvider).value?.id}');
      print('🛒 Selected Size: $selectedSize, Size Type: $sizeType');
      
      final authState = ref.read(authNotifierProvider);
      final user = authState.value;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call the updated redeemReward method with delivery address and size
      await RewardService.redeemReward(
        user.id, 
        item.id, 
        deliveryAddress.toJson(),
        selectedSize: selectedSize,
        sizeType: sizeType,
        pointCost: item.pointCost,
      );
      
      print('✅ Redemption successful!');
      
      // Refresh reward stats and shop data after successful redemption
      ref.invalidate(rewardStatsProvider);
      ref.read(rewardShopProvider.notifier).refresh();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).orderPlacedSuccessfully(item.name)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Redemption failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).failedToPlaceOrder(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
