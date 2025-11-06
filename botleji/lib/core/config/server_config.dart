import 'package:botleji/core/services/network_detection_service.dart';

class ServerConfig {
  // Development mode: use tunnel for fast connection, auto-detect IP for different locations
  static const bool useTunnel = false; // Set to true to use Cloudflare tunnel for remote access
  static const bool useAutoDetection = false; // Automatically detect the best IP address (disabled for physical devices)
  
  // Cloudflare tunnel URL (fast, reliable)
  static const String tunnelUrl = 'https://circuits-institutions-holds-axis.trycloudflare.com';
  
  // Fallback IPs (will be overridden by auto-detection)
  static const String fallbackServerIp = '172.20.10.12'; // Your Mac's IP when using Personal Hotspot
  static const String serverPort = '3000';
  
  // Cached detected IP
  static String? _detectedIp;
  
  // Base URLs - automatically choose the best option
  static Future<String> get serverUrl async {
    if (useTunnel) {
      return tunnelUrl;
    }
    
    if (useAutoDetection) {
      _detectedIp = await NetworkDetectionService.getOptimalServerIp();
      return 'http://$_detectedIp:$serverPort';
    }
    
    // Clear detected IP when auto-detection is disabled to ensure sync uses fallback
    _detectedIp = null;
    return 'http://$fallbackServerIp:$serverPort';
  }
  
  static Future<String> get apiBaseUrl async {
    final url = await serverUrl;
    return '$url/api';
  }
  
  // Synchronous version for backward compatibility
  static String get apiBaseUrlSync {
    // If auto-detection is disabled, always use fallback
    if (!useAutoDetection) {
      return 'http://$fallbackServerIp:$serverPort/api';
    }
    // If detected IP is localhost, use fallback (device can't connect to localhost)
    if (_detectedIp != null && _detectedIp != 'localhost') {
      return 'http://$_detectedIp:$serverPort/api';
    }
    return 'http://$fallbackServerIp:$serverPort/api';
  }
  
  // Socket URL for real-time notifications
  static Future<String> get socketUrl async => await serverUrl;
  
  // Synchronous socket URL for WebSocket connections (without /api prefix)
  static String get socketUrlSync {
    // If auto-detection is disabled, always use fallback
    if (!useAutoDetection) {
      return 'http://$fallbackServerIp:$serverPort';
    }
    // If detected IP is localhost, use fallback (device can't connect to localhost)
    if (_detectedIp != null && _detectedIp != 'localhost') {
      return 'http://$_detectedIp:$serverPort';
    }
    return 'http://$fallbackServerIp:$serverPort';
  }
  
  // Get current detected IP for debugging
  static String? get currentDetectedIp => _detectedIp;
  
  // Clear IP cache (useful when network changes)
  static void clearIpCache() {
    _detectedIp = null;
    NetworkDetectionService.clearCache();
  }
}
