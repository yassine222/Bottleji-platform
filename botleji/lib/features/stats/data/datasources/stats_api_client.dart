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

      // Use new CollectionAttempt endpoint
      final response = await _dio.get(
        '/dropoffs/collector/$collectorId/attempts',
        queryParameters: queryParams,
      );

      // Handle response data safely
      Map<String, dynamic> data;
      if (response.data is String) {
        data = json.decode(response.data as String);
      } else if (response.data is Map<String, dynamic>) {
        data = response.data as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected response data type: ${response.data.runtimeType}');
      }
      
      // Convert CollectionAttempt data to CollectorHistory format for compatibility
      return _convertAttemptsToHistory(data);
    } catch (e) {
      print('❌ Collection Attempts API Error: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to fetch collector attempts: $e');
    }
  }

  /// Convert CollectionAttempt response to CollectorHistory format for compatibility
  CollectorHistory _convertAttemptsToHistory(Map<String, dynamic> data) {
    final attempts = data['attempts'] as List<dynamic>;
    
    // Convert attempts to interactions for backward compatibility
    final interactions = <Map<String, dynamic>>[];
    
    for (final attempt in attempts) {
      final timeline = attempt['timeline'] as List<dynamic>;
      final dropSnapshot = attempt['dropSnapshot'] as Map<String, dynamic>;
      
      // Convert dropSnapshot to DropoffInfo format
      final dropoffInfo = {
        '_id': attempt['dropoffId'],
        'userId': dropSnapshot['createdBy']?['id'] ?? '',
        'imageUrl': dropSnapshot['imageUrl'] ?? '',
        'numberOfBottles': dropSnapshot['numberOfBottles'] ?? 0,
        'numberOfCans': dropSnapshot['numberOfCans'] ?? 0,
        'bottleType': dropSnapshot['bottleType'] ?? '',
        'notes': dropSnapshot['notes'] ?? '',
        'leaveOutside': dropSnapshot['leaveOutside'] ?? false,
        'location': {
          'type': 'Point',
          'coordinates': [
            dropSnapshot['location']?['lng'] ?? 0.0,
            dropSnapshot['location']?['lat'] ?? 0.0,
          ],
        },
        'status': attempt['status'] == 'completed' ? attempt['outcome'] : 'accepted',
        'collectorId': attempt['collectorId'],
        'cancellationCount': attempt['cancellationCount'] ?? 0,
        'acceptedAt': attempt['acceptedAt'],
        'isSuspicious': false,
        'cancelledByCollectorIds': [],
        'createdAt': dropSnapshot['createdAt'],
      };
      
      // Create interaction entries for each timeline event
      for (final event in timeline) {
        interactions.add({
          '_id': '${attempt['_id']}_${event['event']}',
          'dropoffId': attempt['dropoffId'],
          'collectorId': attempt['collectorId'],
          'interactionType': event['event'],
          'interactionTime': event['timestamp'],
          'notes': event['details']?['notes'] ?? '',
          'cancellationReason': event['details']?['reason'],
          'earnings': attempt['earnings'] ?? 0, // Include earnings from collection attempt
          'dropoff': dropoffInfo,
        });
      }
    }
    
    return CollectorHistory.fromJson({
      'interactions': interactions,
      'pagination': {
        'total': data['total'],
        'page': data['page'],
        'limit': data['limit'],
        'totalPages': data['totalPages'],
      }
    });
  }
}
