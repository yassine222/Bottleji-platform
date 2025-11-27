import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/earnings_api_client.dart';
import '../../data/models/today_earnings.dart';
import '../../data/models/earnings_history_response.dart';
import '../../../../core/api/api_client.dart';

// API Client Provider
final earningsApiClientProvider = Provider<EarningsApiClient>((ref) {
  final dio = ApiClientConfig.createDio();
  return EarningsApiClient(dio);
});

// Today's Earnings Provider
final todayEarningsProvider = FutureProvider.autoDispose<TodayEarnings>((ref) async {
  try {
    final client = ref.watch(earningsApiClientProvider);
    return await client.getTodayEarnings();
  } catch (e) {
    // Return default values if API fails (e.g., endpoint not available yet)
    debugPrint('⚠️ Failed to fetch today earnings: $e');
    return TodayEarnings(
      sessionEarnings: 0.0,
      collectionCount: 0,
      isActive: false,
    );
  }
});

// Active Session Provider
final activeSessionProvider = FutureProvider.autoDispose<TodayEarnings>((ref) async {
  try {
    final client = ref.watch(earningsApiClientProvider);
    return await client.getActiveSession();
  } catch (e) {
    debugPrint('⚠️ Failed to fetch active session: $e');
    return TodayEarnings(
      sessionEarnings: 0.0,
      collectionCount: 0,
      isActive: false,
    );
  }
});

// Earnings History Provider
final earningsHistoryProvider = FutureProvider.autoDispose.family<EarningsHistoryResponse, Map<String, dynamic>>((ref, params) async {
  // Keep provider alive to prevent infinite refresh loops
  ref.keepAlive();
  
  try {
    debugPrint('📊 Fetching earnings history with params: $params');
    final client = ref.watch(earningsApiClientProvider);
    final page = params['page'] as int? ?? 1;
    final limit = params['limit'] as int? ?? 20;
    final result = await client.getEarningsHistory(page: page, limit: limit);
    debugPrint('✅ Earnings history fetched: ${result.sessions.length} sessions');
    return result;
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to fetch earnings history: $e');
    debugPrint('❌ Stack trace: $stackTrace');
    return EarningsHistoryResponse(
      sessions: [],
      total: 0,
      page: params['page'] as int? ?? 1,
      limit: params['limit'] as int? ?? 20,
    );
  }
});

// Total Earnings Provider
final totalEarningsProvider = FutureProvider.autoDispose<double>((ref) async {
  try {
    final client = ref.watch(earningsApiClientProvider);
    return await client.getTotalEarnings();
  } catch (e) {
    debugPrint('⚠️ Failed to fetch total earnings: $e');
    return 0.0;
  }
});

