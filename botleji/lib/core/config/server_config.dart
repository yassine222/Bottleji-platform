import 'package:botleji/core/services/network_detection_service.dart';

class ServerConfig {
  // Development mode: use tunnel for fast connection, auto-detect IP for different locations
  static const bool useTunnel = false; // Set to true to use Cloudflare tunnel for remote access
  static const bool useAutoDetection = true; // Automatically detect the best IP address
  
  // Cloudflare tunnel URL (fast, reliable)
  static const String tunnelUrl = 'https://circuits-institutions-holds-axis.trycloudflare.com';
  
  // Fallback IPs (will be overridden by auto-detection)
  static const String fallbackServerIp = '192.168.1.14'; // Your local network IP
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
    
    return 'http://$fallbackServerIp:$serverPort';
  }
  
  static Future<String> get apiBaseUrl async {
    final url = await serverUrl;
    return '$url/api';
  }
  
  // Synchronous version for backward compatibility
  static String get apiBaseUrlSync {
    if (_detectedIp != null) {
      return 'http://$_detectedIp:$serverPort/api';
    }
    return 'http://$fallbackServerIp:$serverPort/api';
  }
  
  // Socket URL for real-time notifications
  static Future<String> get socketUrl async => await serverUrl;
  
  // Get current detected IP for debugging
  static String? get currentDetectedIp => _detectedIp;
  
  // Clear IP cache (useful when network changes)
  static void clearIpCache() {
    _detectedIp = null;
    NetworkDetectionService.clearCache();
  }
}
