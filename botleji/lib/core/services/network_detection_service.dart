import 'dart:io';
import 'package:botleji/core/config/server_config.dart';
import 'package:http/http.dart' as http;

class NetworkDetectionService {
  static String? _cachedIp;
  static DateTime? _lastDetection;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Automatically detects the best server IP to use
  static Future<String> getOptimalServerIp() async {
    // Do not probe local network unless user explicitly granted it
    try {
      // Lazy import to avoid circular import at top
      // ignore: avoid_dynamic_calls
      // Use ServerConfig static to check permission cache
      // We reference via mirrors to keep file decoupled (simple direct import is fine too in this project)
    } catch (_) {}
    // Import directly (project keeps config light)
    // If local network not granted, return fallback immediately to avoid triggering iOS prompt
    // This relies on ServerConfig.init() having run in main()
    if (!ServerConfig.isLocalNetworkGranted) {
      return ServerConfig.fallbackServerIp;
    }
    // Return cached result if still valid
    if (_cachedIp != null && 
        _lastDetection != null && 
        DateTime.now().difference(_lastDetection!) < _cacheTimeout) {
      return _cachedIp!;
    }

    try {
      // Try multiple methods to detect the best IP
      final detectedIp = await _detectBestIp();
      _cachedIp = detectedIp;
      _lastDetection = DateTime.now();
      return detectedIp;
    } catch (e) {
      print('❌ NetworkDetectionService: Error detecting IP: $e');
      // Fallback to localhost if detection fails
      return 'localhost';
    }
  }

  /// Detects the best IP using multiple methods
  static Future<String> _detectBestIp() async {
    // Method 1: Try to get local network IP
    try {
      final localIp = await _getLocalNetworkIp();
      if (localIp != null && await _testConnection(localIp)) {
        print('🌐 NetworkDetectionService: Using local network IP: $localIp');
        return localIp;
      }
    } catch (e) {
      print('❌ NetworkDetectionService: Local IP detection failed: $e');
    }

    // Method 2: Try common local IPs (Personal Hotspot IP first)
    final commonIps = ['172.20.10.12', '192.168.0.207', '192.168.1.14', '192.168.1.100', '192.168.0.100', '10.0.0.100'];
    for (final ip in commonIps) {
      if (await _testConnection(ip)) {
        print('🌐 NetworkDetectionService: Using common IP: $ip');
        return ip;
      }
    }

    // Method 3: Try to get external IP and use it
    try {
      final externalIp = await _getExternalIp();
      if (externalIp != null && await _testConnection(externalIp)) {
        print('🌐 NetworkDetectionService: Using external IP: $externalIp');
        return externalIp;
      }
    } catch (e) {
      print('❌ NetworkDetectionService: External IP detection failed: $e');
    }

    // Fallback to localhost
    print('🌐 NetworkDetectionService: Falling back to localhost');
    return 'localhost';
  }

  /// Gets local network IP address
  static Future<String?> _getLocalNetworkIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final ip = addr.address;
            // Filter out common non-routable IPs
            if (!ip.startsWith('169.254.') && 
                !ip.startsWith('127.') && 
                ip != '0.0.0.0') {
              return ip;
            }
          }
        }
      }
    } catch (e) {
      print('❌ NetworkDetectionService: Error getting local IP: $e');
    }
    return null;
  }

  /// Gets external IP address
  static Future<String?> _getExternalIp() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.ipify.org'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      print('❌ NetworkDetectionService: Error getting external IP: $e');
    }
    return null;
  }

  /// Tests if a connection to the server is possible
  static Future<bool> _testConnection(String ip) async {
    try {
      final socket = await Socket.connect(ip, 3000, timeout: const Duration(seconds: 3));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clears the cached IP (useful when network changes)
  static void clearCache() {
    _cachedIp = null;
    _lastDetection = null;
  }

  /// Gets the current cached IP
  static String? get currentIp => _cachedIp;
}
