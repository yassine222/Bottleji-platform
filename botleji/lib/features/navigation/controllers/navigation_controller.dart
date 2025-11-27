import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:botleji/features/collection/data/datasources/collection_attempt_api_client.dart';
import 'package:botleji/features/collection/data/models/collection_attempt.dart';
import 'package:botleji/core/api/api_client.dart' as api;
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';

class ActiveCollection {
  final String dropId;
  final LatLng destination;
  final DateTime acceptedAt;
  final String dropoffId;
  final String? imageUrl;
  final int numberOfBottles;
  final int numberOfCans;
  final String bottleType;
  final String? notes;
  final bool leaveOutside;
  final String? routeDuration;
  final String? routeDistance;
  final String collectorId; // Add collector ID field

  const ActiveCollection({
    required this.dropId,
    required this.destination,
    required this.acceptedAt,
    required this.dropoffId,
    this.imageUrl,
    required this.numberOfBottles,
    required this.numberOfCans,
    required this.bottleType,
    this.notes,
    required this.leaveOutside,
    this.routeDuration,
    this.routeDistance,
    required this.collectorId, // Add to constructor
  });

  Map<String, dynamic> toJson() {
    return {
      'dropId': dropId,
      'destination': {
        'latitude': destination.latitude,
        'longitude': destination.longitude,
      },
      'acceptedAt': acceptedAt.toIso8601String(),
      'dropoffId': dropoffId,
      'imageUrl': imageUrl,
      'numberOfBottles': numberOfBottles,
      'numberOfCans': numberOfCans,
      'bottleType': bottleType,
      'notes': notes,
      'leaveOutside': leaveOutside,
      'routeDuration': routeDuration,
      'routeDistance': routeDistance,
      'collectorId': collectorId, // Add collector ID
    };
  }

  factory ActiveCollection.fromJson(Map<String, dynamic> json) {
    return ActiveCollection(  
      dropId: json['dropId'] as String,
      destination: LatLng(
        json['destination']['latitude'] as double,
        json['destination']['longitude'] as double,
      ),
      leaveOutside: json['leaveOutside'] as bool,
      collectorId: json['collectorId'] as String,
      acceptedAt: DateTime.parse(json['acceptedAt'] as String),
      dropoffId: json['dropoffId'] as String,
      imageUrl: json['imageUrl'] as String?,
      numberOfBottles: json['numberOfBottles'] as int? ?? 0,
      numberOfCans: json['numberOfCans'] as int? ?? 0,
      bottleType: json['bottleType'] as String? ?? 'plastic',
    );
  }

  ActiveCollection copyWith({
    String? dropId,
    LatLng? destination,
    DateTime? acceptedAt,
    String? dropoffId,
    String? imageUrl,
    int? numberOfBottles,
    int? numberOfCans,
    String? bottleType,
    String? notes,
    bool? leaveOutside,
    String? routeDuration,
    String? routeDistance,
    String? collectorId, // Add collector ID parameter
  }) {
    return ActiveCollection(
      dropId: dropId ?? this.dropId,
      destination: destination ?? this.destination,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      dropoffId: dropoffId ?? this.dropoffId,
      imageUrl: imageUrl ?? this.imageUrl,
      numberOfBottles: numberOfBottles ?? this.numberOfBottles,
      numberOfCans: numberOfCans ?? this.numberOfCans,
      bottleType: bottleType ?? this.bottleType,
      notes: notes ?? this.notes,
      leaveOutside: leaveOutside ?? this.leaveOutside,
      routeDuration: routeDuration ?? this.routeDuration,
      routeDistance: routeDistance ?? this.routeDistance,
      collectorId: collectorId ?? this.collectorId, // Add collector ID
    );
  }
}

class NavigationController extends StateNotifier<ActiveCollection?> {
  static const String _activeCollectionKey = 'active_collection';
  bool _isLoading = true;
  final Ref? _ref;
  
