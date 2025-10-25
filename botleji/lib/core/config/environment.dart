import 'server_config.dart';

enum Environment {
  dev,
  prod,
}

class EnvironmentConfig {
  static Environment environment = Environment.dev;

  static Future<String> get apiBaseUrl async {
    switch (environment) {
      case Environment.dev:
        return await ServerConfig.apiBaseUrl;
      case Environment.prod:
        return 'https://your-production-api.com/api'; // Replace with your production URL
    }
  }
  
  // Synchronous fallback for backward compatibility
  static String get apiBaseUrlSync {
    switch (environment) {
      case Environment.dev:
        return 'http://192.168.1.14:3000/api'; // Fallback URL
      case Environment.prod:
        return 'https://your-production-api.com/api'; // Replace with your production URL
    }
  }

  static bool get isDevelopment => environment == Environment.dev;
} 