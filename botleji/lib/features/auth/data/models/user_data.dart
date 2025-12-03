import 'package:json_annotation/json_annotation.dart';

part 'user_data.g.dart';

enum CollectorApplicationStatus {
  pending,
  approved,
  rejected;

  static CollectorApplicationStatus fromBackendStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return CollectorApplicationStatus.pending;
      case 'approved':
        return CollectorApplicationStatus.approved;
      case 'rejected':
        return CollectorApplicationStatus.rejected;
      default:
        return CollectorApplicationStatus.pending;
    }
  }
}

@JsonSerializable()
class CollectorApplication {
  final CollectorApplicationStatus status;
  final String? idCardPhoto;
  final String? selfieWithIdPhoto;
  final String? rejectionReason;
  final DateTime? appliedAt;
  final DateTime? reviewedAt;

  const CollectorApplication({
    required this.status,
    this.idCardPhoto,
    this.selfieWithIdPhoto,
    this.rejectionReason,
    this.appliedAt,
    this.reviewedAt,
  });

  factory CollectorApplication.fromJson(Map<String, dynamic> json) =>
      _$CollectorApplicationFromJson(json);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status.name,
        'idCardPhoto': idCardPhoto,
        'selfieWithIdPhoto': selfieWithIdPhoto,
        'rejectionReason': rejectionReason,
        'appliedAt': appliedAt?.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
      };
}

@JsonSerializable()
class UserData {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final bool? isPhoneVerified;
  final bool? isEmailVerified; // Track if email is verified (for phone users who add email)
  final String? address;
  final String? profilePhoto;
  final List<String> roles;
  final String? collectorSubscriptionType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isProfileComplete;
  
  // Soft delete fields
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;
  
  // Session invalidation field
  final DateTime? sessionInvalidatedAt;

  // Account lock fields (for collectors with 5 warnings)
  final bool isAccountLocked;
  final DateTime? accountLockedUntil;
  final int warningCount;

  // Collector application status
  final CollectorApplicationStatus? collectorApplicationStatus;
  final String? collectorApplicationId;
  final DateTime? collectorApplicationAppliedAt;
  final DateTime? collectorApplicationReviewedAt;
  final String? collectorApplicationRejectionReason;
  
  // Reward system fields
  final int? currentPoints;
  final int? totalPointsEarned;
  final int? currentTier;
  final List<Map<String, dynamic>>? rewardHistory;
  
  // Earnings system fields
  final double? totalEarnings;
  final List<Map<String, dynamic>>? earningsHistory;

  const UserData({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.isPhoneVerified,
    this.isEmailVerified,
    this.address,
    this.profilePhoto,
    required this.roles,
    this.collectorSubscriptionType,
    required this.createdAt,
    required this.updatedAt,
    this.isProfileComplete = false,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    this.sessionInvalidatedAt,
    this.isAccountLocked = false,
    this.accountLockedUntil,
    this.warningCount = 0,
    this.collectorApplicationStatus,
    this.collectorApplicationId,
    this.collectorApplicationAppliedAt,
    this.collectorApplicationReviewedAt,
    this.collectorApplicationRejectionReason,
    this.currentPoints,
    this.totalPointsEarned,
    this.currentTier,
    this.rewardHistory,
    this.totalEarnings,
    this.earningsHistory,
  });

  // Helper getters for backward compatibility
  bool get isCollector => roles.contains('collector');
  bool get isHousehold => roles.contains('household');
  
  // Check if account is currently locked (lock hasn't expired yet)
  bool get isCurrentlyLocked {
    if (!isAccountLocked) return false;
    if (accountLockedUntil == null) return false;
    return DateTime.now().isBefore(accountLockedUntil!);
  }
  
  // Check if user was just unlocked (unlocked in last hour)
  bool get wasRecentlyUnlocked {
    if (isAccountLocked) return false;
    if (accountLockedUntil == null) return false;
    final now = DateTime.now();
    final hourAgo = now.subtract(const Duration(hours: 1));
    return accountLockedUntil!.isAfter(hourAgo) && accountLockedUntil!.isBefore(now);
  }

