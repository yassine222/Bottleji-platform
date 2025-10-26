import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TimezoneService {
  static const String germanTimezone = 'Europe/Berlin';
  static bool _initialized = false;

  /// Initialize timezone service with German timezone
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Set local timezone to Germany
    tz.setLocalLocation(tz.getLocation(germanTimezone));
    
    _initialized = true;
  }

  /// Get current time in German timezone
  static DateTime now() {
    return tz.TZDateTime.now(tz.getLocation(germanTimezone));
  }

  /// Convert UTC DateTime to German timezone
  static DateTime toGermanTime(DateTime utcDateTime) {
    DateTime result;
    if (utcDateTime.isUtc) {
      result = tz.TZDateTime.from(utcDateTime, tz.getLocation(germanTimezone));
    } else {
      // If already local, convert to UTC first then to German time
      result = tz.TZDateTime.from(utcDateTime.toUtc(), tz.getLocation(germanTimezone));
    }
    
    return result;
  }

  /// Convert German time to UTC
  static DateTime toUtc(DateTime germanDateTime) {
    if (germanDateTime is tz.TZDateTime) {
      return germanDateTime.toUtc();
    } else {
      // Treat as German time and convert to UTC
      final germanTz = tz.TZDateTime.from(germanDateTime, tz.getLocation(germanTimezone));
      return germanTz.toUtc();
    }
  }

  /// Parse ISO string and convert to German timezone
  static DateTime parseToGermanTime(String isoString) {
    final utcDateTime = DateTime.parse(isoString);
    final result = toGermanTime(utcDateTime);
    return result;
  }

  /// Format DateTime for display in German timezone
  static String formatForDisplay(DateTime dateTime) {
    final germanTime = toGermanTime(dateTime);
    return germanTime.toString();
  }

  /// Get German timezone location
  static tz.Location getGermanLocation() {
    return tz.getLocation(germanTimezone);
  }

  /// Check if timezone is initialized
  static bool get isInitialized => _initialized;
}
