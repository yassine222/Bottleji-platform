class UserDropStats {
  final int total;
  final int pending;
  final int accepted;
  final int collected;
  final int cancelled;
  final int expired;
  final String? timeRange;

  UserDropStats({
    required this.total,
    required this.pending,
    required this.accepted,
    required this.collected,
    required this.cancelled,
    required this.expired,
    this.timeRange,
  });

  factory UserDropStats.fromJson(Map<String, dynamic> json) {
    return UserDropStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      accepted: json['accepted'] ?? 0,
      collected: json['collected'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      expired: json['expired'] ?? 0,
      timeRange: json['timeRange'],
    );

  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'pending': pending,
      'accepted': accepted,
      'collected': collected,
      'cancelled': cancelled,
      'expired': expired,
      'timeRange': timeRange,
    };
  }
}