  NavigationController([this._ref]) : super(null) {
    _loadActiveCollection();
  }

  Future<void> _loadActiveCollection() async {
    try {
      // First, try to load from local storage
      final prefs = await SharedPreferences.getInstance();
      final activeCollectionJson = prefs.getString(_activeCollectionKey);
      
      if (activeCollectionJson != null) {
        final json = Map<String, dynamic>.from(
          jsonDecode(activeCollectionJson) as Map,
        );
        state = ActiveCollection.fromJson(json);
        print('✅ Loaded active collection from local storage: ${state?.dropId}');
        _isLoading = false;
        return;
      }
      
      // If not found locally, wait for auth to be ready, then check backend
      print('ℹ️ No active collection in local storage, waiting for auth then checking backend...');
      
      // Wait for auth to be ready (with timeout)
      if (_ref != null) {
        int attempts = 0;
        while (attempts < 10) { // Try for up to 5 seconds (10 * 500ms)
          final authState = _ref.read(authNotifierProvider);
          if (authState.hasValue && authState.value?.id != null) {
            print('✅ Auth is ready, checking backend for active collection...');
            await _restoreFromBackend();
            break;
          }
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }
        
        if (attempts >= 10) {
          print('⚠️ Auth not ready after timeout, will retry when auth is available');
          // Schedule a retry when auth becomes available
          _scheduleRetryWhenAuthReady();
        }
      } else {
        print('⚠️ No ref available, cannot restore from backend');
      }
    } catch (e) {
      print('❌ Error loading active collection: $e');
      state = null;
    } finally {
      _isLoading = false;
    }
  }

  /// Schedule a retry to restore from backend when auth becomes available
  void _scheduleRetryWhenAuthReady() {
    if (_ref == null) return;
    
    // Listen to auth state changes
    _ref.listen(authNotifierProvider, (previous, next) {
      if (next.hasValue && next.value?.id != null && state == null) {
        print('✅ Auth is now ready, retrying backend restore...');
        _restoreFromBackend();
      }
    });
  }

  /// Restore active collection from backend
  Future<void> _restoreFromBackend() async {
    try {
      // Get current user ID
      String? collectorId;
      if (_ref != null) {
        final authState = _ref.read(authNotifierProvider);
        collectorId = authState.value?.id;
      }
      
      if (collectorId == null || collectorId.isEmpty) {
        print('ℹ️ No user logged in, cannot restore from backend');
        return;
      }

      print('🔍 Checking backend for active collection attempts for collector: $collectorId');
      
      // Get collection attempts from backend
      final dio = api.ApiClientConfig.createDio();
      final apiClient = CollectionAttemptApiClient(dio);
      final response = await apiClient.getCollectorAttempts(
        collectorId: collectorId,
        page: 1,
        limit: 10, // Only need the first few to find active ones
      );

      // Find the first active attempt
      final activeAttempt = response.attempts.firstWhere(
        (attempt) => attempt.status == 'active' && attempt.outcome == null,
        orElse: () => throw StateError('No active attempt found'),
      );

      print('✅ Found active collection attempt in backend: ${activeAttempt.id}');
      
      // Convert CollectionAttempt to ActiveCollection
      final dropSnapshot = activeAttempt.dropSnapshot;
      final activeCollection = ActiveCollection(
        dropId: activeAttempt.dropoffId,
        dropoffId: activeAttempt.dropoffId,
        destination: LatLng(
          dropSnapshot.location['latitude'] ?? 0.0,
          dropSnapshot.location['longitude'] ?? 0.0,
        ),
        acceptedAt: activeAttempt.acceptedAt,
        imageUrl: dropSnapshot.imageUrl,
        numberOfBottles: dropSnapshot.numberOfBottles,
        numberOfCans: dropSnapshot.numberOfCans,
        bottleType: dropSnapshot.bottleType,
        notes: dropSnapshot.notes,
        leaveOutside: false, // Default, can be updated if needed
        routeDuration: null,
        routeDistance: null,
        collectorId: activeAttempt.collectorId,
      );

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(activeCollection.toJson());
      await prefs.setString(_activeCollectionKey, jsonData);
      
      state = activeCollection;
      print('✅ Restored active collection from backend: ${activeCollection.dropId}');
    } catch (e) {
      if (e is StateError) {
        print('ℹ️ No active collection attempts found in backend');
      } else {
        print('❌ Error restoring from backend: $e');
      }
    }
  }

