import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:botleji/core/utils/json_converters.dart';
import 'package:botleji/core/services/timezone_service.dart';
import 'package:botleji/l10n/app_localizations.dart';
import 'package:botleji/features/drops/domain/utils/drop_value_calculator.dart';

enum BottleType {
  plastic,
  can,
  mixed,
}

/// Extension to provide localized display names for BottleType
extension BottleTypeLocalization on BottleType {
  /// Returns the localized display name for this bottle type
  String localizedDisplayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case BottleType.plastic:
        return l10n.plastic;
      case BottleType.can:
        return l10n.can;
      case BottleType.mixed:
        return l10n.mixed;
    }
  }
}

enum DropStatus {
  pending,    // Drop is created and waiting for collection
  accepted,   // A collector has accepted to collect this drop
  collected,  // Drop has been collected
  cancelled,  // Drop was cancelled by the household
  expired,    // Drop expired because it wasn't collected within time limit
  stale,      // Drop is too old and likely collected by external collectors
}

/// Extension to provide localized display names for DropStatus
extension DropStatusLocalization on DropStatus {
  /// Returns the localized display name for this status
  String localizedDisplayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case DropStatus.pending:
        return l10n.pendingStatus;
      case DropStatus.accepted:
        return l10n.acceptedStatus;
      case DropStatus.collected:
        return l10n.collectedStatus;
      case DropStatus.cancelled:
        return l10n.cancelledStatus;
      case DropStatus.expired:
        return l10n.expiredStatus;
      case DropStatus.stale:
        return l10n.staleStatus;
    }
  }
}

enum CancellationReason {
  noAccess,
  notFound,
  alreadyCollected,
  wrongLocation,
  unsafe,
  other;

  String get displayName {
    switch (this) {
      case CancellationReason.noAccess:
        return 'No Access';
      case CancellationReason.notFound:
        return 'Not Found';
      case CancellationReason.alreadyCollected:
        return 'Already Collected';
      case CancellationReason.wrongLocation:
        return 'Wrong Location';
      case CancellationReason.unsafe:
        return 'Unsafe Area';
      case CancellationReason.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case CancellationReason.noAccess:
        return 'Cannot access the drop location';
      case CancellationReason.notFound:
        return 'Drop was not found at the specified location';
      case CancellationReason.alreadyCollected:
        return 'Drop has already been collected by someone else';
      case CancellationReason.wrongLocation:
        return 'Location information was incorrect';
      case CancellationReason.unsafe:
        return 'Area is unsafe or dangerous';
      case CancellationReason.other:
        return 'Other reason';
    }
  }
}

class Drop {
  final String id;
  final String userId;
  final String imageUrl;
  final int numberOfBottles;
  final int numberOfCans;
  final BottleType bottleType;
  final String? notes;
  final bool leaveOutside;
  final LatLng location;
  final DropStatus status;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? collectedAt;
  final int cancellationCount;
  final bool isSuspicious;
  final String? suspiciousReason;
  final bool isCensored;
  final String? censorReason;
  final DateTime? censoredAt;
  final CancellationReason? cancellationReason;
  final List<String> cancelledByCollectorIds;

  /// Calculated estimated value of the drop in TND
  /// Formula: (numberOfBottles * 0.03) + (numberOfCans * 0.15)
  double get estimatedValue => DropValueCalculator.calculateEstimatedValue(
        plasticBottleCount: numberOfBottles,
        cansCount: numberOfCans,
      );

  const Drop({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.numberOfBottles,
    required this.numberOfCans,
    required this.bottleType,
    this.notes,
    required this.leaveOutside,
    required this.location,
    this.status = DropStatus.pending,
    required this.createdAt,
    required this.modifiedAt,
    this.collectedAt,
    this.cancellationCount = 0,
    this.isSuspicious = false,
    this.suspiciousReason,
    this.isCensored = false,
    this.censorReason,
    this.censoredAt,
    this.cancellationReason,
    this.cancelledByCollectorIds = const [],
  });

