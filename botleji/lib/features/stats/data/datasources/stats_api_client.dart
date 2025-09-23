import 'package:dio/dio.dart';
import 'package:botleji/features/stats/data/models/collector_stats.dart';
import 'package:botleji/features/stats/data/models/user_drop_stats.dart';
import 'dart:convert';

class StatsApiClient {
  final Dio _dio;

  StatsApiClient(this._dio);

  Future<CollectorStats> getCollectorStats(
    String collectorId, {
    String? timeRange,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (timeRange != null && timeRange.isNotEmpty) {
        queryParams['timeRange'] = timeRange;
      }

      final response = await _dio.get(
        '/dropoffs/collector/$collectorId/stats',
        queryParameters: queryParams,
      ); // <-- Closing parenthesis added

      return CollectorStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch collector stats: $e');
    }
  }

  Future<UserDropStats> getUserDropStats(
    String userId, {
    String? timeRange,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (timeRange != null && timeRange.isNotEmpty) {
        queryParams['timeRange'] = timeRange;
      }

      final response = await _dio.get(
        '/dropoffs/user/$userId/drop-stats',
        queryParameters: queryParams,
      ); // <-- Closing parenthesis added

      return UserDropStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch user drop stats: $e');
    }
  }

  Future<CollectorHistory> getCollectorHistory(
    String collectorId, {
    String? status,
    String? timeRange,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (timeRange != null && timeRange.isNotEmpty) {
        queryParams['timeRange'] = timeRange;
      }

      final response = await _dio.get(
        '/dropoffs/collector/$collectorId/history',
        queryParameters: queryParams,
      );

      // Debug logging
      print('History API Response Status: ${response.statusCode}');
      print('History API Response Data Type: ${response.data.runtimeType}');
      
      // Handle response data safely
      Map<String, dynamic> data;
      if (response.data is String) {
        data = json.decode(response.data as String);
        print('JSON decoded from String');
      } else if (response.data is Map<String, dynamic>) {
        data = response.data as Map<String, dynamic>;
        print('Response data already decoded');
      } else {
        print('❌ Unexpected response data type: ${response.data.runtimeType}');
        throw Exception('Unexpected response data type: ${response.data.runtimeType}');
      }

      print('History API Response Data Keys: ${data.keys.toList()}');
      
      return CollectorHistory.fromJson(data);
    } catch (e) {
      print('❌ History API Error: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to fetch collector history: $e');
    }
  }
}
