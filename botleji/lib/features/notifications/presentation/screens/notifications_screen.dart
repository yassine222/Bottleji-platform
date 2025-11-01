import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';
import '../../data/models/notification_models.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final notificationNotifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        actions: [
          if (notificationState.unreadCount > 0)
            TextButton(
              onPressed: () {
                notificationNotifier.markAllAsRead();
              },
              child: const Text(
                'Mark All Read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await notificationNotifier.loadNotifications(refresh: true);
        },
        child: _buildBody(notificationState, notificationNotifier),
      ),
    );
  }

  Widget _buildBody(notificationState, notificationNotifier) {
    if (notificationState.isLoading && notificationState.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (notificationState.error != null && notificationState.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load notifications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              notificationState.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                notificationNotifier.loadNotifications(refresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (notificationState.notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You\'ll see your notifications here',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notificationState.notifications.length,
      itemBuilder: (context, index) {
        final notification = notificationState.notifications[index];
        return NotificationCard(
          notification: notification,
          onTap: () {
            // Handle notification tap
            _handleNotificationTap(notification);
          },
          onDelete: () {
            _showDeleteDialog(notification, notificationNotifier);
          },
        );
      },
    );
  }

  void _handleNotificationTap(notification) {
    // Handle different notification types
    switch (notification.type) {
      case NotificationType.orderApproved:
        // Navigate to order details or tracking
        break;
      case NotificationType.orderRejected:
        // Navigate to order details
        break;
      case NotificationType.pointsEarned:
        // Navigate to rewards or points history
        break;
      default:
        // Handle other types
        break;
    }
  }

  void _showDeleteDialog(notification, notificationNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              notificationNotifier.deleteNotification(notification.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}