import 'package:botleji/core/services/network_detection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  // Development mode: use tunnel for fast connection, auto-detect IP for different locations
  static const bool useTunnel = false; // Set to true to use Cloudflare tunnel for remote access
  static const bool useAutoDetection = false; // Automatically detect the best IP address (disabled for physical devices)
  
  // Cloudflare tunnel URL (fast, reliable)
  static const String tunnelUrl = 'https://circuits-institutions-holds-axis.trycloudflare.com';
  static String? _tunnelUrlOverride; // Optional runtime override, loaded from SharedPreferences
  
  // Fallback IPs (will be overridden by auto-detection)
  static const String fallbackServerIp = '172.20.10.12'; // Your Mac's IP when using Personal Hotspot
  static const String serverPort = '3000';
  
  // Cached detected IP
  static String? _detectedIp;
  // Cache local network permission to allow sync getters to decide without async prefs
  static bool _localNetworkGranted = false;
  
  // Initialize ServerConfig caches (call once at app start)
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _localNetworkGranted = prefs.getBool('local_network_granted') ?? false;
      _tunnelUrlOverride = prefs.getString('server_tunnel_url');
    } catch (_) {
      _localNetworkGranted = false;
    }
  }
  
  // Update local network permission at runtime (called by permissions screen)
  static void setLocalNetworkGranted(bool granted) {
    _localNetworkGranted = granted;
  }
  
  // Set/clear tunnel URL override at runtime and persist
  static Future<void> setTunnelUrlOverride(String? url) async {
    _tunnelUrlOverride = (url == null || url.isEmpty) ? null : url;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_tunnelUrlOverride == null) {
        await prefs.remove('server_tunnel_url');
      } else {
        await prefs.setString('server_tunnel_url', _tunnelUrlOverride!);
      }
    } catch (_) {}
    // Changing endpoint invalidates previous IP detection cache
    clearIpCache();
  }

  // Resolve active tunnel URL (override wins)
  static String get _activeTunnelUrl => _tunnelUrlOverride ?? tunnelUrl;
  
  // Read-only accessor for other services to respect permission without async prefs
  static bool get isLocalNetworkGranted => _localNetworkGranted;
  
  // Check if we're using a tunnel (tunnel URL override or forced tunnel mode)
  static bool get isUsingTunnel {
    return _tunnelUrlOverride != null || !_localNetworkGranted || useTunnel;
  }
  
  // Base URLs - automatically choose the best option
  static Future<String> get serverUrl async {
    // If a runtime tunnel override is set, always prefer it (bypasses LAN completely)
    if (_tunnelUrlOverride != null) {
      return _activeTunnelUrl;
    }

    // If local network not granted yet, force tunnel to avoid iOS local network prompt
    if (!_localNetworkGranted) {
      return _activeTunnelUrl;
    }
    
    if (useTunnel) {
      return _activeTunnelUrl;
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
    // If a runtime tunnel override is set, always prefer it (bypasses LAN completely)
    if (_tunnelUrlOverride != null) {
      return '$_activeTunnelUrl/api';
    }

    // If local network not granted yet, force tunnel to avoid iOS local network prompt
    if (!_localNetworkGranted) {
      return '$_activeTunnelUrl/api';
    }
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
    // If a runtime tunnel override is set, always prefer it (bypasses LAN completely)
    if (_tunnelUrlOverride != null) {
      return _activeTunnelUrl;
    }

    // If local network not granted yet, force tunnel to avoid iOS local network prompt
    if (!_localNetworkGranted) {
      return _activeTunnelUrl;
    }
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
