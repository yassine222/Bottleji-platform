import 'package:botleji/features/stats/data/datasources/stats_api_client.dart';
import 'package:botleji/features/stats/data/models/collector_stats.dart';
import 'package:botleji/features/stats/data/models/user_drop_stats.dart';

class StatsRepository {
  final StatsApiClient _apiClient;

  StatsRepository(this._apiClient);

  Future<CollectorStats> getCollectorStats(
    String collectorId, {
    String? timeRange,
  }) async {
    return await _apiClient.getCollectorStats(
      collectorId,
      timeRange: timeRange,
      );
  }

  Future<CollectorHistory> getCollectorHistory(
    String collectorId, {
    String? status,
    String? timeRange,
    int page = 1,
    int limit = 20,
  }) async {
    return await _apiClient.getCollectorHistory(
      collectorId,
      status: status,
      timeRange: timeRange,
      page: page,
      limit: limit,
    );

  }

  Future<UserDropStats> getUserDropStats(
    String userId, {
    String? timeRange,
  }) async {
    return await _apiClient.getUserDropStats(
      userId,
      timeRange: timeRange,);
  }
} 