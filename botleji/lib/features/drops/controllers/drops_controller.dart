import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'package:botleji/features/drops/data/repositories/drop_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/core/services/live_activities_package_service.dart';
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
      
      // End drop timeline Live Activity if active
      try {
        final liveActivityService = LiveActivitiesPackageService();
        await liveActivityService.initialize();
        await liveActivityService.endDropTimelineActivity(dropId: dropId);
        debugPrint('✅ Drop Timeline Live Activity ended for deleted drop: $dropId');
      } catch (e) {
        debugPrint('⚠️ Error ending Drop Timeline Live Activity for deleted drop: $e');
        // Don't fail the deletion if Live Activity cleanup fails
      }
      
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
      
      // Update Live Activity when collector is assigned (status changes to accepted)
      if (updatedDrop.status == DropStatus.accepted) {
        debugPrint('🔄 assignCollector: Updating Live Activity for accepted drop $dropId');
        await _updateDropTimelineActivity(updatedDrop, {'collectorId': collectorId});
      }
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
      
      // End Live Activity since drop is now collected (do this after state update)
      if (updatedDrop.status == DropStatus.collected) {
        debugPrint('🔄 confirmCollection: Ending Live Activity for collected drop $dropId');
        await _updateDropTimelineActivity(updatedDrop, null);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<Map<String, dynamic>?> confirmCollectionWithRewards(String dropId) async {
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
      
      // End Live Activity since drop is now collected (do this after state update)
      if (updatedDrop.status == DropStatus.collected) {
        debugPrint('🔄 confirmCollectionWithRewards: Ending Live Activity for collected drop $dropId');
        await _updateDropTimelineActivity(updatedDrop, null);
      }

      // Return the response which now contains rewardData from the backend
      return response;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  /// Handle real-time drop status updates from WebSocket notifications
  Future<void> handleDropStatusUpdate(String dropId, String status, Map<String, dynamic> data) async {
    debugPrint('🔄 DropsController: Handling drop status update - $status for drop $dropId');
    
    // For critical status changes (especially drop_accepted), fetch the full drop from backend
    // to ensure we have all the latest data (collector info, timestamps, etc.)
    if (status == 'drop_accepted') {
      debugPrint('🔄 DropsController: Fetching full drop data from backend for drop_accepted');
      try {
        // Fetch the updated drop from backend
        final updatedDrop = await _repository.getDropById(dropId);
        if (updatedDrop != null) {
          debugPrint('✅ DropsController: Fetched updated drop from backend: ${updatedDrop.status.name}');
          
          // Update the drop in the list
          state.whenData((drops) {
            final updatedDrops = drops.map((drop) {
              if (drop.id == dropId) {
                return updatedDrop;
              }
              return drop;
            }).toList();
            
            state = AsyncValue.data(updatedDrops);
            debugPrint('🔄 DropsController: Drop list updated with full drop data from backend');
            
            // Update drop timeline Live Activity (household mode only)
            debugPrint('🔄 DropsController: Updating Live Activity for drop ${updatedDrop.id} with status ${updatedDrop.status.name}');
            _updateDropTimelineActivity(updatedDrop, data).catchError((e) {
              debugPrint('❌ Error updating Live Activity from handleDropStatusUpdate: $e');
            });
          });
          
          return;
        } else {
          debugPrint('⚠️ DropsController: Could not fetch drop from backend, falling back to local update');
        }
      } catch (e) {
        debugPrint('❌ DropsController: Error fetching drop from backend: $e, falling back to local update');
      }
    }
    
    // Fallback: Update status locally for other status changes or if backend fetch fails
    state.whenData((drops) {
      Drop? updatedDrop;
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
          updatedDrop = drop.copyWith(
            status: newStatus,
            modifiedAt: DateTime.now(), // Update modified timestamp
          );
          debugPrint('🔄 DropsController: Updated drop $dropId status to ${newStatus.name} (local update)');
          
          return updatedDrop!;
        }
        return drop;
      }).toList();
      
      state = AsyncValue.data(updatedDrops);
      debugPrint('🔄 DropsController: Drop list updated with new status');
      
      // Note: Live Activity updates are handled via APNs push notifications from the backend
      // The backend sends push notifications when drop status changes (drop_accepted, drop_collected, etc.)
      // We don't need to update locally here - the push notification will update the widget
      debugPrint('🔄 DropsController: Live Activity will be updated via push notification from backend');
    });
  }
  
  /// Update drop timeline Live Activity
  Future<void> _updateDropTimelineActivity(Drop drop, Map<String, dynamic>? notificationData) async {
    try {
      debugPrint('🔄 _updateDropTimelineActivity: Starting update for drop ${drop.id}, status: ${drop.status.name}');
      
      final liveActivityService = LiveActivitiesPackageService();
      await liveActivityService.initialize();
      
      // Determine status and status text
      String statusKey = drop.status.name;
      String statusText = LiveActivitiesPackageService.getStatusText(statusKey);
      debugPrint('🔄 _updateDropTimelineActivity: Status key: $statusKey, Status text: $statusText');
      
      // Get collector name if available (for accepted/on_way status)
      String? collectorName;
      if (drop.status == DropStatus.accepted || statusKey == 'on_way') {
        // Try to get collector name from notification data or drop
        if (notificationData != null && notificationData['collectorName'] != null) {
          collectorName = notificationData['collectorName'] as String;
          debugPrint('🔄 _updateDropTimelineActivity: Got collector name from notification: $collectorName');
        } else {
          // Try to get collector ID from notification data
          String? collectorId;
          if (notificationData != null && notificationData['collectorId'] != null) {
            collectorId = notificationData['collectorId'] as String;
            debugPrint('🔄 _updateDropTimelineActivity: Got collector ID from notification: $collectorId');
          } else {
            // Fetch collector ID from active CollectionAttempt
            debugPrint('🔄 _updateDropTimelineActivity: No collector ID in notification, fetching from active CollectionAttempt');
            try {
              final activeAttempt = await _repository.getActiveCollectionAttempt(drop.id);
              if (activeAttempt != null && activeAttempt['collectorId'] != null) {
                collectorId = activeAttempt['collectorId'].toString();
                debugPrint('🔄 _updateDropTimelineActivity: Got collector ID from active attempt: $collectorId');
              }
            } catch (e) {
              debugPrint('⚠️ _updateDropTimelineActivity: Error fetching active attempt: $e');
            }
          }
          
          // Fetch collector name by ID if we have it
          if (collectorId != null) {
            debugPrint('🔄 _updateDropTimelineActivity: Fetching collector name for ID: $collectorId');
            final collectorInfo = await getUserInfo(collectorId);
            collectorName = collectorInfo?['name'] as String?;
            debugPrint('🔄 _updateDropTimelineActivity: Fetched collector name: $collectorName');
          } else {
            debugPrint('⚠️ _updateDropTimelineActivity: No collector ID available, collector name will be empty');
          }
        }
      }
      
      // Update or end activity based on status
      if (drop.status == DropStatus.collected || 
          drop.status == DropStatus.expired || 
          drop.status == DropStatus.cancelled) {
        // End activity for final states
        debugPrint('🔄 _updateDropTimelineActivity: Ending Live Activity (final state: ${drop.status.name})');
        await liveActivityService.endDropTimelineActivity(dropId: drop.id);
      } else {
        // Update activity for intermediate states
        debugPrint('🔄 _updateDropTimelineActivity: Updating Live Activity with status: $statusText, collector: $collectorName');
        // Get distance remaining if available from notification data
        double? distanceRemaining;
        if (notificationData != null && notificationData['distanceRemaining'] != null) {
          distanceRemaining = (notificationData['distanceRemaining'] as num).toDouble();
        }
        
        await liveActivityService.updateDropTimelineActivity(
          dropId: drop.id,
          status: statusKey,
          statusText: statusText,
          collectorName: collectorName,
          timeAgo: LiveActivitiesPackageService.formatTimeAgo(drop.modifiedAt),
          distanceRemaining: distanceRemaining,
        );
        debugPrint('✅ _updateDropTimelineActivity: Live Activity update completed');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating drop timeline Live Activity: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  Future<void> cancelAcceptedDrop(String dropId, String reason, String cancelledByCollectorId) async {
    try {
      await _repository.cancelAcceptedDrop(dropId, reason, cancelledByCollectorId);
      
      // Update the drop status in the current list
      Drop? cancelledDrop;
      state.whenData((drops) {
        final updatedDrops = drops.map((drop) {
          if (drop.id == dropId) {
            cancelledDrop = drop.copyWith(status: DropStatus.cancelled);
            return cancelledDrop!;
          }
          return drop;
        }).toList();
        state = AsyncValue.data(updatedDrops);
      });
      
      // End Live Activity since drop is now cancelled
      if (cancelledDrop != null) {
        debugPrint('🔄 cancelAcceptedDrop: Ending Live Activity for cancelled drop $dropId');
        await _updateDropTimelineActivity(cancelledDrop!, null);
      }
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