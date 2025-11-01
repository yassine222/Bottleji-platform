import 'package:dio/dio.dart';
import '../config/server_config.dart';

class DioFactory {
  static Dio? _cachedDio;
  static String? _cachedBaseUrl;
  
  /// Get a Dio instance with the configured base URL (async version)
  static Future<Dio> getDio() async {
    final baseUrl = await ServerConfig.apiBaseUrl;
    
    // Return cached instance if base URL hasn't changed
    if (_cachedDio != null && _cachedBaseUrl == baseUrl) {
      return _cachedDio!;
    }
    
    _cachedDio = Dio(BaseOptions(
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
    
    _cachedBaseUrl = baseUrl;
    return _cachedDio!;
  }
  
  /// Get a Dio instance with the configured base URL (sync version - uses fallback)
  static Dio getDioSync() {
    return Dio(BaseOptions(
      baseUrl: ServerConfig.apiBaseUrlSync, // Fallback URL
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