  // Check if profile is complete (use backend field if available, otherwise calculate)
  bool get isProfileCompleteCalculated {
    return name != null && 
           name!.isNotEmpty && 
           phoneNumber != null && 
           phoneNumber!.isNotEmpty && 
           address != null && 
           address!.isNotEmpty;
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility with old 'role' field
    List<String> roles = [];
    if (json['roles'] != null) {
      roles = List<String>.from(json['roles']);
    } else if (json['role'] != null) {
      // Convert old single role to roles array
      roles = [json['role']];
    } else {
      // Default to household
      roles = ['household'];
    }

    // Handle backward compatibility with old field names
    final phoneNumber = json['phoneNumber'] ?? json['phone'];
    final isPhoneVerified = json['isPhoneVerified'] as bool?;
    final isEmailVerified = json['isEmailVerified'] as bool?;
    final address = json['address'];
    final profilePhoto = json['profilePhoto'];
    final collectorSubscriptionType = json['collectorSubscriptionType'] ?? 'basic';
    
    // Handle isProfileComplete from backend
    bool isProfileComplete = false;
    if (json['isProfileComplete'] != null) {
      isProfileComplete = json['isProfileComplete'] as bool;
    }
    
    // Handle soft delete fields
    bool isDeleted = false;
    DateTime? deletedAt;
    String? deletedBy;
    DateTime? sessionInvalidatedAt;
    
    if (json['isDeleted'] != null) {
      isDeleted = json['isDeleted'] as bool;
    }
    if (json['deletedAt'] != null) {
      try {
        deletedAt = DateTime.parse(json['deletedAt'] as String);
      } catch (e) {
        deletedAt = null;
      }
    }
    if (json['deletedBy'] != null) {
      deletedBy = json['deletedBy'] as String;
    }
    if (json['sessionInvalidatedAt'] != null) {
      try {
        sessionInvalidatedAt = DateTime.parse(json['sessionInvalidatedAt'] as String);
      } catch (e) {
        sessionInvalidatedAt = null;
      }
    }
    
    // Handle account lock fields
    bool isAccountLocked = json['isAccountLocked'] ?? false;
    DateTime? accountLockedUntil;
    int warningCount = json['warningCount'] ?? 0;
    
    if (json['accountLockedUntil'] != null) {
      try {
        accountLockedUntil = DateTime.parse(json['accountLockedUntil'] as String);
      } catch (e) {
        accountLockedUntil = null;
      }
    }
    
    // Handle createdAt and updatedAt with fallbacks
    DateTime createdAt;
    DateTime updatedAt;
    try {
      createdAt = DateTime.parse(json['createdAt'] as String);
    } catch (e) {
      createdAt = DateTime.now();
    }
    try {
      updatedAt = DateTime.parse(json['updatedAt'] as String);
    } catch (e) {
      updatedAt = DateTime.now();
    }

    // Handle rewardHistory - parse it manually since it's not in generated code
    print('📊 UserData.fromJson - Raw rewardHistory from JSON: ${json['rewardHistory']}');
    print('📊 UserData.fromJson - Reward history type: ${json['rewardHistory'].runtimeType}');
    print('📊 UserData.fromJson - Reward history is null: ${json['rewardHistory'] == null}');
    
    List<Map<String, dynamic>>? rewardHistory;
    if (json['rewardHistory'] != null) {
      print('📊 UserData.fromJson - Reward history is not null, processing...');
      if (json['rewardHistory'] is List) {
        print('📊 UserData.fromJson - Reward history is a List');
        final list = json['rewardHistory'] as List;
        print('📊 UserData.fromJson - List length: ${list.length}');
        rewardHistory = list
            .map((item) {
              print('📊 UserData.fromJson - Processing item: $item (type: ${item.runtimeType})');
              return item is Map<String, dynamic> 
                  ? item 
                  : Map<String, dynamic>.from(item);
            })
            .toList();
        print('📊 UserData.fromJson - Parsed reward history: $rewardHistory');
      } else {
        print('📊 UserData.fromJson - Reward history is NOT a List, it is: ${json['rewardHistory'].runtimeType}');
      }
    } else {
      print('📊 UserData.fromJson - Reward history is null or missing');
    }
    
    print('📊 UserData.fromJson - Final rewardHistory: $rewardHistory');
    print('📊 UserData.fromJson - Final rewardHistory length: ${rewardHistory?.length ?? 0}');
    
    // Handle earningsHistory - similar to rewardHistory
    print('📊 UserData.fromJson - Raw earningsHistory from JSON: ${json['earningsHistory']}');
    print('📊 UserData.fromJson - Earnings history type: ${json['earningsHistory']?.runtimeType}');
    print('📊 UserData.fromJson - Earnings history is null: ${json['earningsHistory'] == null}');
    
    List<Map<String, dynamic>>? earningsHistory;
    if (json['earningsHistory'] != null) {
      print('📊 UserData.fromJson - Earnings history is not null, processing...');
      if (json['earningsHistory'] is List) {
        print('📊 UserData.fromJson - Earnings history is a List');
        final list = json['earningsHistory'] as List;
        print('📊 UserData.fromJson - List length: ${list.length}');
        earningsHistory = list
            .map((item) {
              print('📊 UserData.fromJson - Processing earnings item: $item (type: ${item.runtimeType})');
              return item is Map<String, dynamic> 
                  ? item 
                  : Map<String, dynamic>.from(item);
            })
            .toList();
        print('📊 UserData.fromJson - Parsed earnings history: $earningsHistory');
      } else {
        print('📊 UserData.fromJson - Earnings history is NOT a List, it is: ${json['earningsHistory'].runtimeType}');
      }
    } else {
      print('📊 UserData.fromJson - Earnings history is null or missing');
    }
    
    print('📊 UserData.fromJson - Final earningsHistory: $earningsHistory');
    print('📊 UserData.fromJson - Final earningsHistory length: ${earningsHistory?.length ?? 0}');
    
    // Handle totalEarnings
    double? totalEarnings;
    if (json['totalEarnings'] != null) {
      if (json['totalEarnings'] is double) {
        totalEarnings = json['totalEarnings'] as double;
      } else if (json['totalEarnings'] is int) {
        totalEarnings = (json['totalEarnings'] as int).toDouble();
      } else if (json['totalEarnings'] is String) {
        totalEarnings = double.tryParse(json['totalEarnings']);
      }
    }

    final userData = _$UserDataFromJson({
      ...json,
      'roles': roles,
      'phoneNumber': phoneNumber,
      'isPhoneVerified': isPhoneVerified ?? false,
      'isEmailVerified': isEmailVerified ?? false,
      'address': address,
      'profilePhoto': profilePhoto,
      'collectorSubscriptionType': collectorSubscriptionType,
      'isProfileComplete': isProfileComplete,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'sessionInvalidatedAt': sessionInvalidatedAt?.toIso8601String(),
      'isAccountLocked': isAccountLocked,
      'accountLockedUntil': accountLockedUntil?.toIso8601String(),
      'warningCount': warningCount,
      'currentPoints': json['currentPoints'],
      'totalPointsEarned': json['totalPointsEarned'],
      'currentTier': json['currentTier'],
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    });
    
    // Manually set rewardHistory since it's not in generated code
    return UserData(
      id: userData.id,
      email: userData.email,
      name: userData.name,
      phoneNumber: userData.phoneNumber,
      isPhoneVerified: userData.isPhoneVerified,
      isEmailVerified: userData.isEmailVerified,
      address: userData.address,
      profilePhoto: userData.profilePhoto,
      roles: userData.roles,
      collectorSubscriptionType: userData.collectorSubscriptionType,
      createdAt: userData.createdAt,
      updatedAt: userData.updatedAt,
      isProfileComplete: userData.isProfileComplete,
      isDeleted: userData.isDeleted,
      deletedAt: userData.deletedAt,
      deletedBy: userData.deletedBy,
      sessionInvalidatedAt: userData.sessionInvalidatedAt,
      isAccountLocked: userData.isAccountLocked,
      accountLockedUntil: userData.accountLockedUntil,
      warningCount: userData.warningCount,
      collectorApplicationStatus: userData.collectorApplicationStatus,
      collectorApplicationId: userData.collectorApplicationId,
      collectorApplicationAppliedAt: userData.collectorApplicationAppliedAt,
      collectorApplicationReviewedAt: userData.collectorApplicationReviewedAt,
      collectorApplicationRejectionReason: userData.collectorApplicationRejectionReason,
      currentPoints: userData.currentPoints,
      totalPointsEarned: userData.totalPointsEarned,
      currentTier: userData.currentTier,
      rewardHistory: rewardHistory,
      totalEarnings: totalEarnings,
      earningsHistory: earningsHistory,
    );
  }

