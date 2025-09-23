import 'package:dio/dio.dart';
import '../config/server_config.dart';

class DioFactory {
  /// Get a Dio instance with the configured base URL
  static Dio getDio() {
    return Dio(BaseOptions(
      baseUrl: ServerConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ));
  }

  /// Create a Dio instance with a specific base URL (for testing or custom endpoints)
  static Dio createDioWithBaseUrl(String baseUrl) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ));
  }
}
