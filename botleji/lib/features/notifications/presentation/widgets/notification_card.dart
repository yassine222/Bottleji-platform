import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_models.dart';
import '../providers/notification_provider.dart';

class NotificationCard extends ConsumerWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationCard({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getNotificationColor(notification.type);
    final isUnread = !notification.isRead;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isUnread 
                ? color.withOpacity(0.15)
                : Colors.grey.withOpacity(0.08),
            blurRadius: isUnread ? 12 : 6,
            spreadRadius: isUnread ? 2 : 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: isUnread
            ? Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              ref.read(notificationProvider.notifier).markAsRead(notification.id);
            }
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon with gradient effect
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
            
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: isUnread 
                                        ? FontWeight.w700 
                                        : FontWeight.w600,
                                    fontSize: 15,
                                    color: isUnread 
                                        ? Colors.grey[900] 
                                        : Colors.grey[700],
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notification.message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isUnread 
                                        ? Colors.grey[700] 
                                        : Colors.grey[600],
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(left: 8, top: 2),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(notification.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (notification.priority == NotificationPriority.high ||
                              notification.priority == NotificationPriority.urgent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: notification.priority == NotificationPriority.urgent
                                    ? Colors.red[50]
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: notification.priority == NotificationPriority.urgent
                                      ? Colors.red[200]!
                                      : Colors.orange[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.priority_high,
                                    size: 12,
                                    color: notification.priority == NotificationPriority.urgent
                                        ? Colors.red[700]
                                        : Colors.orange[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    notification.priority == NotificationPriority.urgent
                                        ? 'URGENT'
                                        : 'HIGH',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: notification.priority == NotificationPriority.urgent
                                          ? Colors.red[700]
                                          : Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      // Action buttons
                      if (notification.actions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: notification.actions.map((action) {
                            return Container(
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _handleAction(context, action);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      action.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                // Delete button
                if (onDelete != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderApproved:
        return Colors.green;
      case NotificationType.orderRejected:
        return Colors.red;
      case NotificationType.orderShipped:
        return Colors.blue;
      case NotificationType.orderDelivered:
        return Colors.purple;
      case NotificationType.pointsEarned:
        return Colors.amber;
      case NotificationType.systemAnnouncement:
        return Colors.grey;
      case NotificationType.userDeleted:
        return Colors.red;
      case NotificationType.applicationApproved:
        return Colors.green;
      case NotificationType.applicationRejected:
        return Colors.red;
      case NotificationType.applicationReversed:
        return Colors.orange;
      case NotificationType.dropAccepted:
        return Colors.blue;
      case NotificationType.dropCollected:
      case NotificationType.dropCollectedWithRewards:
      case NotificationType.dropCollectedWithTierUpgrade:
        return Colors.green;
      case NotificationType.dropCancelled:
        return Colors.orange;
      case NotificationType.dropExpired:
        return Colors.red;
      case NotificationType.dropNearExpiring:
        return Colors.orange;
      case NotificationType.dropCensored:
        return Colors.red;
      case NotificationType.ticketMessage:
        return Colors.blue;
      case NotificationType.accountLocked:
        return Colors.red;
      case NotificationType.accountUnlocked:
        return Colors.green;
      case NotificationType.test:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderApproved:
        return Icons.check_circle;
      case NotificationType.orderRejected:
        return Icons.cancel;
      case NotificationType.orderShipped:
        return Icons.local_shipping;
      case NotificationType.orderDelivered:
        return Icons.done_all;
      case NotificationType.pointsEarned:
        return Icons.star;
      case NotificationType.systemAnnouncement:
        return Icons.announcement;
      case NotificationType.userDeleted:
        return Icons.delete;
      case NotificationType.applicationApproved:
        return Icons.check_circle;
      case NotificationType.applicationRejected:
        return Icons.cancel;
      case NotificationType.applicationReversed:
        return Icons.undo;
      case NotificationType.dropAccepted:
        return Icons.check_circle_outline;
      case NotificationType.dropCollected:
      case NotificationType.dropCollectedWithRewards:
      case NotificationType.dropCollectedWithTierUpgrade:
        return Icons.check_circle;
      case NotificationType.dropCancelled:
        return Icons.cancel;
      case NotificationType.dropExpired:
        return Icons.schedule;
      case NotificationType.dropNearExpiring:
        return Icons.warning;
      case NotificationType.dropCensored:
        return Icons.block;
      case NotificationType.ticketMessage:
        return Icons.message;
      case NotificationType.accountLocked:
        return Icons.lock;
      case NotificationType.accountUnlocked:
        return Icons.lock_open;
      case NotificationType.test:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  void _handleAction(BuildContext context, NotificationAction action) {
    switch (action.action) {
      case 'track_order':
        // Navigate to order tracking
        break;
      case 'view_order':
        // Navigate to order details
        break;
      case 'shop_again':
        // Navigate to rewards shop
        break;
      case 'view_rewards':
        // Navigate to rewards
        break;
      default:
        // Handle other actions
        break;
    }
  }
}
