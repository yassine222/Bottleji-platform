import 'package:flutter_riverpod/flutter_riverpod.dart';

class CollectionSuccessState {
  final bool showPopup;
  final int pointsAwarded;
  final String tierName;
  final int currentTier;
  final int totalPoints;
  final bool tierUpgraded;

  CollectionSuccessState({
    this.showPopup = false,
    this.pointsAwarded = 0,
    this.tierName = '',
    this.currentTier = 1,
    this.totalPoints = 0,
    this.tierUpgraded = false,
  });

  CollectionSuccessState copyWith({
    bool? showPopup,
    int? pointsAwarded,
    String? tierName,
    int? currentTier,
    int? totalPoints,
    bool? tierUpgraded,
  }) {
    return CollectionSuccessState(
      showPopup: showPopup ?? this.showPopup,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      tierName: tierName ?? this.tierName,
      currentTier: currentTier ?? this.currentTier,
      totalPoints: totalPoints ?? this.totalPoints,
      tierUpgraded: tierUpgraded ?? this.tierUpgraded,
    );
  }
}

class CollectionSuccessNotifier extends StateNotifier<CollectionSuccessState> {
  CollectionSuccessNotifier() : super(CollectionSuccessState());

  void showCollectionSuccess({
    required int pointsAwarded,
    required String tierName,
    required int currentTier,
    required int totalPoints,
    required bool tierUpgraded,
  }) {
    print('🎉 CollectionSuccessProvider: showCollectionSuccess called with $pointsAwarded points');
    state = state.copyWith(
      showPopup: true,
      pointsAwarded: pointsAwarded,
      tierName: tierName,
      currentTier: currentTier,
      totalPoints: totalPoints,
      tierUpgraded: tierUpgraded,
    );
    print('🎉 CollectionSuccessProvider: State updated, showPopup: ${state.showPopup}');
  }

  void dismissPopup() {
    state = state.copyWith(showPopup: false);
  }
}

final collectionSuccessProvider = StateNotifierProvider<CollectionSuccessNotifier, CollectionSuccessState>((ref) {
  return CollectionSuccessNotifier();
});
