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

  // Collector application status
  final CollectorApplicationStatus? collectorApplicationStatus;
  final String? collectorApplicationId;
  final DateTime? collectorApplicationAppliedAt;
  final DateTime? collectorApplicationReviewedAt;
  final String? collectorApplicationRejectionReason;

  const UserData({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.isPhoneVerified,
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
    this.collectorApplicationStatus,
    this.collectorApplicationId,
    this.collectorApplicationAppliedAt,
    this.collectorApplicationReviewedAt,
    this.collectorApplicationRejectionReason,
  });

  // Helper getters for backward compatibility
  bool get isCollector => roles.contains('collector');
  bool get isHousehold => roles.contains('household');

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

    return _$UserDataFromJson({
      ...json,
      'roles': roles,
      'phoneNumber': phoneNumber,
      'address': address,
      'profilePhoto': profilePhoto,
      'collectorSubscriptionType': collectorSubscriptionType,
      'isProfileComplete': isProfileComplete,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'sessionInvalidatedAt': sessionInvalidatedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    });
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
      collectorApplicationStatus: collectorApplicationStatus,
      collectorApplicationId: collectorApplicationId,
      collectorApplicationAppliedAt: collectorApplicationAppliedAt,
      collectorApplicationReviewedAt: collectorApplicationReviewedAt,
      collectorApplicationRejectionReason: collectorApplicationRejectionReason,
    );
    print('🔍 UserData.fromJson: Created user data with application status: ${userData.collectorApplicationStatus}');
    return userData;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'isPhoneVerified': isPhoneVerified,
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
        'collectorApplicationStatus': collectorApplicationStatus?.name,
        'collectorApplicationId': collectorApplicationId,
        'collectorApplicationAppliedAt': collectorApplicationAppliedAt?.toIso8601String(),
        'collectorApplicationReviewedAt': collectorApplicationReviewedAt?.toIso8601String(),
        'collectorApplicationRejectionReason': collectorApplicationRejectionReason,
      };

  UserData copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
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