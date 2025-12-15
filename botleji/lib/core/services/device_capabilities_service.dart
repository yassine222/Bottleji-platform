import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../api/api_client.dart' as api;

/// Service to detect and report device capabilities to backend
/// This enables the backend to make unified notification routing decisions
class DeviceCapabilitiesService {
  static final DeviceCapabilitiesService _instance = DeviceCapabilitiesService._internal();
  factory DeviceCapabilitiesService() => _instance;
  DeviceCapabilitiesService._internal();

  /// Send device capabilities to backend
  /// Should be called:
  /// 1. At app launch (after login)
  /// 2. When capabilities change (e.g., user enables/disables Live Activities)
  /// 3. When FCM token is updated
  Future<void> reportCapabilities({
    required String fcmToken,
    required bool liveActivitySupported,
    bool? dynamicIslandSupported,
    bool? supportsOngoingNotification,
    bool? supportsForegroundService,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      Map<String, dynamic> payload = {
        'fcmToken': fcmToken,
        'appVersion': appVersion,
      };

      if (Platform.isIOS) {
        // iOS capabilities
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        final iosVersion = iosInfo.systemVersion;

        payload['platform'] = 'ios';
        payload['liveActivitySupported'] = liveActivitySupported;
        payload['dynamicIslandSupported'] = dynamicIslandSupported ?? false;
        payload['iosVersion'] = iosVersion;

        debugPrint('📱 Reporting iOS capabilities:');
        debugPrint('   Live Activity: $liveActivitySupported');
        debugPrint('   Dynamic Island: ${dynamicIslandSupported ?? false}');
        debugPrint('   iOS Version: $iosVersion');
        debugPrint('   App Version: $appVersion');
      } else if (Platform.isAndroid) {
        // Android capabilities
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final androidVersion = androidInfo.version.release;

        payload['platform'] = 'android';
        payload['supportsOngoingNotification'] = supportsOngoingNotification ?? false;
        payload['supportsForegroundService'] = supportsForegroundService ?? false;
        payload['androidVersion'] = androidVersion;

        debugPrint('📱 Reporting Android capabilities:');
        debugPrint('   Ongoing Notification: ${supportsOngoingNotification ?? false}');
        debugPrint('   Foreground Service: ${supportsForegroundService ?? false}');
        debugPrint('   Android Version: $androidVersion');
        debugPrint('   App Version: $appVersion');
      } else {
        debugPrint('⚠️ Platform not supported for capability reporting');
        return;
      }

      final dio = api.ApiClientConfig.createDio();
      await dio.post(
        '${api.ApiClientConfig.baseUrl}/device-capabilities',
        data: payload,
      );

      debugPrint('✅ Device capabilities reported to backend successfully');
    } catch (e) {
      debugPrint('❌ Error reporting device capabilities: $e');
      // Don't throw - this is not critical for app functionality
    }
  }
}

