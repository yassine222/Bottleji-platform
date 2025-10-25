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

// Reward Shop Models
class RewardItem {
  final String id;
  final String name;
  final String description;
  final RewardCategory category;
  final String subCategory;
  final int pointCost;
  final int stock;
  final String? imageUrl;
  final bool isActive;
  final int totalRedemptions;
  final DateTime createdAt;
  final DateTime updatedAt;

  RewardItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.pointCost,
    required this.stock,
    this.imageUrl,
    required this.isActive,
    required this.totalRedemptions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: RewardCategory.fromString(json['category'] ?? 'collector'),
      subCategory: json['subCategory'] ?? '',
      pointCost: json['pointCost'] ?? 0,
      stock: json['stock'] ?? 0,
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      totalRedemptions: json['totalRedemptions'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.value,
      'subCategory': subCategory,
      'pointCost': pointCost,
      'stock': stock,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'totalRedemptions': totalRedemptions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

enum RewardCategory {
  collector('collector'),
  household('household');

  const RewardCategory(this.value);
  final String value;

  static RewardCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'collector':
        return RewardCategory.collector;
      case 'household':
        return RewardCategory.household;
      default:
        return RewardCategory.collector;
    }
  }

  String get displayName {
    switch (this) {
      case RewardCategory.collector:
        return 'Collector Rewards';
      case RewardCategory.household:
        return 'Household Rewards';
    }
  }
}

class RewardRedemption {
  final String id;
  final String userId;
  final String rewardItemId;
  final String rewardItemName;
  final int pointsSpent;
  final String status; // 'pending', 'approved', 'rejected', 'fulfilled'
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? fulfilledAt;
  final String? notes;

  RewardRedemption({
    required this.id,
    required this.userId,
    required this.rewardItemId,
    required this.rewardItemName,
    required this.pointsSpent,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.fulfilledAt,
    this.notes,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    return RewardRedemption(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      rewardItemId: json['rewardItemId'] ?? '',
      rewardItemName: json['rewardItemName'] ?? '',
      pointsSpent: json['pointsSpent'] ?? 0,
      status: json['status'] ?? 'pending',
      requestedAt: DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      fulfilledAt: json['fulfilledAt'] != null ? DateTime.parse(json['fulfilledAt']) : null,
      notes: json['notes'],
    );
  }
}
