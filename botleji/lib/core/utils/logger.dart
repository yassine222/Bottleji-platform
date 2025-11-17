import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  /// Toggle this flag to enable or disable verbose logging globally.
  /// Keep this false for better runtime performance.
  static const bool enableVerboseLogging = false;

  static void log(Object? message) {
    if (!enableVerboseLogging) return;
    if (kDebugMode) {
      debugPrint('[Bottleji] ${message ?? ''}');
    }
  }
}

