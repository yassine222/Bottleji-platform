import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'package:botleji/features/drops/data/repositories/drop_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/core/services/live_activity_service.dart';
import 'package:botleji/features/drops/domain/utils/drop_value_calculator.dart';

final dropsControllerProvider = StateNotifierProvider<DropsController, AsyncValue<List<Drop>>>((ref) {
  return DropsController(ref.watch(dropRepositoryProvider));
});

final dropRepositoryProvider = Provider<DropRepository>((ref) {
  return DropRepository();
});

// Provider for pending drops count (for collector badge)
final pendingDropsCountProvider = Provider<int>((ref) {
  final dropsState = ref.watch(dropsControllerProvider);
  final userMode = ref.watch(userModeControllerProvider);
  
  return userMode.when(
    data: (mode) {
      if (mode != UserMode.collector) return 0;
      
      return dropsState.when(
        data: (drops) => drops.where((drop) => drop.status == DropStatus.pending).length,
        loading: () => 0,
        error: (_, __) => 0,
      );
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Provider for initial filter when navigating to Drops tab
final dropsInitialFilterProvider = StateProvider<String?>((ref) => null);

// Provider for user drops count (for household badge)
final userDropsCountProvider = Provider<int>((ref) {
  final dropsState = ref.watch(dropsControllerProvider);
  final userMode = ref.watch(userModeControllerProvider);
  
  return userMode.when(
    data: (mode) {
      if (mode != UserMode.household) return 0;
      
      return dropsState.when(
        data: (drops) => drops.where((d) => 
          !d.isSuspicious && 
          !d.isCensored && 
          d.cancellationCount < 3 &&
          (d.status == DropStatus.pending || d.status == DropStatus.accepted) &&
          d.status != DropStatus.stale
        ).length,
        loading: () => 0,
        error: (_, __) => 0,
      );
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});


class DropsController extends StateNotifier<AsyncValue<List<Drop>>> {
  final DropRepository _repository;

  DropsController(this._repository) : super(const AsyncValue.loading());

  Future<void> loadDrops() async {
    state = const AsyncValue.loading();
    try {
      final drops = await _repository.getDrops();
      state = AsyncValue.data(drops);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> loadAllDrops() async {
    state = const AsyncValue.loading();
    try {
      final drops = await _repository.getDrops();
      state = AsyncValue.data(drops);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> loadDropsAvailableForCollectors({String? excludeCollectorId}) async {
    state = const AsyncValue.loading();
    try {
      // print('🔍 Loading drops available for collectors...');
      // print('🔍 excludeCollectorId: $excludeCollectorId');
      
      final drops = await _repository.getDropsAvailableForCollectors(excludeCollectorId: excludeCollectorId);
      
      // print('🔍 Drops loaded: ${drops.length}');
      // print('🔍 Drops details: ${drops.map((d) => '${d.id}: ${d.status.name}').toList()}');
      
      state = AsyncValue.data(drops);
    } catch (e) {
      // print('❌ Error loading drops: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> loadDropsAcceptedByCollector(String collectorId) async {
    state = const AsyncValue.loading();
    try {
      final drops = await _repository.getDropsAcceptedByCollector(collectorId);
      state = AsyncValue.data(drops);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> loadDropsByStatus(String status) async {
    state = const AsyncValue.loading();
    try {
      final drops = await _repository.getDropsByStatus(status);
      state = AsyncValue.data(drops);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> loadUserDrops(String userId) async {
    if (userId.isEmpty) {
      // print('🔍 User ID is empty, returning empty list');
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      // print('🔍 Loading drops for user: $userId');
      
      final drops = await _repository.getDropsByUser(userId);
      
      // print('🔍 User drops loaded: ${drops.length}');
      // print('🔍 User drops details: ${drops.map((d) => '${d.id}: ${d.status.name}').toList()}');
      
      state = AsyncValue.data(drops);
    } catch (e) {
      // print('❌ Error loading user drops: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> clearDrops() async {
    state = const AsyncValue.data([]);
  }

  // Method to get user drops for support without affecting global state
  Future<List<Drop>> getUserDropsForSupport(String userId) async {
    if (userId.isEmpty) {
      return [];
    }
    
    try {
      final drops = await _repository.getDropsByUser(userId);
      return drops;
    } catch (e) {
      debugPrint('❌ Error loading user drops for support: $e');
      return [];
    }
  }

  Future<Drop?> createDrop({
    required String userId,
    required String imagePath,
    required int numberOfBottles,
    required int numberOfCans,
    required BottleType bottleType,
    String? notes,
    required bool leaveOutside,
    required LatLng location,
  }) async {
    try {
      final drop = await _repository.createDrop(
        userId: userId,
        imagePath: imagePath,
        numberOfBottles: numberOfBottles,
        numberOfCans: numberOfCans,
        bottleType: bottleType,
        notes: notes,
        leaveOutside: leaveOutside,
        location: location,
      );

      // Add the new drop to the current list
      state.whenData((drops) {
        state = AsyncValue.data([drop, ...drops]);
      });

      return drop;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  Future<void> updateDropStatus(String dropId, DropStatus status) async {
    try {
      final updatedDrop = await _repository.updateDropStatus(dropId, status);
      
      // Update the drop in the current list
      state.whenData((drops) {
        final updatedDrops = drops.map((drop) {
          if (drop.id == dropId) {
            return updatedDrop;
          }
          return drop;
        }).toList();
        state = AsyncValue.data(updatedDrops);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateDrop(Drop drop) async {
    try {
      final updatedDrop = await _repository.updateDrop(drop);
      
      // Update the drop in the current list
      state.whenData((drops) {
        final updatedDrops = drops.map((d) {
          if (d.id == drop.id) {
            return updatedDrop;
          }
          return d;
        }).toList();
        state = AsyncValue.data(updatedDrops);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteDrop(String dropId) async {
    try {
      await _repository.deleteDrop(dropId);
      
      // Remove the drop from the current list
      state.whenData((drops) {
        final updatedDrops = drops.where((drop) => drop.id != dropId).toList();
        state = AsyncValue.data(updatedDrops);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> assignCollector(String dropId, String collectorId) async {
    try {
      final updatedDrop = await _repository.assignCollector(dropId, collectorId);
      
      // Update the drop in the current list
      state.whenData((drops) {
        final updatedDrops = drops.map((drop) {
          if (drop.id == dropId) {
            return updatedDrop;
          }
          return drop;
        }).toList();
        state = AsyncValue.data(updatedDrops);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> confirmCollection(String dropId) async {
    try {
      final response = await _repository.confirmCollection(dropId);
      final updatedDrop = Drop.fromJson(response);
      
      // Update the drop in the current list
      state.whenData((drops) {
        final updatedDrops = drops.map<Drop>((drop) {
          if (drop.id == dropId) {
            return updatedDrop;
          }
          return drop;
        }).toList();
        state = AsyncValue.data(updatedDrops);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<Map<String, dynamic>?> confirmCollectionWithRewards(String dropId) async {
    try {
      final response = await _repository.confirmCollection(dropId);
      
      // Update the drop in the current list
      state.whenData((drops) {
        final updatedDrops = drops.map<Drop>((drop) {
          if (drop.id == dropId) {
            return Drop.fromJson(response); // Parse the response as a Drop
          }
          return drop;
        }).toList();
        state = AsyncValue.data(updatedDrops);
      });

      // Return the response which now contains rewardData from the backend
      return response;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  /// Handle real-time drop status updates from WebSocket notifications
  void handleDropStatusUpdate(String dropId, String status, Map<String, dynamic> data) {
    debugPrint('🔄 DropsController: Handling drop status update - $status for drop $dropId');
    
    state.whenData((drops) async {
      final updatedDrops = drops.map((drop) {
        if (drop.id == dropId) {
          // Update drop status based on notification
          DropStatus newStatus;
          switch (status) {
            case 'drop_accepted':
              newStatus = DropStatus.accepted;
              break;
            case 'drop_collected':
              newStatus = DropStatus.collected;
              break;
            case 'drop_cancelled':
              newStatus = DropStatus.cancelled;
              break;
            case 'drop_expired':
              newStatus = DropStatus.expired;
              break;
            default:
              return drop; // No change needed
          }
          
          // Create updated drop with new status
          final updatedDrop = drop.copyWith(status: newStatus);
          debugPrint('🔄 DropsController: Updated drop $dropId status to ${newStatus.name}');
          
          // Update drop timeline Live Activity (household mode only)
          _updateDropTimelineActivity(updatedDrop, data);
          
          return updatedDrop;
        }
        return drop;
      }).toList();
      
      state = AsyncValue.data(updatedDrops);
      debugPrint('🔄 DropsController: Drop list updated with new status');
    });
  }
  
  /// Update drop timeline Live Activity
  Future<void> _updateDropTimelineActivity(Drop drop, Map<String, dynamic>? notificationData) async {
    try {
      // Note: We can't access ref here, so we'll check user mode in the caller
      // For now, we'll update the activity regardless and let the service handle platform checks
      
      final liveActivityService = LiveActivityService();
      await liveActivityService.initialize();
      
      // Determine status and status text
      String statusKey = drop.status.name;
      String statusText = LiveActivityService.getStatusText(statusKey);
      
      // Get collector name if available (for accepted/on_way status)
      String? collectorName;
      if (drop.status == DropStatus.accepted || statusKey == 'on_way') {
        // Try to get collector name from notification data or drop
        if (notificationData != null && notificationData['collectorName'] != null) {
          collectorName = notificationData['collectorName'] as String;
        } else if (notificationData != null && notificationData['collectorId'] != null) {
          // Fetch collector name by ID
          final collectorInfo = await getUserInfo(notificationData['collectorId'] as String);
          collectorName = collectorInfo?['name'] as String?;
        }
      }
      
      // Update or end activity based on status
      if (drop.status == DropStatus.collected || 
          drop.status == DropStatus.expired || 
          drop.status == DropStatus.cancelled) {
        // End activity for final states
        await liveActivityService.endDropTimelineActivity(dropId: drop.id);
      } else {
        // Update activity for intermediate states
        await liveActivityService.updateDropTimelineActivity(
          status: statusKey,
          statusText: statusText,
          collectorName: collectorName,
          timeAgo: LiveActivityService.formatTimeAgo(drop.modifiedAt),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error updating drop timeline Live Activity: $e');
    }
  }

  Future<void> cancelAcceptedDrop(String dropId, String reason, String cancelledByCollectorId) async {
    try {
      await _repository.cancelAcceptedDrop(dropId, reason, cancelledByCollectorId);
      
      // Update the drop status in the current list
      state.whenData((drops) {
        final updatedDrops = drops.map((drop) {
          if (drop.id == dropId) {
            return drop.copyWith(status: DropStatus.cancelled);
          }
          return drop;
        }).toList();
        state = AsyncValue.data(updatedDrops);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      return await _repository.getUserById(userId);
    } catch (e) {
      return null;
    }
  }

  // Check for expired drops and track them
  Future<void> checkAndTrackExpiredDrops(String userId) async {
    try {
      state.whenData((drops) async {
        final now = DateTime.now();
        final expiredDrops = drops.where((drop) {
          // Check if drop is expired (assuming drops expire after 24 hours)
          final dropAge = now.difference(drop.createdAt);
          return dropAge.inHours >= 24 && drop.status == DropStatus.pending;
        }).toList();

        // Activity tracking removed
      });
    } catch (e) {
      print('Error checking expired drops: $e');
    }
  }

  // Track collection attempt
  Future<void> trackCollectionAttempt({
    required String userId,
    required String dropId,
    required bool success,
    String? errorMessage,
  }) async {
    // Activity tracking removed
  }
} 