import 'package:dio/dio.dart';
import 'package:botleji/features/collection/data/models/collection_attempt.dart';
import 'dart:convert';

class CollectionAttemptApiClient {
  final Dio _dio;

  CollectionAttemptApiClient(this._dio);

  /// Create a new collection attempt when collector accepts a drop
  Future<CollectionAttempt> createCollectionAttempt({
    required String dropoffId,
    required String collectorId,
  }) async {
    try {
      final response = await _dio.post(
        '/dropoffs/$dropoffId/attempts',
        data: {
          'collectorId': collectorId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      return CollectionAttempt.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create collection attempt: $e');
    }
  }

  /// Complete a collection attempt (expired, cancelled, or collected)
  Future<CollectionAttempt> completeCollectionAttempt({
    required String attemptId,
    required String dropoffId,
    required String outcome,
    String? reason,
    String? notes,
    Map<String, double>? location,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'outcome': outcome,
      };

      if (reason != null) data['reason'] = reason;
      if (notes != null) data['notes'] = notes;
      if (location != null) data['location'] = location;

      final response = await _dio.patch(
        '/dropoffs/$dropoffId/attempts/$attemptId/complete',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      return CollectionAttempt.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to complete collection attempt: $e');
    }
  }

  /// Get all collection attempts for a collector (with pagination)
  Future<CollectionAttemptListResponse> getCollectorAttempts({
    required String collectorId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/dropoffs/collector/$collectorId/attempts',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return CollectionAttemptListResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch collector attempts: $e');
    }
  }

  /// Get all collection attempts for a specific drop
  Future<List<CollectionAttempt>> getDropoffAttempts({
    required String dropoffId,
  }) async {
    try {
      final response = await _dio.get('/dropoffs/$dropoffId/attempts');

      final List<dynamic> data = response.data;
      return data.map((json) => CollectionAttempt.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch dropoff attempts: $e');
    }
  }

  /// Get collection attempt statistics for a collector
  Future<CollectionAttemptStats> getCollectionAttemptStats({
    required String collectorId,
  }) async {
    try {
      final response = await _dio.get(
        '/dropoffs/collector/$collectorId/attempts/stats',
      );

      return CollectionAttemptStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch collection attempt stats: $e');
    }
  }

  /// Get daily collection attempts for charts (last 7 days)
  Future<List<Map<String, dynamic>>> getDailyCollectionAttempts({
    required String collectorId,
  }) async {
    try {
      final response = await _dio.get(
        '/dropoffs/collector/$collectorId/attempts/daily',
        queryParameters: {
          'days': 7,
        },
      );

      // Return the data as a list of daily counts
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('dailyData')) {
          return List<Map<String, dynamic>>.from(data['dailyData']);
        }
      }
      
      // If no data, return empty list
      return [];
    } catch (e) {
      print('📊 Chart API: Error fetching daily attempts: $e');
      // Return mock data for development
      return _generateMockDailyData();
    }
  }

  /// Generate mock data for development/testing
  List<Map<String, dynamic>> _generateMockDailyData() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> mockData = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      
      mockData.add({
        'date': dateStr,
        'collected': (i % 3 == 0) ? 2 : (i % 2 == 0) ? 1 : 0,
        'cancelled': (i % 4 == 0) ? 1 : 0,
        'expired': (i % 5 == 0) ? 1 : 0,
      });
    }
    
    print('📊 Chart API: Using mock data for development');
    return mockData;
  }
}
