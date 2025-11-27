import 'package:botleji/features/collection/data/models/collection_attempt.dart';
import 'package:botleji/features/drops/domain/utils/drop_value_calculator.dart';

/// Utility class for calculating collection session values
class CollectionSessionCalculator {
  /// Default inactivity timeout for session (3 hours)
  static const Duration sessionInactivityTimeout = Duration(hours: 3);

  /// Calculates total value for all collections completed today
  /// 
  /// Returns the sum of estimated values for all collections
  /// where outcome == 'collected' and completedAt is today
  static double calculateTodayTotalValue(List<CollectionAttempt> attempts) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final todayCollections = attempts.where((attempt) {
      if (attempt.outcome != 'collected') return false;
      if (attempt.completedAt == null) return false;
      return attempt.completedAt!.isAfter(todayStart);
    }).toList();

    return _calculateTotalValue(todayCollections);
  }

  /// Calculates total value for active session
  /// 
  /// Session starts from the earliest accepted drop today
  /// and includes all collections completed since then,
  /// as long as the last collection was within the inactivity timeout.
  /// 
  /// Returns null if no active session (no recent activity)
  static double? calculateActiveSessionValue(List<CollectionAttempt> attempts) {
    if (attempts.isEmpty) return null;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Get all completed collections from today
    final todayCompleted = attempts.where((attempt) {
      if (attempt.outcome != 'collected') return false;
      if (attempt.completedAt == null) return false;
      return attempt.completedAt!.isAfter(todayStart);
    }).toList();

    if (todayCompleted.isEmpty) return null;

    // Sort by completion time (most recent first)
    todayCompleted.sort((a, b) {
      final aTime = a.completedAt ?? a.updatedAt;
      final bTime = b.completedAt ?? b.updatedAt;
      return bTime.compareTo(aTime);
    });

    // Check if most recent collection is within inactivity timeout
    final mostRecent = todayCompleted.first;
    final mostRecentTime = mostRecent.completedAt ?? mostRecent.updatedAt;
    final timeSinceLastCollection = now.difference(mostRecentTime);

    // If last collection was too long ago, no active session
    if (timeSinceLastCollection > sessionInactivityTimeout) {
      return null;
    }

    // Find session start (earliest accepted drop today)
    final todayAccepted = attempts.where((attempt) {
      return attempt.acceptedAt.isAfter(todayStart);
    }).toList();

    if (todayAccepted.isEmpty) return null;

    final sessionStart = todayAccepted
        .map((a) => a.acceptedAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    // Include all collections completed after session start
    final sessionCollections = todayCompleted.where((attempt) {
      final completedTime = attempt.completedAt ?? attempt.updatedAt;
      return completedTime.isAfter(sessionStart) || 
             completedTime.isAtSameMomentAs(sessionStart);
    }).toList();

    return _calculateTotalValue(sessionCollections);
  }

  /// Counts number of completed collections today
  static int countTodayCollections(List<CollectionAttempt> attempts) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    return attempts.where((attempt) {
      if (attempt.outcome != 'collected') return false;
      if (attempt.completedAt == null) return false;
      return attempt.completedAt!.isAfter(todayStart);
    }).length;
  }

  /// Calculates total value from a list of collection attempts
  static double _calculateTotalValue(List<CollectionAttempt> attempts) {
    double total = 0.0;

    for (final attempt in attempts) {
      final snapshot = attempt.dropSnapshot;
      final value = DropValueCalculator.calculateEstimatedValue(
        plasticBottleCount: snapshot.numberOfBottles,
        cansCount: snapshot.numberOfCans,
      );
      total += value;
    }

    return double.parse(total.toStringAsFixed(2));
  }

  /// Checks if collector has an active session (recent activity)
  static bool hasActiveSession(List<CollectionAttempt> attempts) {
    return calculateActiveSessionValue(attempts) != null;
  }
}