  // Empty sentinel used for safe optional returns
  factory Drop.empty() => Drop(
    id: '',
    userId: '',
    imageUrl: '',
    numberOfBottles: 0,
    numberOfCans: 0,
    bottleType: BottleType.plastic,
    leaveOutside: false,
    location: const LatLng(0, 0),
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
    collectedAt: null,
    isSuspicious: false,
    isCensored: false,
  );

  factory Drop.fromJson(Map<String, dynamic> json) {
    return Drop(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      numberOfBottles: json['numberOfBottles'] as int? ?? 0,
      numberOfCans: json['numberOfCans'] as int? ?? 0,
      bottleType: BottleType.values.firstWhere(
        (e) => e.name == (json['bottleType']?.toString() ?? 'plastic'),
        orElse: () => BottleType.plastic,
      ),
      notes: json['notes']?.toString(),
      leaveOutside: json['leaveOutside'] as bool? ?? false,
      location: LatLngConverter().fromJson(json['location'] ?? {}),
      status: DropStatus.values.firstWhere(
        (e) => e.name == (json['status']?.toString() ?? 'pending'),
        orElse: () => DropStatus.pending,
      ),
      createdAt: _parseDate(json['createdAt']) ?? TimezoneService.now(),
      modifiedAt: _parseDate(json['updatedAt']) ?? TimezoneService.now(),
      collectedAt: _parseDate(json['collectedAt']),
      cancellationCount: json['cancellationCount'] as int? ?? 0,
      isSuspicious: json['isSuspicious'] as bool? ?? false,
      suspiciousReason: json['suspiciousReason']?.toString(),
      isCensored: json['isCensored'] as bool? ?? false,
      censorReason: json['censorReason']?.toString(),
      censoredAt: json['censoredAt'] != null ? DateTime.tryParse(json['censoredAt'].toString()) : null,
      cancellationReason: json['cancellationReason'] != null ? CancellationReason.values.firstWhere(
        (e) => e.name == json['cancellationReason'].toString(),
        orElse: () => CancellationReason.other,
      ) : null,
      cancelledByCollectorIds: (json['cancelledByCollectorIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'numberOfBottles': numberOfBottles,
      'numberOfCans': numberOfCans,
      'bottleType': bottleType.name,
      'notes': notes,
      'leaveOutside': leaveOutside,
      'location': LatLngConverter().toJson(location),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': modifiedAt.toIso8601String(),
      'collectedAt': collectedAt?.toIso8601String(),
      'cancellationCount': cancellationCount,
      'isSuspicious': isSuspicious,
      'suspiciousReason': suspiciousReason,
      'isCensored': isCensored,
      'censorReason': censorReason,
      'censoredAt': censoredAt?.toIso8601String(),
      'cancellationReason': cancellationReason?.name,
      'cancelledByCollectorIds': cancelledByCollectorIds,
    };
  }

  Drop copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    int? numberOfBottles,
    int? numberOfCans,
    BottleType? bottleType,
    String? notes,
    bool? leaveOutside,
    LatLng? location,
    DropStatus? status,
    DateTime? createdAt,
    DateTime? modifiedAt,
    DateTime? collectedAt,
    int? cancellationCount,
    bool? isSuspicious,
    String? suspiciousReason,
    bool? isCensored,
    String? censorReason,
    DateTime? censoredAt,
    CancellationReason? cancellationReason,
    List<String>? cancelledByCollectorIds,
  }) {
    return Drop(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      numberOfBottles: numberOfBottles ?? this.numberOfBottles,
      numberOfCans: numberOfCans ?? this.numberOfCans,
      bottleType: bottleType ?? this.bottleType,
      notes: notes ?? this.notes,
      leaveOutside: leaveOutside ?? this.leaveOutside,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      collectedAt: collectedAt ?? this.collectedAt,
      cancellationCount: cancellationCount ?? this.cancellationCount,
      isSuspicious: isSuspicious ?? this.isSuspicious,
      suspiciousReason: suspiciousReason ?? this.suspiciousReason,
      isCensored: isCensored ?? this.isCensored,
      censorReason: censorReason ?? this.censorReason,
      censoredAt: censoredAt ?? this.censoredAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledByCollectorIds: cancelledByCollectorIds ?? this.cancelledByCollectorIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Drop &&
        other.id == id &&
        other.userId == userId &&
        other.imageUrl == imageUrl &&
        other.numberOfBottles == numberOfBottles &&
        other.numberOfCans == numberOfCans &&
        other.bottleType == bottleType &&
        other.notes == notes &&
        other.leaveOutside == leaveOutside &&
        other.location == location &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.modifiedAt == modifiedAt &&
        other.collectedAt == collectedAt &&
        other.cancellationCount == cancellationCount &&
        other.isSuspicious == isSuspicious &&
        other.suspiciousReason == suspiciousReason &&
        other.isCensored == isCensored &&
        other.censorReason == censorReason &&
        other.cancellationReason == cancellationReason &&
        other.cancelledByCollectorIds == cancelledByCollectorIds;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      imageUrl,
      numberOfBottles,
      numberOfCans,
      bottleType,
      notes,
      leaveOutside,
      location,
      status,
      createdAt,
      modifiedAt,
      collectedAt,
      cancellationCount,
      isSuspicious,
      suspiciousReason,
      isCensored,
      censorReason,
      cancellationReason,
      cancelledByCollectorIds,
    );
  }

