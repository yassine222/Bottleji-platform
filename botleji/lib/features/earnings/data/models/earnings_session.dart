class EarningsSession {
  final String id;
  final DateTime date;
  final double sessionEarnings;
  final int collectionCount;
  final DateTime startTime;
  final DateTime lastCollectionTime;
  final bool isActive;

  EarningsSession({
    required this.id,
    required this.date,
    required this.sessionEarnings,
    required this.collectionCount,
    required this.startTime,
    required this.lastCollectionTime,
    required this.isActive,
  });

  factory EarningsSession.fromJson(Map<String, dynamic> json) {
    try {
      // Helper to safely parse dates
      DateTime parseDate(dynamic value, DateTime fallback) {
        if (value == null) return fallback;
        try {
          if (value is String) {
            return DateTime.parse(value).toLocal();
          } else if (value is DateTime) {
            return value.toLocal();
          }
        } catch (e) {
          print('⚠️ Failed to parse date: $value, error: $e');
        }
        return fallback;
      }

      // Helper to safely convert to double
      double toDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      // Helper to safely convert to int
      int toInt(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      final now = DateTime.now();
      return EarningsSession(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        date: parseDate(json['date'], now),
        sessionEarnings: toDouble(json['sessionEarnings']),
        collectionCount: toInt(json['collectionCount']),
        startTime: parseDate(json['startTime'], now),
        lastCollectionTime: parseDate(json['lastCollectionTime'], now),
        isActive: json['isActive'] == true,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing EarningsSession: $e');
      print('❌ JSON: $json');
      print('❌ Stack: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'sessionEarnings': sessionEarnings,
      'collectionCount': collectionCount,
      'startTime': startTime.toIso8601String(),
      'lastCollectionTime': lastCollectionTime.toIso8601String(),
      'isActive': isActive,
    };
  }
}

