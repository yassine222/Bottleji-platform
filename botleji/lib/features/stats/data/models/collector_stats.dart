class CollectorStats {
  final int accepted;
  final int collected;
  final int cancelled;
  final int expired;
  final double collectionRate;
  final int averageCollectionTime;
  final Map<String, int> cancellationReasons;
  final String timeRange;

  const CollectorStats({
    required this.accepted,
    required this.collected,
    required this.cancelled,
    required this.expired,
    required this.collectionRate,
    required this.averageCollectionTime,
    required this.cancellationReasons,
    required this.timeRange,
  });

  factory CollectorStats.fromJson(Map<String, dynamic> json) {
    return CollectorStats(
      accepted: json['accepted'] ?? 0,
      collected: json['collected'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      expired: json['expired'] ?? 0,
      collectionRate: (json['collectionRate'] ?? 0).toDouble(),
      averageCollectionTime: json['averageCollectionTime'] ?? 0,
      cancellationReasons: Map<String, int>.from(json['cancellationReasons'] ?? {}),
      timeRange: json['timeRange'] ?? '',);
  }

  Map<String, dynamic> toJson() {
    return {
      'accepted': accepted,
      'collected': collected,
      'cancelled': cancelled,
      'expired': expired,
      'collectionRate': collectionRate,
      'averageCollectionTime': averageCollectionTime,
      'cancellationReasons': cancellationReasons,
      'timeRange': timeRange,
    };
  }
}

class CollectorHistory {
  final List<CollectorInteraction> interactions;
  final PaginationInfo pagination;

  const CollectorHistory({
    required this.interactions,
    required this.pagination,
  });

  factory CollectorHistory.fromJson(Map<String, dynamic> json) {
    return CollectorHistory(
      interactions: (json['interactions'] as List?)
          ?.map((e) => CollectorInteraction.fromJson(e))
          .toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),);
  }

  Map<String, dynamic> toJson() {
    return {
      'interactions': interactions.map((e) => e.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

class CollectorInteraction {
  final String id;
  final String collectorId;
  final String dropoffId;
  final String interactionType;
  final String? cancellationReason;
  final String? notes;
  final DateTime interactionTime;
  final DropoffInfo? dropoff;
  final DateTime? acceptedAt;
  final DateTime? cancelledAt;
  final DateTime? collectedAt;
  final DateTime? expiredAt;

  const CollectorInteraction({
    required this.id,
    required this.collectorId,
    required this.dropoffId,
    required this.interactionType,
    this.cancellationReason,
    this.notes,
    required this.interactionTime,
    this.dropoff,
    this.acceptedAt,
    this.cancelledAt,
    this.collectedAt,
    this.expiredAt,
  });

  factory CollectorInteraction.fromJson(Map<String, dynamic> json) {
    try {
      // Check if dropoffId contains the actual dropoff data
      DropoffInfo? dropoffData;
      String extractedDropoffId = '';
      
      if (json['dropoffId'] is Map<String, dynamic>) {
        // dropoffId contains the actual dropoff object (populated)
        dropoffData = DropoffInfo.fromJson(json['dropoffId'] as Map<String, dynamic>);
        // Extract the ID from the populated object
        extractedDropoffId = (json['dropoffId'] as Map<String, dynamic>)['_id']?.toString() ?? 
                            (json['dropoffId'] as Map<String, dynamic>)['id']?.toString() ?? 
                            dropoffData.id;
      } else if (json['dropoffId'] is String) {
        // dropoffId is just a string ID
        extractedDropoffId = json['dropoffId']?.toString() ?? '';
      }
      
      if (json['dropoff'] is Map<String, dynamic>) {
        // dropoff field contains the dropoff object
        dropoffData = DropoffInfo.fromJson(json['dropoff'] as Map<String, dynamic>);
        // If we don't have a dropoffId yet, use the one from dropoff
        if (extractedDropoffId.isEmpty) {
          extractedDropoffId = dropoffData.id;
        }
      }

      return CollectorInteraction(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        collectorId: json['collectorId']?.toString() ?? '',
        dropoffId: extractedDropoffId,
        interactionType: json['interactionType']?.toString() ?? '',
        cancellationReason: json['cancellationReason']?.toString(),
        notes: json['notes']?.toString(),
        interactionTime: DateTime.parse(json['interactionTime']?.toString() ?? DateTime.now().toIso8601String()),
        dropoff: dropoffData,
        acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt'].toString()) : null,
        cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt'].toString()) : null,
        collectedAt: json['collectedAt'] != null ? DateTime.parse(json['collectedAt'].toString()) : null,
        expiredAt: json['expiredAt'] != null ? DateTime.parse(json['expiredAt'].toString()) : null,);
    } catch (e) {
      print('❌ Error parsing CollectorInteraction: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collectorId': collectorId,
      'dropoffId': dropoffId,
      'interactionType': interactionType,
      'cancellationReason': cancellationReason,
      'notes': notes,
      'interactionTime': interactionTime.toIso8601String(),
      'dropoff': dropoff?.toJson(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'collectedAt': collectedAt?.toIso8601String(),
      'expiredAt': expiredAt?.toIso8601String(),
    };
  }
}

class DropoffInfo {
  final String id;
  final String userId;
  final String imageUrl;
  final int numberOfBottles;
  final int numberOfCans;
  final String bottleType;
  final String? notes;
  final bool leaveOutside;
  final LocationInfo location;
  final String status;
  final String? collectorId;
  final int cancellationCount;
  final DateTime? acceptedAt;
  final bool isSuspicious;
  final List<String> cancelledByCollectorIds;
  final DateTime createdAt;

  const DropoffInfo({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.numberOfBottles,
    required this.numberOfCans,
    required this.bottleType,
    this.notes,
    required this.leaveOutside,
    required this.location,
    required this.status,
    this.collectorId,
    required this.cancellationCount,
    this.acceptedAt,
    required this.isSuspicious,
    required this.cancelledByCollectorIds,
    required this.createdAt,
  });

  factory DropoffInfo.fromJson(Map<String, dynamic> json) {
    try {
      return DropoffInfo(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString() ?? '',
        numberOfBottles: json['numberOfBottles'] ?? 0,
        numberOfCans: json['numberOfCans'] ?? 0,
        bottleType: json['bottleType']?.toString() ?? '',
        notes: json['notes']?.toString(),
        leaveOutside: json['leaveOutside'] ?? false,
        location: LocationInfo.fromJson(json['location'] ?? {}),
        status: json['status']?.toString() ?? '',
        collectorId: json['collectorId']?.toString(),
        cancellationCount: json['cancellationCount'] ?? 0,
        acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt'].toString()) : null,
        isSuspicious: json['isSuspicious'] ?? false,
        cancelledByCollectorIds: _parseStringList(json['cancelledByCollectorIds']),
        createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),);
    } catch (e) {
      print('❌ Error parsing DropoffInfo: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  // Helper method to safely parse string list
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'numberOfBottles': numberOfBottles,
      'numberOfCans': numberOfCans,
      'bottleType': bottleType,
      'notes': notes,
      'leaveOutside': leaveOutside,
      'location': location.toJson(),
      'status': status,
      'collectorId': collectorId,
      'cancellationCount': cancellationCount,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'isSuspicious': isSuspicious,
      'cancelledByCollectorIds': cancelledByCollectorIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class LocationInfo {
  final String type;
  final List<double> coordinates;

  const LocationInfo({
    required this.type,
    required this.coordinates,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      type: json['type'] ?? 'Point',
      coordinates: List<double>.from(json['coordinates'] ?? []),);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,);
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'pages': pages,
    };
  }
}

enum TimeRange {
  today,
  week,
  month,
  year,
  allTime;

  String get displayName {
    switch (this) {
      case TimeRange.today:
        return 'Today';
      case TimeRange.week:
        return 'This Week';
      case TimeRange.month:
        return 'This Month';
      case TimeRange.year:
        return 'This Year';
      case TimeRange.allTime:
        return 'All Time';
    }
  }

  String get apiValue {
    switch (this) {
      case TimeRange.today:
        return 'today';
      case TimeRange.week:
        return 'week';
      case TimeRange.month:
        return 'month';
      case TimeRange.year:
        return 'year';
      case TimeRange.allTime:
        return '';
    }
  }
}

enum InteractionStatus {
  accepted,
  collected,
  cancelled;

  String get displayName {
    switch (this) {
      case InteractionStatus.accepted:
        return 'Accepted';
      case InteractionStatus.collected:
        return 'Collected';
      case InteractionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get apiValue {
    switch (this) {
      case InteractionStatus.accepted:
        return 'ACCEPTED';
      case InteractionStatus.collected:
        return 'COLLECTED';
      case InteractionStatus.cancelled:
        return 'CANCELLED';
    }
  }
} 