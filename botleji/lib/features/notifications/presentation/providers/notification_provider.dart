import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_models.dart';
import '../../data/services/notification_service.dart';
import '../../../../core/services/local_notification_service.dart';


// Notification state
class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notification notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final result = await NotificationService.getUserNotifications();
      
      if (result['success']) {
        final unreadCount = result['unreadCount'] ?? 0;
        state = state.copyWith(
          notifications: result['notifications'],
          unreadCount: unreadCount,
          isLoading: false,
          error: null,
        );
        
        // Sync app icon badge with actual unread count
        final localNotificationService = LocalNotificationService();
        await localNotificationService.updateBadgeCount(unreadCount);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['error'] ?? 'Failed to load notifications',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final success = await NotificationService.markAsRead(notificationId);
    if (success) {
      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        return notification;
      }).toList();

      final newUnreadCount = state.unreadCount > 0 ? state.unreadCount - 1 : 0;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
      
      // Update app icon badge with new unread count
      final localNotificationService = LocalNotificationService();
      await localNotificationService.updateBadgeCount(newUnreadCount);
    }
  }

  Future<void> markAllAsRead() async {
    final success = await NotificationService.markAllAsRead();
    if (success) {
      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
      
      // Clear app icon badge since all are read
      final localNotificationService = LocalNotificationService();
      await localNotificationService.clearBadgeCount();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final success = await NotificationService.deleteNotification(notificationId);
    if (success) {
      // Update local state
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();

      // Check if the deleted notification was unread
      final deletedNotification = state.notifications
          .firstWhere((notification) => notification.id == notificationId);
      
      final newUnreadCount = deletedNotification.isRead 
          ? state.unreadCount 
          : (state.unreadCount > 0 ? state.unreadCount - 1 : 0);

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final unreadCount = await NotificationService.getUnreadCount();
      state = state.copyWith(unreadCount: unreadCount);
    } catch (e) {
      // Silently fail for unread count refresh
    }
  }
}

// Providers
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

final notificationsListProvider = Provider<List<NotificationModel>>((ref) {
  return ref.watch(notificationProvider).notifications;
});

final notificationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(notificationProvider).isLoading;
});

final notificationErrorProvider = Provider<String?>((ref) {
  return ref.watch(notificationProvider).error;
});
