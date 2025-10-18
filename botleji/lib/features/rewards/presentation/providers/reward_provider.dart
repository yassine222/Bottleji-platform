import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/rewards/data/services/reward_service.dart';
import 'package:botleji/features/rewards/data/models/reward_models.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';

// Reward stats provider
final rewardStatsProvider = FutureProvider<RewardStats>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.value;
  
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final stats = await RewardService.getUserRewardStats(user.id);
  return RewardStats.fromJson(stats);
});

// Tiers provider
final tiersProvider = FutureProvider<List<TierInfo>>((ref) async {
  final tiers = await RewardService.getAllTiers();
  return tiers.map((tier) => TierInfo.fromJson(tier)).toList();
});

// Tier upgrade detection provider
final tierUpgradeProvider = StateNotifierProvider<TierUpgradeNotifier, TierUpgradeState>((ref) {
  return TierUpgradeNotifier();
});

class TierUpgradeState {
  final bool showPopup;
  final TierInfo? newTier;
  final int? pointsAwarded;

  TierUpgradeState({
    this.showPopup = false,
    this.newTier,
    this.pointsAwarded,
  });

  TierUpgradeState copyWith({
    bool? showPopup,
    TierInfo? newTier,
    int? pointsAwarded,
  }) {
    return TierUpgradeState(
      showPopup: showPopup ?? this.showPopup,
      newTier: newTier ?? this.newTier,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
    );
  }
}

class TierUpgradeNotifier extends StateNotifier<TierUpgradeState> {
  TierUpgradeNotifier() : super(TierUpgradeState());

  void showTierUpgrade(TierInfo newTier, int pointsAwarded) {
    state = state.copyWith(
      showPopup: true,
      newTier: newTier,
      pointsAwarded: pointsAwarded,
    );
  }

  void dismissPopup() {
    state = state.copyWith(
      showPopup: false,
      newTier: null,
      pointsAwarded: null,
    );
  }
}

// Helper function to detect tier upgrades
class TierUpgradeDetector {
  static TierInfo? detectTierUpgrade(
    RewardStats oldStats,
    RewardStats newStats,
    List<TierInfo> tiers,
  ) {
    if (newStats.currentTier > oldStats.currentTier) {
      // Find the new tier info
      return tiers.firstWhere(
        (tier) => tier.tier == newStats.currentTier,
        orElse: () => TierInfo(
          tier: newStats.currentTier,
          name: 'Tier ${newStats.currentTier}',
          dropsRequired: 0,
          pointsPerDrop: 10,
        ),
      );
    }
    return null;
  }
}
