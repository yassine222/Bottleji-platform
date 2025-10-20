import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:botleji/features/stats/data/models/collector_stats.dart';
import 'package:botleji/features/stats/controllers/stats_controller.dart';
import 'package:botleji/features/stats/data/repositories/stats_repository.dart';
import 'package:botleji/features/stats/data/datasources/stats_api_client.dart';
import 'package:botleji/features/auth/data/models/user_data.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';

// Provider for the history controller - using a single instance
final historyControllerProvider = StateNotifierProvider<HistoryController, AsyncValue<CollectorHistory>>((ref) {
  final repository = ref.watch(statsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  
  return HistoryController(
    ref,
    repository,
    authState,
  );
});

class HistoryController extends StateNotifier<AsyncValue<CollectorHistory>> {
  final Ref _ref;
  final StatsRepository _repository;
  final AsyncValue<UserData?> _authState;
  
  String? _currentStatus;
  String? _currentTimeRange;
  bool _isLoading = false;

  HistoryController(
    this._ref,
    this._repository,
    this._authState,
  ) : super(const AsyncValue.loading()) {
    // Don't auto-load on creation, wait for explicit load call
  }

  Future<void> loadHistory({String? status, String? timeRange}) async {
    // Prevent multiple simultaneous requests
    if (_isLoading) return;
    
    // Check if we need to reload (parameters changed)
    if (status == _currentStatus && timeRange == _currentTimeRange && state.hasValue) {
      return; // Already loaded with same parameters
    }

    _currentStatus = status;
    _currentTimeRange = timeRange;
    
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = _authState.value;
    if (user?.id == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return;
    }

    if (_isLoading) return;
    _isLoading = true;

    try {
      state = const AsyncValue.loading();
      
      // Convert time range to API format
      String? apiTimeRange = _convertTimeRangeToApiFormat(_currentTimeRange);
      
      final history = await _repository.getCollectorHistory(
        user!.id!,
        status: _currentStatus,
        timeRange: apiTimeRange,
        );
      
      // Sort interactions by most recent first
      final sortedInteractions = List<CollectorInteraction>.from(history.interactions);
      sortedInteractions.sort((a, b) => b.interactionTime.compareTo(a.interactionTime));
      
      final sortedHistory = CollectorHistory(
        interactions: sortedInteractions,
        pagination: history.pagination,
        );
      state = AsyncValue.data(sortedHistory);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    } finally {
      _isLoading = false;
    }
  }

  String? _convertTimeRangeToApiFormat(String? timeRange) {
    if (timeRange == null) return null;
    
    switch (timeRange) {
      case 'Today':
        return 'today';
      case 'Last 7 Days':
        return 'week';
      case 'Last 30 Days':
        return 'month';
      case 'Last 3 Months':
        return 'quarter';
      case 'Last 6 Months':
        return 'half_year';
      case 'This Year':
        return 'year';
      default:
        return null;
    }
  }

  Future<void> refresh() async {
    print('🔍 History: Refresh method called');
    // Force refresh with current parameters
    _isLoading = false; // Reset loading state
    await _loadHistory();
  }

  Future<void> loadMore() async {
    if (_isLoading) return;
    
    try {
      final currentHistory = state.value;
      if (currentHistory == null) return;

      final nextPage = currentHistory.pagination.page + 1;
      if (nextPage > currentHistory.pagination.pages) return;

      final user = _authState.value;
      if (user?.id == null) return;

      _isLoading = true;

      // Convert time range to API format
      String? apiTimeRange = _convertTimeRangeToApiFormat(_currentTimeRange);

      final moreHistory = await _repository.getCollectorHistory(
        user!.id!,
        status: _currentStatus,
        timeRange: apiTimeRange,
        page: nextPage,
        );

      final updatedInteractions = [
        ...currentHistory.interactions,
        ...moreHistory.interactions,
      ];

      // Sort all interactions by most recent first
      updatedInteractions.sort((a, b) => b.interactionTime.compareTo(a.interactionTime));

      final updatedHistory = CollectorHistory(
        interactions: updatedInteractions,
        pagination: moreHistory.pagination,
        );
      state = AsyncValue.data(updatedHistory);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> filterByStatus(String? status) async {
    await loadHistory(status: status, timeRange: _currentTimeRange);
  }

  Future<void> filterByTimeRange(String? timeRange) async {
    await loadHistory(status: _currentStatus, timeRange: timeRange);
  }

  // Getter to check if currently loading
  bool get isLoading => _isLoading;
} 