  Future<void> startCollection({
    required String dropId,
    required LatLng destination,
    required String dropoffId,
    String? imageUrl,
    required int numberOfBottles,
    required int numberOfCans,
    required String bottleType,
    String? notes,
    required bool leaveOutside,
    String? routeDuration,
    String? routeDistance,
    required String collectorId, // Add collector ID parameter
  }) async {
    final activeCollection = ActiveCollection(
      dropId: dropId,
      destination: destination,
      acceptedAt: DateTime.now(),
      dropoffId: dropoffId,
      imageUrl: imageUrl,
      numberOfBottles: numberOfBottles,
      numberOfCans: numberOfCans,
      bottleType: bottleType,
      notes: notes,
      leaveOutside: leaveOutside,
      routeDuration: routeDuration,
      routeDistance: routeDistance,
      collectorId: collectorId, // Add collector ID
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(activeCollection.toJson());
      await prefs.setString(_activeCollectionKey, jsonData);
      state = activeCollection;
      print('✅ Started collection: $dropId');
    } catch (e) {
      print('❌ Error saving active collection: $e');
    }
  }

  Future<void> completeCollection() async {
    try {
      final activeCollection = state;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeCollectionKey);
      state = null;
      print('✅ Completed collection');
      
      // Mark active collection activity as resolved
      if (activeCollection != null) {
        print('✅ Active collection activity marked as resolved');
      }
    } catch (e) {
      print('❌ Error completing collection: $e');
    }
  }

  Future<void> cancelCollection() async {
    try {
      final activeCollection = state;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeCollectionKey);
      state = null;
      print('✅ Cancelled collection');
      
      // Mark active collection activity as resolved
      if (activeCollection != null) {
        print('✅ Active collection activity marked as resolved');
      }
    } catch (e) {
      print('❌ Error cancelling collection: $e');
    }
  }

  Future<void> updateCollection(ActiveCollection updatedCollection) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(updatedCollection.toJson());
      await prefs.setString(_activeCollectionKey, jsonData);
      state = updatedCollection;
      print('✅ Updated active collection with route info');
    } catch (e) {
      print('❌ Error updating active collection: $e');
    }
  }

  bool get hasActiveCollection => state != null;
  bool get isLoading => _isLoading;
  
  ActiveCollection? get activeCollection => state;

  // Debug method to check SharedPreferences
  Future<void> debugCheckSavedCollection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeCollectionJson = prefs.getString(_activeCollectionKey);
      
      if (activeCollectionJson != null) {
        final json = Map<String, dynamic>.from(
          jsonDecode(activeCollectionJson) as Map,
        );
        final collection = ActiveCollection.fromJson(json);
        print('🔍 Active collection found: ${collection.dropId}');
      } else {
        print('ℹ️ No active collection found');
      }
    } catch (e) {
      print('❌ Error checking saved collection: $e');
    }
  }
}

final navigationControllerProvider = StateNotifierProvider<NavigationController, ActiveCollection?>((ref) {
  return NavigationController(ref);
});

// Separate provider for tab navigation
class TabController extends StateNotifier<int> {
  TabController() : super(0);

  void setTab(int index) {
    print('🔍 TabController: Setting tab to index $index');
    state = index;
    print('🔍 TabController: Tab set to $state');
  }
}

final tabControllerProvider = StateNotifierProvider<TabController, int>((ref) {
  return TabController();
}); 