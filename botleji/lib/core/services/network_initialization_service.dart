import 'package:botleji/core/config/server_config.dart';
import 'package:botleji/core/services/network_detection_service.dart';

class NetworkInitializationService {
  static bool _initialized = false;
  static String? _detectedServerUrl;
  static String? _detectedApiUrl;

  /// Initialize network configuration at app startup
  static Future<void> initialize() async {
    if (_initialized) return;

    print('🌐 NetworkInitializationService: Starting network detection...');
    
    try {
      // Clear any previous cache
      NetworkDetectionService.clearCache();
      ServerConfig.clearIpCache();

      // Detect the optimal server IP
      final serverUrl = await ServerConfig.serverUrl;
      final apiUrl = await ServerConfig.apiBaseUrl;
      
      _detectedServerUrl = serverUrl;
      _detectedApiUrl = apiUrl;
      
      print('🌐 NetworkInitializationService: Detected server URL: $serverUrl');
      print('🌐 NetworkInitializationService: Detected API URL: $apiUrl');
      print('🌐 NetworkInitializationService: Current detected IP: ${ServerConfig.currentDetectedIp}');
      
      _initialized = true;
    } catch (e) {
      print('❌ NetworkInitializationService: Error during initialization: $e');
      // Set fallback URLs
      _detectedServerUrl = 'http://localhost:3000';
      _detectedApiUrl = 'http://localhost:3000/api';
      _initialized = true;
    }
  }

  /// Get the detected server URL
  static String? get serverUrl => _detectedServerUrl;

  /// Get the detected API URL
  static String? get apiUrl => _detectedApiUrl;

  /// Check if network is initialized
  static bool get isInitialized => _initialized;

  /// Reinitialize network configuration (useful when network changes)
  static Future<void> reinitialize() async {
    _initialized = false;
    _detectedServerUrl = null;
    _detectedApiUrl = null;
    await initialize();
  }

  /// Get network status for debugging
  static Map<String, dynamic> getNetworkStatus() {
    return {
      'initialized': _initialized,
      'serverUrl': _detectedServerUrl,
      'apiUrl': _detectedApiUrl,
      'detectedIp': ServerConfig.currentDetectedIp,
      'useAutoDetection': ServerConfig.useAutoDetection,
      'useTunnel': ServerConfig.useTunnel,
    };
  }
}
