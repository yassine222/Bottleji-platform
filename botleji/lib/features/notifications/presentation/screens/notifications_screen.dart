import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import 'package:intl/intl.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationService = ref.watch(notificationServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: notificationService.notifications.isNotEmpty
                ? () => notificationService.markAllAsRead()
                : null,
            child: const Text('Mark All Read'),
          ),
        ],
      ),
      body: notificationService.notifications.isEmpty
          ? const Center(
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
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notificationService.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationService.notifications[index];
                final isRead = notification.data?['read'] ?? false;
                
                // Filter out connection notifications
                if (notification.type == 'connection_established' || 
                    notification.type == 'connection') {
                  return const SizedBox.shrink();
                }
                
                return _NotificationTile(
                  notification: notification,
                  isRead: isRead,
                  onTap: () => notificationService.markAsRead(index),
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationPayload notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isRead ? null : Colors.blue.withOpacity(0.1),
      child: ListTile(
        leading: _getNotificationIcon(notification.type),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: isRead ? null : Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'user_deleted':
      case 'force_logout':
        iconData = Icons.person_off;
        iconColor = Colors.red;
        break;
      case 'user_banned':
        iconData = Icons.block;
        iconColor = Colors.orange;
        break;
      case 'user_unbanned':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'role_changed':
        iconData = Icons.admin_panel_settings;
        iconColor = Colors.blue;
        break;
      case 'drop_accepted':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'drop_collected':
        iconData = Icons.done_all;
        iconColor = Colors.green;
        break;
      case 'drop_cancelled':
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'drop_expired':
        iconData = Icons.schedule;
        iconColor = Colors.orange;
        break;
      case 'new_drop_available':
        iconData = Icons.add_location;
        iconColor = Colors.blue;
        break;
      case 'ticket_response':
        iconData = Icons.support_agent;
        iconColor = Colors.purple;
        break;
      case 'application_approved':
        iconData = Icons.verified;
        iconColor = Colors.green;
        break;
      case 'application_rejected':
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'system_maintenance':
        iconData = Icons.build;
        iconColor = Colors.orange;
        break;
      case 'announcement':
        iconData = Icons.announcement;
        iconColor = Colors.blue;
        break;
      case 'new_training_content':
        iconData = Icons.school;
        iconColor = Colors.blue;
        break;
      case 'training_completed':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'connection_established':
        iconData = Icons.notifications;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, y').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 