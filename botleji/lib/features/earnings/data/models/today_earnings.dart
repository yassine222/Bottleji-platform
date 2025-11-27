class TodayEarnings {
  final double sessionEarnings;
  final int collectionCount;
  final bool isActive;
  final DateTime? startTime;
  final DateTime? lastCollectionTime;

  TodayEarnings({
    required this.sessionEarnings,
    required this.collectionCount,
    required this.isActive,
    this.startTime,
    this.lastCollectionTime,
  });

  factory TodayEarnings.fromJson(Map<String, dynamic> json) {
    return TodayEarnings(
      sessionEarnings: (json['sessionEarnings'] ?? 0).toDouble(),
      collectionCount: json['collectionCount'] ?? 0,
      isActive: json['isActive'] ?? false,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime']).toLocal()
          : null,
      lastCollectionTime: json['lastCollectionTime'] != null
          ? DateTime.parse(json['lastCollectionTime']).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionEarnings': sessionEarnings,
      'collectionCount': collectionCount,
      'isActive': isActive,
      'startTime': startTime?.toIso8601String(),
      'lastCollectionTime': lastCollectionTime?.toIso8601String(),
    };
  }
}