  // Add a custom fromJson method to handle collector application status fields
  factory UserData.fromJsonWithDebug(Map<String, dynamic> json) {
    print('🔍 UserData.fromJson: Parsing user data: $json');
    print('🔍 UserData.fromJson: collectorApplicationStatus: ${json['collectorApplicationStatus']}');
    print('🔍 UserData.fromJson: collectorApplicationId: ${json['collectorApplicationId']}');
    print('🔍 UserData.fromJson: collectorApplicationAppliedAt: ${json['collectorApplicationAppliedAt']}');
    
    // Handle collector application status fields
    CollectorApplicationStatus? collectorApplicationStatus;
    if (json['collectorApplicationStatus'] != null) {
      collectorApplicationStatus = CollectorApplicationStatus.fromBackendStatus(json['collectorApplicationStatus'] as String);
      print('🔍 UserData.fromJson: Parsed collectorApplicationStatus: $collectorApplicationStatus');
    }
    
    String? collectorApplicationId = json['collectorApplicationId'] as String?;
    DateTime? collectorApplicationAppliedAt;
    DateTime? collectorApplicationReviewedAt;
    String? collectorApplicationRejectionReason = json['collectorApplicationRejectionReason'] as String?;
    
    if (json['collectorApplicationAppliedAt'] != null) {
      try {
        collectorApplicationAppliedAt = DateTime.parse(json['collectorApplicationAppliedAt'] as String);
      } catch (e) {
        print('🔍 UserData.fromJson: Error parsing collectorApplicationAppliedAt: $e');
      }
    }
    
    if (json['collectorApplicationReviewedAt'] != null) {
      try {
        collectorApplicationReviewedAt = DateTime.parse(json['collectorApplicationReviewedAt'] as String);
      } catch (e) {
        print('🔍 UserData.fromJson: Error parsing collectorApplicationReviewedAt: $e');
      }
    }
    
    // Handle backward compatibility with old 'role' field
    List<String> roles = [];
    if (json['roles'] != null) {
      roles = List<String>.from(json['roles']);
    } else if (json['role'] != null) {
      // Convert old single role to roles array
      roles = [json['role']];
    } else {
      // Default to household
      roles = ['household'];
    }

    // Handle backward compatibility with old field names
    final phoneNumber = json['phoneNumber'] ?? json['phone'];
    final address = json['address'];
    final profilePhoto = json['profilePhoto'];
    final collectorSubscriptionType = json['collectorSubscriptionType'] ?? 'basic';
    
    // Handle isProfileComplete from backend
    bool isProfileComplete = false;
    if (json['isProfileComplete'] != null) {
      isProfileComplete = json['isProfileComplete'] as bool;
    }
    
    // Handle soft delete fields
    bool isDeleted = false;
    DateTime? deletedAt;
    String? deletedBy;
    DateTime? sessionInvalidatedAt;
    
    if (json['isDeleted'] != null) {
      isDeleted = json['isDeleted'] as bool;
    }
    if (json['deletedAt'] != null) {
      try {
        deletedAt = DateTime.parse(json['deletedAt'] as String);
      } catch (e) {
        deletedAt = null;
      }
    }
    if (json['deletedBy'] != null) {
      deletedBy = json['deletedBy'] as String;
    }
    if (json['sessionInvalidatedAt'] != null) {
      try {
        sessionInvalidatedAt = DateTime.parse(json['sessionInvalidatedAt'] as String);
      } catch (e) {
        sessionInvalidatedAt = null;
      }
    }
    
    // Handle createdAt and updatedAt with fallbacks
    DateTime createdAt;
    DateTime updatedAt;
    try {
      createdAt = DateTime.parse(json['createdAt'] as String);
    } catch (e) {
      createdAt = DateTime.now();
    }
    try {
      updatedAt = DateTime.parse(json['updatedAt'] as String);
    } catch (e) {
      updatedAt = DateTime.now();
    }

    // Handle account lock fields
    bool isAccountLocked = json['isAccountLocked'] ?? false;
    DateTime? accountLockedUntil;
    int warningCount = json['warningCount'] ?? 0;
    
    print('🔍 UserData.fromJson: LOCK FIELDS:');
    print('   - isAccountLocked: ${json['isAccountLocked']} -> $isAccountLocked');
    print('   - accountLockedUntil: ${json['accountLockedUntil']}');
    print('   - warningCount: ${json['warningCount']} -> $warningCount');
    
    if (json['accountLockedUntil'] != null) {
      try {
        accountLockedUntil = DateTime.parse(json['accountLockedUntil'] as String);
        print('   - Parsed accountLockedUntil: $accountLockedUntil');
      } catch (e) {
        print('   - Error parsing accountLockedUntil: $e');
        accountLockedUntil = null;
      }
    }
    
    final userData = UserData(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      phoneNumber: phoneNumber,
      address: address,
      profilePhoto: profilePhoto,
      roles: roles,
      collectorSubscriptionType: collectorSubscriptionType,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isProfileComplete: isProfileComplete,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
      deletedBy: deletedBy,
      sessionInvalidatedAt: sessionInvalidatedAt,
      isAccountLocked: isAccountLocked,
      accountLockedUntil: accountLockedUntil,
      warningCount: warningCount,
      collectorApplicationStatus: collectorApplicationStatus,
      collectorApplicationId: collectorApplicationId,
      collectorApplicationAppliedAt: collectorApplicationAppliedAt,
      collectorApplicationReviewedAt: collectorApplicationReviewedAt,
      collectorApplicationRejectionReason: collectorApplicationRejectionReason,
    );
    print('🔍 UserData.fromJson: Created user data with application status: ${userData.collectorApplicationStatus}');
    print('🔍 UserData.fromJson: FINAL LOCK STATUS:');
    print('   - isAccountLocked: ${userData.isAccountLocked}');
    print('   - accountLockedUntil: ${userData.accountLockedUntil}');
    print('   - warningCount: ${userData.warningCount}');
    print('   - isCurrentlyLocked: ${userData.isCurrentlyLocked}');
    return userData;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'isPhoneVerified': isPhoneVerified,
        'isEmailVerified': isEmailVerified,
        'address': address,
        'profilePhoto': profilePhoto,
        'roles': roles,
        'collectorSubscriptionType': collectorSubscriptionType,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isProfileComplete': isProfileComplete,
        'isDeleted': isDeleted,
        'deletedAt': deletedAt?.toIso8601String(),
        'deletedBy': deletedBy,
        'sessionInvalidatedAt': sessionInvalidatedAt?.toIso8601String(),
        'isAccountLocked': isAccountLocked,
        'accountLockedUntil': accountLockedUntil?.toIso8601String(),
        'warningCount': warningCount,
        'collectorApplicationStatus': collectorApplicationStatus?.name,
        'collectorApplicationId': collectorApplicationId,
        'collectorApplicationAppliedAt': collectorApplicationAppliedAt?.toIso8601String(),
        'collectorApplicationReviewedAt': collectorApplicationReviewedAt?.toIso8601String(),
        'collectorApplicationRejectionReason': collectorApplicationRejectionReason,
        'currentPoints': currentPoints,
        'totalPointsEarned': totalPointsEarned,
        'currentTier': currentTier,
        'rewardHistory': rewardHistory,
        'totalEarnings': totalEarnings,
        'earningsHistory': earningsHistory,
      };

  UserData copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    bool? isEmailVerified,
    String? address,
    String? profilePhoto,
    List<String>? roles,
    String? collectorSubscriptionType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isProfileComplete,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? sessionInvalidatedAt,
  }) {
    return UserData(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      address: address ?? this.address,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      roles: roles ?? this.roles,
      collectorSubscriptionType: collectorSubscriptionType ?? this.collectorSubscriptionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      sessionInvalidatedAt: sessionInvalidatedAt ?? this.sessionInvalidatedAt,  
    );
  }
} 