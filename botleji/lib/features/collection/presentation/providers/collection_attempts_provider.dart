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

// Use the existing CollectionAttemptListResponse from the models

// Collection Attempts Controller
class CollectionAttemptsController extends StateNotifier<AsyncValue<CollectionAttemptListResponse>> {
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

      // Call the API to get collection attempts
      final response = await _apiClient.getCollectorAttempts(
        collectorId: user!.id!,
        page: 1,
        limit: 100, // Get more attempts for charts
      );
      
      state = AsyncValue.data(response);
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
final collectionAttemptsProvider = StateNotifierProvider<CollectionAttemptsController, AsyncValue<CollectionAttemptListResponse>>((ref) {
  final apiClient = ref.watch(collectionAttemptApiClientProvider);
  final authState = ref.watch(authNotifierProvider);
  
  return CollectionAttemptsController(apiClient, authState);
});

// Provider for chart data (daily collection attempts for last 7 days)
final chartDataProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiClient = ref.watch(collectionAttemptApiClientProvider);
  final authState = ref.watch(authNotifierProvider);
  
  final user = authState.value;
  if (user?.id == null) {
    throw Exception('User not authenticated');
  }
  
  final dailyData = await apiClient.getDailyCollectionAttempts(collectorId: user!.id!);
  
  return dailyData;
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
