class UserDropStats {
  final int total;
  final int pending;
  final int collected;
  final int flagged;
  final int stale;
  final int censored;
  final String? timeRange;

  UserDropStats({
    required this.total,
    required this.pending,
    required this.collected,
    required this.flagged,
    required this.stale,
    required this.censored,
    this.timeRange,
  });

  factory UserDropStats.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return UserDropStats(
      total: toInt(json['total']),
      pending: toInt(json['pending']),
      collected: toInt(json['collected']),
      flagged: toInt(json['flagged']),
      stale: toInt(json['stale']),
      censored: toInt(json['censored']),
      timeRange: json['timeRange'],
    );

  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'pending': pending,
      'collected': collected,
      'flagged': flagged,
      'stale': stale,
      'censored': censored,
      'timeRange': timeRange,
    };
  }
}

