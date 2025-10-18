class RewardStats {
  final int totalDropsCollected;
  final int totalDropsCreated;
  final int totalPointsEarned;
  final int currentPoints;
  final int currentTier;
  final List<RewardHistoryItem> rewardHistory;

  RewardStats({
    required this.totalDropsCollected,
    required this.totalDropsCreated,
    required this.totalPointsEarned,
    required this.currentPoints,
    required this.currentTier,
    required this.rewardHistory,
  });

  factory RewardStats.fromJson(Map<String, dynamic> json) {
    print('🎯 RewardStats.fromJson: Parsing response: $json');
    
    // Handle the actual backend response structure
    final currentTierData = json['currentTier'] as Map<String, dynamic>?;
    final currentTier = currentTierData?['tier'] ?? 1;
    
    print('🎯 RewardStats.fromJson: Extracted currentTier: $currentTier');
    print('🎯 RewardStats.fromJson: Extracted currentPoints: ${json['currentPoints']}');
    
    return RewardStats(
      totalDropsCollected: json['totalDrops'] ?? 0, // Backend uses 'totalDrops'
      totalDropsCreated: json['totalDrops'] ?? 0, // Same as collected for now
      totalPointsEarned: json['totalPoints'] ?? 0, // Backend uses 'totalPoints'
      currentPoints: json['currentPoints'] ?? 0,
      currentTier: currentTier,
      rewardHistory: (json['rewardHistory'] as List<dynamic>?)
          ?.map((item) => RewardHistoryItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

class RewardHistoryItem {
  final String? dropId;
  final int pointsAwarded;
  final int tier;
  final bool tierUpgraded;
  final String type;
  final DateTime collectedAt;

  RewardHistoryItem({
    this.dropId,
    required this.pointsAwarded,
    required this.tier,
    required this.tierUpgraded,
    required this.type,
    required this.collectedAt,
  });

  factory RewardHistoryItem.fromJson(Map<String, dynamic> json) {
    return RewardHistoryItem(
      dropId: json['dropId'],
      pointsAwarded: json['pointsAwarded'] ?? 0,
      tier: json['tier'] ?? 1,
      tierUpgraded: json['tierUpgraded'] ?? false,
      type: json['type'] ?? 'unknown',
      collectedAt: DateTime.parse(json['collectedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class TierInfo {
  final int tier;
  final String name;
  final int dropsRequired;
  final int pointsPerDrop;

  TierInfo({
    required this.tier,
    required this.name,
    required this.dropsRequired,
    required this.pointsPerDrop,
  });

  factory TierInfo.fromJson(Map<String, dynamic> json) {
    return TierInfo(
      tier: json['tier'] ?? 1,
      name: json['name'] ?? 'Unknown',
      dropsRequired: json['dropsRequired'] ?? 0,
      pointsPerDrop: json['pointsPerDrop'] ?? 10,
    );
  }
}