  @override
  String toString() {
    return 'Drop(id: $id, userId: $userId, imageUrl: $imageUrl, numberOfBottles: $numberOfBottles, numberOfCans: $numberOfCans, bottleType: $bottleType, notes: $notes, leaveOutside: $leaveOutside, location: $location, status: $status, createdAt: $createdAt, modifiedAt: $modifiedAt, collectedAt: $collectedAt, cancellationCount: $cancellationCount, isSuspicious: $isSuspicious, cancellationReason: $cancellationReason, cancelledByCollectorIds: $cancelledByCollectorIds)';
  }
} 

DateTime? _parseDate(dynamic rawValue) {
  if (rawValue == null) return null;

  try {
    if (rawValue is DateTime) {
      return TimezoneService.toGermanTime(rawValue);
    }

    if (rawValue is String) {
      if (rawValue.isEmpty) return null;
      return TimezoneService.parseToGermanTime(rawValue);
    }

    if (rawValue is Map<String, dynamic>) {
      dynamic value = rawValue['\$date'] ?? rawValue['date'] ?? rawValue['iso'];

      if (value is Map<String, dynamic>) {
        if (value.containsKey('\$numberLong')) {
          final millisString = value['\$numberLong']?.toString();
          if (millisString != null) {
            final millis = int.tryParse(millisString);
            if (millis != null) {
              return TimezoneService.toGermanTime(DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true));
            }
          }
        } else if (value.containsKey('_seconds')) {
          final secondsRaw = value['_seconds'];
          final nanosRaw = value['_nanoseconds'] ?? 0;
          if (secondsRaw is num) {
            final seconds = secondsRaw.toDouble();
            final nanos = nanosRaw is num ? nanosRaw.toDouble() : 0;
            final millis = (seconds * 1000).round() + (nanos / 1000000).round();
            final dateTime = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
            return TimezoneService.toGermanTime(dateTime);
          }
        }
        // Attempt to parse nested iso string
        final nestedIso = value['iso'] ?? value['\$date'];
        if (nestedIso is String) {
          return TimezoneService.parseToGermanTime(nestedIso);
        }
      }

      if (value is String) {
        return TimezoneService.parseToGermanTime(value);
      }

      // Fallback: try known Mongo style keys
      if (rawValue.containsKey('_seconds')) {
        final secondsRaw = rawValue['_seconds'];
        final nanosRaw = rawValue['_nanoseconds'] ?? 0;
        if (secondsRaw is num) {
          final seconds = secondsRaw.toDouble();
          final nanos = nanosRaw is num ? nanosRaw.toDouble() : 0;
          final millis = (seconds * 1000).round() + (nanos / 1000000).round();
          final dateTime = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
          return TimezoneService.toGermanTime(dateTime);
        }
      }
    }
  } catch (_) {
    return null;
  }

  return null;
}