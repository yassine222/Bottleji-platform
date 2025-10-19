import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/collection/data/models/collection_attempt.dart';
import 'package:botleji/features/collection/data/datasources/collection_attempt_api_client.dart';
import 'package:botleji/core/api/api_client.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/auth/data/models/user_data.dart';

// API Client Provider
final collectionAttemptApiClientProvider = Provider<CollectionAttemptApiClient>((ref) {
  final dio = ApiClientConfig.createDio();
  return CollectionAttemptApiClient(dio);
});

// Collection Attempts List Response
class CollectionAttemptsListResponse {
  final List<CollectionAttempt> attempts;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  CollectionAttemptsListResponse({
    required this.attempts,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory CollectionAttemptsListResponse.fromJson(Map<String, dynamic> json) {
    return CollectionAttemptsListResponse(
      attempts: (json['attempts'] as List)
          .map((e) => CollectionAttempt.fromJson(e))
          .toList(),
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
      hasMore: json['hasMore'],
    );
  }
}

// Collection Attempts Controller
class CollectionAttemptsController extends StateNotifier<AsyncValue<CollectionAttemptsListResponse>> {
  final CollectionAttemptApiClient _apiClient;
  final AsyncValue<UserData?> _authState;

  CollectionAttemptsController(this._apiClient, this._authState) : super(const AsyncValue.loading()) {
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    try {
      final user = _authState.value;
      if (user?.id == null) {
        state = AsyncValue.error('User not authenticated', StackTrace.current);
        return;
      }

      // For now, we'll create a simple list response
      // TODO: Implement proper API endpoint for getting collector attempts
      state = AsyncValue.data(CollectionAttemptsListResponse(
        attempts: [],
        total: 0,
        page: 1,
        limit: 10,
        hasMore: false,
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadAttempts();
  }
}

// Provider for collection attempts
final collectionAttemptsProvider = StateNotifierProvider<CollectionAttemptsController, AsyncValue<CollectionAttemptsListResponse>>((ref) {
  final apiClient = ref.watch(collectionAttemptApiClientProvider);
  final authState = ref.watch(authNotifierProvider);
  
  return CollectionAttemptsController(apiClient, authState);
});

// Provider for recent completed collections (for stats screen)
final recentCompletedCollectionsProvider = Provider<AsyncValue<List<CollectionAttempt>>>((ref) {
  final attemptsState = ref.watch(collectionAttemptsProvider);
  
  return attemptsState.when(
    data: (response) {
      // Filter for completed collections and sort by completion date
      final completedAttempts = response.attempts
          .where((attempt) => attempt.outcome == 'collected')
          .toList()
        ..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));
      
      return AsyncValue.data(completedAttempts);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
