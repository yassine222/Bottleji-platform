import 'server_config.dart';

class ApiConfig {
  static Future<String> get baseUrl async {
    return await ServerConfig.apiBaseUrl;
  }
  
  // Synchronous fallback for backward compatibility
  static String get baseUrlSync {
    return 'http://localhost:3000/api'; // Fallback URL
  }
} 