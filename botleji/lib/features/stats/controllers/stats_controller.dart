import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:botleji/features/stats/data/models/collector_stats.dart';
import 'package:botleji/features/stats/data/models/user_drop_stats.dart';
import 'package:botleji/features/stats/data/repositories/stats_repository.dart';
import 'package:botleji/features/stats/data/datasources/stats_api_client.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/auth/data/models/user_data.dart';
import 'package:botleji/core/api/api_client.dart';
import 'package:botleji/core/api/dio_factory.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final dio = ApiClientConfig.createDio();
  final statsApiClient = StatsApiClient(dio);
  return StatsRepository(statsApiClient);
});

final collectorStatsProvider = StateNotifierProvider.family<CollectorStatsController, AsyncValue<CollectorStats>, String>((ref, timeRange) {
  final repository = ref.watch(statsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  
  return CollectorStatsController(repository, authState, timeRange);
});

final collectorHistoryProvider = StateNotifierProvider.family<CollectorHistoryController, AsyncValue<CollectorHistory>, Map<String, dynamic>>((ref, params) {
  final repository = ref.watch(statsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  
  return CollectorHistoryController(
    repository, 
    authState, 
    params['status'] as String?,
    params['timeRange'] as String?,
    params['page'] as int? ?? 1,);
});

final userDropStatsProvider = StateNotifierProvider.family<UserDropStatsController, AsyncValue<UserDropStats>, String>((ref, timeRange) {
  final repository = ref.watch(statsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  
  return UserDropStatsController(repository, authState, timeRange);
});

class CollectorStatsController extends StateNotifier<AsyncValue<CollectorStats>> {
  final StatsRepository _repository;
  final AsyncValue<UserData?> _authState;
  final String _timeRange;

  CollectorStatsController(this._repository, this._authState, this._timeRange) : super(const AsyncValue.loading()) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = _authState.value;
    if (user?.id == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final stats = await _repository.getCollectorStats(
        user!.id!,
        timeRange: _timeRange.isEmpty ? null : _timeRange,);
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadStats();
  }
}

class UserDropStatsController extends StateNotifier<AsyncValue<UserDropStats>> {
  final StatsRepository _repository;
  final AsyncValue<UserData?> _authState;
  final String _timeRange;

  UserDropStatsController(this._repository, this._authState, this._timeRange) : super(const AsyncValue.loading()) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = _authState.value;
    if (user?.id == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final stats = await _repository.getUserDropStats(
        user!.id!,
        timeRange: _timeRange.isEmpty ? 'all' : _timeRange,);
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadStats();
  }
}

class CollectorHistoryController extends StateNotifier<AsyncValue<CollectorHistory>> {
  final StatsRepository _repository;
  final AsyncValue<UserData?> _authState;
  final String? _status;
  final String? _timeRange;
  final int _page;

  CollectorHistoryController(
    this._repository, 
    this._authState, 
    this._status,
    this._timeRange,
    this._page,
  ) : super(const AsyncValue.loading()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = _authState.value;
    if (user?.id == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final history = await _repository.getCollectorHistory(
        user!.id!,
        status: _status,
        timeRange: _timeRange,
        page: _page,);
      
      // Sort interactions by most recent first
      final sortedInteractions = List<CollectorInteraction>.from(history.interactions);
      sortedInteractions.sort((a, b) => b.interactionTime.compareTo(a.interactionTime));
      
      final sortedHistory = CollectorHistory(
        interactions: sortedInteractions,
        pagination: history.pagination,);
      
      state = AsyncValue.data(sortedHistory);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadHistory();
  }

  Future<void> loadPage(int page) async {
    final user = _authState.value;
    if (user?.id == null) return;

    try {
      final history = await _repository.getCollectorHistory(
        user!.id!,
        status: _status,
        timeRange: _timeRange,
        page: page,);
      
      // Sort interactions by most recent first
      final sortedInteractions = List<CollectorInteraction>.from(history.interactions);
      sortedInteractions.sort((a, b) => b.interactionTime.compareTo(a.interactionTime));
      
      final sortedHistory = CollectorHistory(
        interactions: sortedInteractions,
        pagination: history.pagination,);
      
      state = AsyncValue.data(sortedHistory);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
} 