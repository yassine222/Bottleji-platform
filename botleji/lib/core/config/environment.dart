import 'server_config.dart';

enum Environment {
  dev,
  prod,
}

class EnvironmentConfig {
  static Environment environment = Environment.dev;

  static String get apiBaseUrl {
    switch (environment) {
      case Environment.dev:
        return ServerConfig.apiBaseUrl;
      case Environment.prod:
        return 'https://your-production-api.com/api'; // Replace with your production URL
    }
  }

  static bool get isDevelopment => environment == Environment.dev;
} 