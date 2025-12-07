import 'dart:io';
import 'package:flutter/material.dart';

import 'ios_activity_service.dart';
import 'android_live_activity_service.dart';

/// Data model for collection activity
class CollectionActivityData {
  final String dropId;
  final String dropAddress;
  final Duration elapsedTime; // Time elapsed since collection started
  final double distanceToDestination; // in meters
  final String? eta; // "5 min" or null
  final String transportMode; // "walking", "driving", "bicycling"
  final String estimatedValue; // "2.50 TND"
  final int progressPercentage; // 0-100

  CollectionActivityData({
    required this.dropId,
    required this.dropAddress,
    required this.elapsedTime,
    required this.distanceToDestination,
    this.eta,
    required this.transportMode,
    required this.estimatedValue,
    required this.progressPercentage,
  });
}

/// Unified service for Live Activities (iOS Dynamic Island & Android Notifications)
class LiveActivityService {
  static final LiveActivityService _instance = LiveActivityService._internal();
  factory LiveActivityService() => _instance;
  LiveActivityService._internal();

  IOSActivityService? _iosService;
  AndroidLiveActivityService? _androidService;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (Platform.isIOS) {
      _iosService = IOSActivityService();
      await _iosService?.initialize();
    } else if (Platform.isAndroid) {
      _androidService = AndroidLiveActivityService();
      await _androidService?.initialize();
    }

    _isInitialized = true;
  }

  /// Check if live activities are supported on this device
  bool isSupported() {
    if (Platform.isIOS) {
      return _iosService?.isSupported() ?? false;
    } else if (Platform.isAndroid) {
      return _androidService?.isSupported() ?? true; // Android 8.0+ supports notifications
    }
    return false;
  }

  /// Start live activity for collection
  Future<void> startCollectionActivity(CollectionActivityData data) async {
    debugPrint('🔵 LiveActivityService: Starting collection activity...');
    debugPrint('🔵 Platform: ${Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Unknown'}');
    
    if (!_isInitialized) {
      debugPrint('🔵 Service not initialized, initializing now...');
      await initialize();
    }

    debugPrint('🔵 isSupported(): ${isSupported()}');
    
    if (Platform.isIOS && _iosService != null) {
      debugPrint('🔵 Calling iOS service...');
      await _iosService!.startCollectionActivity(data);
    } else if (Platform.isAndroid && _androidService != null) {
      debugPrint('🔵 Calling Android service...');
      await _androidService!.showCollectionActivity(data);
    } else {
      debugPrint('⚠️ No service available for this platform');
      debugPrint('⚠️ iOS service: ${_iosService != null}');
      debugPrint('⚠️ Android service: ${_androidService != null}');
    }
  }

  /// Update live activity with new data
  Future<void> updateCollectionActivity(CollectionActivityData data) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (Platform.isIOS && _iosService != null) {
      await _iosService!.updateCollectionActivity(data);
    } else if (Platform.isAndroid && _androidService != null) {
      await _androidService!.updateCollectionActivity(data);
    }
  }

  /// End live activity
  Future<void> endCollectionActivity() async {
    if (Platform.isIOS && _iosService != null) {
      await _iosService!.endCollectionActivity();
    } else if (Platform.isAndroid && _androidService != null) {
      await _androidService!.dismissCollectionActivity();
    }
  }

  /// Format elapsed time as "MM:SS"
  static String formatElapsedTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format countdown time (remaining time) as "MM:SS"
  static String formatCountdownTime(Duration remainingTime) {
    if (remainingTime.isNegative || remainingTime.inSeconds <= 0) {
      return '00:00';
    }
    final minutes = remainingTime.inMinutes;
    final seconds = remainingTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format distance in meters to readable string
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
  
  // MARK: - Drop Timeline Activity (Household Mode)
  
  /// Start drop timeline activity
  Future<void> startDropTimelineActivity({
    required String dropId,
    required String dropAddress,
    required String estimatedValue,
    required String status,
    required String statusText,
    String? collectorName,
    required String timeAgo,
    required String createdAt,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (Platform.isIOS && _iosService != null) {
      await _iosService!.startDropTimelineActivity(
        dropId: dropId,
        dropAddress: dropAddress,
        estimatedValue: estimatedValue,
        status: status,
        statusText: statusText,
        collectorName: collectorName,
        timeAgo: timeAgo,
        createdAt: createdAt,
      );
    } else if (Platform.isAndroid && _androidService != null) {
      // Android implementation can use persistent notification
      // For now, we'll skip Android for drop timeline
      debugPrint('⚠️ Drop Timeline not yet implemented for Android');
    }
  }
  
  /// Update drop timeline activity
  Future<void> updateDropTimelineActivity({
    required String status,
    required String statusText,
    String? collectorName,
    required String timeAgo,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (Platform.isIOS && _iosService != null) {
      await _iosService!.updateDropTimelineActivity(
        status: status,
        statusText: statusText,
        collectorName: collectorName,
        timeAgo: timeAgo,
      );
    }
  }
  
  /// End drop timeline activity
  Future<void> endDropTimelineActivity({String? dropId}) async {
    if (Platform.isIOS && _iosService != null) {
      await _iosService!.endDropTimelineActivity(dropId: dropId);
    }
  }
  
  /// Format time ago string
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }
  
  /// Get status text from DropStatus
  static String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Created';
      case 'accepted':
        return 'Accepted';
      case 'on_way':
        return 'On his way';
      case 'collected':
        return 'Collected';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

