import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/rewards/data/models/reward_models.dart';
import 'package:botleji/features/rewards/data/services/reward_service.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';

// Reward Shop State
class RewardShopState {
  final List<RewardItem> items;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;
  final String? selectedSubCategory;

  RewardShopState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
    this.selectedSubCategory,
  });

  RewardShopState copyWith({
    List<RewardItem>? items,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? selectedSubCategory,
  }) {
    return RewardShopState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedSubCategory: selectedSubCategory ?? this.selectedSubCategory,
    );
  }
}

// Reward Shop Notifier
class RewardShopNotifier extends StateNotifier<RewardShopState> {
  RewardShopNotifier() : super(RewardShopState());

  Future<void> loadRewardItems({
    String? category,
    String? subCategory,
  }) async {
    print('🎯 RewardShopProvider: Starting loadRewardItems with category: $category, subCategory: $subCategory');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('🎯 RewardShopProvider: Calling RewardService.getRewardItems...');
      final itemsData = await RewardService.getRewardItems(
        category: category,
        subCategory: subCategory,
        isActive: true, // Only show active items
      );
      print('🎯 RewardShopProvider: Got ${itemsData.length} items from service');

      final items = itemsData.map((json) => RewardItem.fromJson(json)).toList();
      
      print('🎯 RewardShopProvider: Received ${items.length} items after filtering');
      for (var item in items) {
        print('🎯 RewardShopProvider: Item "${item.name}" - Category: ${item.category.value}, SubCategory: ${item.subCategory}');
      }
      
      state = state.copyWith(
        items: items,
        isLoading: false,
        selectedCategory: category,
        selectedSubCategory: subCategory,
      );
    } catch (e) {
      print('🎯 RewardShopProvider: Error loading reward items: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setCategory(String? category) {
    print('🎯 RewardShopProvider: Setting category filter to: $category');
    state = state.copyWith(selectedCategory: category);
    loadRewardItems(category: category);
  }

  void setSubCategory(String? subCategory) {
    state = state.copyWith(selectedSubCategory: subCategory);
    loadRewardItems(
      category: state.selectedCategory,
      subCategory: subCategory,
    );
  }

  Future<void> refresh() async {
    await loadRewardItems(
      category: state.selectedCategory,
      subCategory: state.selectedSubCategory,
    );
  }
}

// Provider
final rewardShopProvider = StateNotifierProvider<RewardShopNotifier, RewardShopState>((ref) {
  return RewardShopNotifier();
});

// Filtered items provider
final filteredRewardItemsProvider = Provider<List<RewardItem>>((ref) {
  final shopState = ref.watch(rewardShopProvider);
  return shopState.items;
});

// User redemptions provider
final userRedemptionsProvider = FutureProvider<List<RewardRedemption>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.value;
  
  if (user == null) return [];

  try {
    final redemptionsData = await RewardService.getUserRedemptions(user.id);
    return redemptionsData.map((json) => RewardRedemption.fromJson(json)).toList();
  } catch (e) {
    print('Error loading user redemptions: $e');
    return [];
  }
});

// Redeem reward provider
final redeemRewardProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, rewardItemId) async {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.value;
  
  if (user == null) throw Exception('User not authenticated');

  try {
    final result = await RewardService.redeemReward(user.id, rewardItemId);
    
    // Refresh the reward shop and redemptions after successful redemption
    ref.invalidate(rewardShopProvider);
    ref.invalidate(userRedemptionsProvider);
    
    return result;
  } catch (e) {
    print('Error redeeming reward: $e');
    rethrow;
  }
});
