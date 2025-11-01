import 'package:flutter/material.dart';

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
    final currentTierData = json['currentTier'];
    final currentTier = currentTierData is Map ? (currentTierData['tier'] ?? 1) : (currentTierData ?? 1);
    final currentPoints = json['currentPoints'] ?? 0;
    final totalPoints = json['totalPoints'] ?? 0;
    final totalCollections = json['totalCollections'] ?? 0;
    
    print('🎯 RewardStats.fromJson: Extracted currentTier: $currentTier');
    print('🎯 RewardStats.fromJson: Extracted currentPoints: $currentPoints');
    print('🎯 RewardStats.fromJson: Extracted totalPoints: $totalPoints');
    print('🎯 RewardStats.fromJson: Extracted totalCollections: $totalCollections');
    
    return RewardStats(
      totalDropsCollected: totalCollections,
      totalDropsCreated: totalCollections, // Same as collected for now
      totalPointsEarned: totalPoints,
      currentPoints: currentPoints,
      currentTier: currentTier,
      rewardHistory: (json['recentRedemptions'] as List<dynamic>?)
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
  final bool isFootwear;
  final bool isJacket;
  final bool isBottoms;
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
    required this.isFootwear,
    required this.isJacket,
    required this.isBottoms,
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
      isFootwear: json['isFootwear'] ?? false,
      isJacket: json['isJacket'] ?? false,
      isBottoms: json['isBottoms'] ?? false,
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
      'isFootwear': isFootwear,
      'isJacket': isJacket,
      'isBottoms': isBottoms,
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

class DeliveryAddress {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String phoneNumber;
  final String? additionalNotes;

  DeliveryAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.phoneNumber,
    this.additionalNotes,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      country: json['country'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      additionalNotes: json['additionalNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'phoneNumber': phoneNumber,
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
    };
  }
}

enum RedemptionStatus {
  pending('pending'),
  approved('approved'),
  processing('processing'),
  shipped('shipped'),
  delivered('delivered'),
  cancelled('cancelled'),
  rejected('rejected');

  const RedemptionStatus(this.value);
  final String value;

  static RedemptionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return RedemptionStatus.pending;
      case 'approved':
        return RedemptionStatus.approved;
      case 'processing':
        return RedemptionStatus.processing;
      case 'shipped':
        return RedemptionStatus.shipped;
      case 'delivered':
        return RedemptionStatus.delivered;
      case 'cancelled':
        return RedemptionStatus.cancelled;
      case 'rejected':
        return RedemptionStatus.rejected;
      default:
        return RedemptionStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case RedemptionStatus.pending:
        return 'Pending';
      case RedemptionStatus.approved:
        return 'Approved';
      case RedemptionStatus.processing:
        return 'Processing';
      case RedemptionStatus.shipped:
        return 'Shipped';
      case RedemptionStatus.delivered:
        return 'Delivered';
      case RedemptionStatus.cancelled:
        return 'Cancelled';
      case RedemptionStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case RedemptionStatus.pending:
        return Colors.orange;
      case RedemptionStatus.approved:
        return Colors.blue;
      case RedemptionStatus.processing:
        return Colors.purple;
      case RedemptionStatus.shipped:
        return Colors.indigo;
      case RedemptionStatus.delivered:
        return Colors.green;
      case RedemptionStatus.cancelled:
        return Colors.grey;
      case RedemptionStatus.rejected:
        return Colors.red;
    }
  }
}

class RewardRedemption {
  final String id;
  final String userId;
  final String rewardItemId;
  final String rewardItemName;
  final int pointsSpent;
  final RedemptionStatus status;
  final DeliveryAddress deliveryAddress;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? processingAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? rejectedAt;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;
  final String? adminNotes;
  final String? rejectionReason;
  final String? selectedSize;
  final String? sizeType;

  RewardRedemption({
    required this.id,
    required this.userId,
    required this.rewardItemId,
    required this.rewardItemName,
    required this.pointsSpent,
    required this.status,
    required this.deliveryAddress,
    required this.createdAt,
    this.approvedAt,
    this.processingAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.rejectedAt,
    this.trackingNumber,
    this.estimatedDelivery,
    this.adminNotes,
    this.rejectionReason,
    this.selectedSize,
    this.sizeType,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    return RewardRedemption(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      rewardItemId: json['rewardItemId'] is Map ? json['rewardItemId']['_id'] ?? json['rewardItemId']['id'] ?? '' : json['rewardItemId'] ?? '',
      rewardItemName: json['rewardItemName'] ?? '',
      pointsSpent: json['pointsSpent'] ?? 0,
      status: RedemptionStatus.fromString(json['status'] ?? 'pending'),
      deliveryAddress: DeliveryAddress.fromJson(json['deliveryAddress'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      processingAt: json['processingAt'] != null ? DateTime.parse(json['processingAt']) : null,
      shippedAt: json['shippedAt'] != null ? DateTime.parse(json['shippedAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
      rejectedAt: json['rejectedAt'] != null ? DateTime.parse(json['rejectedAt']) : null,
      trackingNumber: json['trackingNumber'],
      estimatedDelivery: json['estimatedDelivery'] != null ? DateTime.parse(json['estimatedDelivery']) : null,
      adminNotes: json['adminNotes'],
      rejectionReason: json['rejectionReason'],
      selectedSize: json['selectedSize'],
      sizeType: json['sizeType'],
    );
  }
}
