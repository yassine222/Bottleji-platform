import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import '../api/api_client.dart';
import '../constants/app_constants.dart';

// Manual provider definitions (no code generation needed)
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
}); 