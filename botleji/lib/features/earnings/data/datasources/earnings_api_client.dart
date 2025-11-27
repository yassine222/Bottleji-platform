import 'package:dio/dio.dart';
import '../models/today_earnings.dart';
import '../models/earnings_history_response.dart';
import '../../../../core/config/api_config.dart';

class EarningsApiClient {
  final Dio _dio;

  EarningsApiClient(this._dio);

  /// Get today's earnings
  /// GET /earnings/today
  Future<TodayEarnings> getTodayEarnings() async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrlSync}/earnings/today',
      );
      return TodayEarnings.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch today earnings: $e');
    }
  }

  /// Get active session earnings (last collection within 3 hours)
  /// GET /earnings/active
  Future<TodayEarnings> getActiveSession() async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrlSync}/earnings/active',
      );
      return TodayEarnings.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch active session: $e');
    }
  }

  /// Get earnings history
  /// GET /earnings/history?page=1&limit=20
  Future<EarningsHistoryResponse> getEarningsHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('📡 Calling earnings history API: ${ApiConfig.baseUrlSync}/earnings/history?page=$page&limit=$limit');
      final response = await _dio.get(
        '${ApiConfig.baseUrlSync}/earnings/history',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      print('✅ Earnings history API response received: ${response.statusCode}');
      print('📦 Response data: ${response.data}');
      
      if (response.data == null) {
        throw Exception('Response data is null');
      }
      
      return EarningsHistoryResponse.fromJson(response.data);
    } catch (e, stackTrace) {
      print('❌ Earnings history API error: $e');
      print('❌ Stack trace: $stackTrace');
      if (e is DioException) {
        print('❌ Dio error type: ${e.type}');
        print('❌ Dio error message: ${e.message}');
        print('❌ Dio response: ${e.response?.data}');
      }
      throw Exception('Failed to fetch earnings history: $e');
    }
  }

  /// Get total lifetime earnings
  /// GET /earnings/total
  Future<double> getTotalEarnings() async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrlSync}/earnings/total',
      );
      return (response.data['totalEarnings'] ?? 0).toDouble();
    } catch (e) {
      throw Exception('Failed to fetch total earnings: $e');
    }
  }
}

