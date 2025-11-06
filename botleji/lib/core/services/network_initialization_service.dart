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

      // Use sync version when auto-detection is disabled to avoid localhost issues
      if (!ServerConfig.useAutoDetection) {
        // Use sync fallback directly - this will use the correct fallback IP
        final syncApiUrl = ServerConfig.apiBaseUrlSync;
        _detectedApiUrl = syncApiUrl;
        // Extract server URL from API URL (remove /api)
        _detectedServerUrl = syncApiUrl.replaceAll('/api', '');
        
        print('🌐 NetworkInitializationService: Auto-detection disabled, using fallback');
        print('🌐 NetworkInitializationService: Detected server URL: $_detectedServerUrl');
        print('🌐 NetworkInitializationService: Detected API URL: $_detectedApiUrl');
      } else {
        // Detect the optimal server IP (async)
        final serverUrl = await ServerConfig.serverUrl;
        final apiUrl = await ServerConfig.apiBaseUrl;
        
        _detectedServerUrl = serverUrl;
        _detectedApiUrl = apiUrl;
        
        print('🌐 NetworkInitializationService: Detected server URL: $serverUrl');
        print('🌐 NetworkInitializationService: Detected API URL: $apiUrl');
      }
      
      print('🌐 NetworkInitializationService: Current detected IP: ${ServerConfig.currentDetectedIp}');
      
      _initialized = true;
    } catch (e) {
      print('❌ NetworkInitializationService: Error during initialization: $e');
      // Set fallback URLs
      _detectedServerUrl = 'http://172.20.10.12:3000';
      _detectedApiUrl = 'http://172.20.10.12:3000/api';
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
