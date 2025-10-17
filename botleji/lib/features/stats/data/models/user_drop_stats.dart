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
    return UserDropStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      collected: json['collected'] ?? 0,
      flagged: json['flagged'] ?? 0,
      stale: json['stale'] ?? 0,
      censored: json['censored'] ?? 0,
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

