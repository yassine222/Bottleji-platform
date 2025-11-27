import 'earnings_session.dart';

class EarningsHistoryResponse {
  final List<EarningsSession> sessions;
  final int total;
  final int page;
  final int limit;

  EarningsHistoryResponse({
    required this.sessions,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory EarningsHistoryResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Helper to safely convert to int
      int toInt(dynamic value, int defaultValue) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      final sessionsList = json['sessions'];
      List<EarningsSession> sessions = [];
      
      if (sessionsList != null && sessionsList is List) {
        for (var item in sessionsList) {
          try {
            if (item is Map<String, dynamic>) {
              sessions.add(EarningsSession.fromJson(item));
            }
          } catch (e) {
            print('⚠️ Failed to parse earnings session: $e');
            print('⚠️ Session data: $item');
          }
        }
      }

      return EarningsHistoryResponse(
        sessions: sessions,
        total: toInt(json['total'], 0),
        page: toInt(json['page'], 1),
        limit: toInt(json['limit'], 20),
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing EarningsHistoryResponse: $e');
      print('❌ JSON: $json');
      print('❌ Stack: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'sessions': sessions.map((e) => e.toJson()).toList(),
      'total': total,
      'page': page,
      'limit': limit,
    };
  }
}

