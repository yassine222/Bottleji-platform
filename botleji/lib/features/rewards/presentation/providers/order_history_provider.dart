import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/reward_service.dart';
import '../../data/models/reward_models.dart';

final orderHistoryProvider = FutureProvider.family<List<RewardRedemption>, String>((ref, userId) async {
  return await RewardService.getUserRedemptions(userId);
});

final orderHistoryNotifierProvider = StateNotifierProvider<OrderHistoryNotifier, AsyncValue<List<RewardRedemption>>>((ref) {
  return OrderHistoryNotifier();
});

class OrderHistoryNotifier extends StateNotifier<AsyncValue<List<RewardRedemption>>> {
  OrderHistoryNotifier() : super(const AsyncValue.loading());

  Future<void> loadOrderHistory(String userId) async {
    state = const AsyncValue.loading();
    try {
      final redemptions = await RewardService.getUserRedemptions(userId);
      state = AsyncValue.data(redemptions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh(String userId) async {
    await loadOrderHistory(userId);
  }
}
