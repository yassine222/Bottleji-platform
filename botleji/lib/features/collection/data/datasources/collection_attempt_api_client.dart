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
}
