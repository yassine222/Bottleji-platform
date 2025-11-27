import 'package:botleji/core/services/timezone_service.dart';

class CollectionAttempt {
  final String id;
  final String dropoffId;
  final String collectorId;
  final String status; // 'active' | 'completed'
  final String? outcome; // 'expired' | 'cancelled' | 'collected'
  final DateTime acceptedAt;
  final DateTime? completedAt;
  final int? durationMinutes;
  final DropSnapshot dropSnapshot;
  final List<TimelineEvent> timeline;
  final int attemptNumber;
  final int cancellationCount;
  final double? earnings; // Earnings for this collection (only when outcome === 'collected')
  final DateTime createdAt;
  final DateTime updatedAt;

  CollectionAttempt({
    required this.id,
    required this.dropoffId,
    required this.collectorId,
    required this.status,
    this.outcome,
    required this.acceptedAt,
    this.completedAt,
    this.durationMinutes,
    required this.dropSnapshot,
    required this.timeline,
    required this.attemptNumber,
    required this.cancellationCount,
    this.earnings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollectionAttempt.fromJson(Map<String, dynamic> json) {
    return CollectionAttempt(
      id: json['_id'] ?? json['id'],
      dropoffId: json['dropoffId'],
      collectorId: json['collectorId'],
      status: json['status'],
      outcome: json['outcome'],
      acceptedAt: TimezoneService.parseToGermanTime(json['acceptedAt']),
      completedAt: json['completedAt'] != null 
          ? TimezoneService.parseToGermanTime(json['completedAt']) 
          : null,
      durationMinutes: json['durationMinutes'],
      dropSnapshot: DropSnapshot.fromJson(json['dropSnapshot']),
      timeline: (json['timeline'] as List)
          .map((e) => TimelineEvent.fromJson(e))
          .toList(),
      attemptNumber: json['attemptNumber'],
      cancellationCount: json['cancellationCount'],
      earnings: json['earnings'] != null ? (json['earnings'] as num).toDouble() : null,
      createdAt: TimezoneService.parseToGermanTime(json['createdAt']),
      updatedAt: TimezoneService.parseToGermanTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dropoffId': dropoffId,
      'collectorId': collectorId,
      'status': status,
      'outcome': outcome,
      'acceptedAt': acceptedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'dropSnapshot': dropSnapshot.toJson(),
      'timeline': timeline.map((e) => e.toJson()).toList(),
      'attemptNumber': attemptNumber,
      'cancellationCount': cancellationCount,
      'earnings': earnings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get the display title for this attempt
  String get displayTitle {
    if (outcome == null) {
      return 'Collection in Progress';
    }
    
    switch (outcome) {
      case 'collected':
        return '✅ Collection Completed';
      case 'cancelled':
        return '❌ Collection Cancelled';
      case 'expired':
        return '⏰ Collection Expired';
      default:
        return 'Collection Attempt';
    }
  }

  /// Get the duration in a human-readable format
  String get durationDisplay {
    if (durationMinutes == null) return 'In progress';
    
    final minutes = durationMinutes!;
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '$minutes min';
    
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }
}

class DropSnapshot {
  final int numberOfBottles;
  final int numberOfCans;
  final String bottleType;
  final Map<String, double> location;
  final String? address;
  final String? notes;
  final String? imageUrl;
  final UserInfo createdBy;
  final DateTime createdAt;

  DropSnapshot({
    required this.numberOfBottles,
    required this.numberOfCans,
    required this.bottleType,
    required this.location,
    this.address,
    this.notes,
    this.imageUrl,
    required this.createdBy,
    required this.createdAt,
  });

  factory DropSnapshot.fromJson(Map<String, dynamic> json) {
    return DropSnapshot(
      numberOfBottles: json['numberOfBottles'] ?? 0,
      numberOfCans: json['numberOfCans'] ?? 0,
      bottleType: json['bottleType'] ?? 'mixed',
      location: json['location'] != null 
          ? Map<String, double>.from(json['location']) 
          : {'latitude': 0.0, 'longitude': 0.0},
      address: json['address'],
      notes: json['notes'],
      imageUrl: json['imageUrl'],
      createdBy: UserInfo.fromJson(json['createdBy'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numberOfBottles': numberOfBottles,
      'numberOfCans': numberOfCans,
      'bottleType': bottleType,
      'location': location,
      'address': address,
      'notes': notes,
      'imageUrl': imageUrl,
      'createdBy': createdBy.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int get totalItems => numberOfBottles + numberOfCans;
}

class UserInfo {
  final String id;
  final String name;
  final String email;

  UserInfo({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class TimelineEvent {
  final String event; // 'accepted' | 'cancelled' | 'expired' | 'collected'
  final DateTime timestamp;
  final UserInfo collector;
  final Map<String, dynamic> details;

  TimelineEvent({
    required this.event,
    required this.timestamp,
    required this.collector,
    required this.details,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      event: json['event'] ?? 'unknown',
      timestamp: TimezoneService.parseToGermanTime(json['timestamp']),
      collector: UserInfo.fromJson(json['collector'] ?? {}),
      details: json['details'] != null 
          ? Map<String, dynamic>.from(json['details']) 
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'timestamp': timestamp.toIso8601String(),
      'collector': collector.toJson(),
      'details': details,
    };
  }

  /// Get the display text for this event
  String get displayText {
    switch (event) {
      case 'accepted':
        return '📋 Accepted drop for collection';
      case 'cancelled':
        return '❌ Cancelled: ${details['reason'] ?? 'Unknown reason'}';
      case 'expired':
        return '⏰ Collection expired';
      case 'collected':
        return '✅ Successfully collected';
      default:
        return 'Unknown event: $event';
    }
  }
}

class CollectionAttemptListResponse {
  final List<CollectionAttempt> attempts;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  CollectionAttemptListResponse({
    required this.attempts,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory CollectionAttemptListResponse.fromJson(Map<String, dynamic> json) {
    return CollectionAttemptListResponse(
      attempts: (json['attempts'] as List)
          .map((e) => CollectionAttempt.fromJson(e))
          .toList(),
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
      totalPages: json['totalPages'],
    );
  }
}

class CollectionAttemptStats {
  final int totalAttempts;
  final int successfulCollections;
  final int cancelledAttempts;
  final int expiredAttempts;
  final int activeAttempts;
  final double averageDuration;
  final int successRate;

  CollectionAttemptStats({
    required this.totalAttempts,
    required this.successfulCollections,
    required this.cancelledAttempts,
    required this.expiredAttempts,
    required this.activeAttempts,
    required this.averageDuration,
    required this.successRate,
  });

  factory CollectionAttemptStats.fromJson(Map<String, dynamic> json) {
    return CollectionAttemptStats(
      totalAttempts: json['totalAttempts'] ?? 0,
      successfulCollections: json['successfulCollections'] ?? 0,
      cancelledAttempts: json['cancelledAttempts'] ?? 0,
      expiredAttempts: json['expiredAttempts'] ?? 0,
      activeAttempts: json['activeAttempts'] ?? 0,
      averageDuration: (json['averageDuration'] ?? 0).toDouble(),
      successRate: json['successRate'] ?? 0,
    );
  }
}
