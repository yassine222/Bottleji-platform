import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'timezone_service.dart';

/// Test function to verify German timezone conversion
void testGermanTimezone() {
  print('🕐 Testing German timezone conversion...');
  
  // Initialize timezone service
  TimezoneService.initialize();
  
  // Test current time
  final now = TimezoneService.now();
  print('🕐 Current German time: $now');
  
  // Test UTC to German conversion
  final utcTime = DateTime.utc(2024, 1, 15, 14, 30); // 2:30 PM UTC
  final germanTime = TimezoneService.toGermanTime(utcTime);
  print('🕐 UTC time: $utcTime');
  print('🕐 German time: $germanTime');
  
  // Test ISO string parsing
  final isoString = '2024-01-15T14:30:00.000Z';
  final parsedTime = TimezoneService.parseToGermanTime(isoString);
  print('🕐 ISO string: $isoString');
  print('🕐 Parsed German time: $parsedTime');
  
  // Test display formatting
  final displayString = TimezoneService.formatForDisplay(utcTime);
  print('🕐 Display format: $displayString');
  
  print('🕐 German timezone test completed!');
}
