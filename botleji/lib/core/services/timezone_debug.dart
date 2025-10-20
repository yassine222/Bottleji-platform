import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'timezone_service.dart';

/// Debug function to test timezone conversion
void debugTimezoneConversion() {
  print('🕐 === TIMEZONE DEBUG ===');
  
  // Initialize timezone service
  TimezoneService.initialize();
  
  // Test 1: Current time
  final now = TimezoneService.now();
  final deviceNow = DateTime.now();
  print('🕐 Device time: $deviceNow');
  print('🕐 German time: $now');
  print('🕐 Difference: ${now.difference(deviceNow).inHours} hours');
  
  // Test 2: UTC to German conversion
  final utcTime = DateTime.utc(2024, 1, 15, 22, 33); // 22:33 UTC
  final germanTime = TimezoneService.toGermanTime(utcTime);
  print('🕐 UTC time: $utcTime');
  print('🕐 German time: $germanTime');
  print('🕐 Expected: Should be 23:33 or 00:33 depending on DST');
  
  // Test 3: ISO string parsing
  final isoString = '2024-01-15T22:33:00.000Z';
  final parsedTime = TimezoneService.parseToGermanTime(isoString);
  print('🕐 ISO string: $isoString');
  print('🕐 Parsed German time: $parsedTime');
  
  // Test 4: Format for display
  final displayString = TimezoneService.formatForDisplay(utcTime);
  print('🕐 Display format: $displayString');
  
  print('🕐 === END DEBUG ===');
}
