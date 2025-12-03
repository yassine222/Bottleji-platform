import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';
import '../../data/models/notification_models.dart';
import 'package:botleji/l10n/app_localizations.dart';

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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).notificationsTitle),
            if (notificationState.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notificationState.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (notificationState.unreadCount > 0)
            TextButton.icon(
              onPressed: () {
                notificationNotifier.markAllAsRead();
              },
              icon: const Icon(Icons.done_all, size: 18),
              label: Text(
                AppLocalizations.of(context).markAllRead,
                style: const TextStyle(color: Colors.white),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).failedToLoadNotifications,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              notificationState.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                notificationNotifier.loadNotifications(refresh: true);
              },
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }

    if (notificationState.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_none,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).noNotificationsYet,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).youWillSeeNotificationsHere,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Group notifications by date
    final groupedNotifications = _groupNotificationsByDate(notificationState.notifications);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groupedNotifications.length,
      itemBuilder: (context, index) {
        final group = groupedNotifications[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                group['date'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Notifications for this date
            ...(group['notifications'] as List<NotificationModel>).map((notification) {
              return NotificationCard(
                notification: notification,
                onTap: () {
                  _handleNotificationTap(notification);
                },
                onDelete: () {
                  // Delete directly without confirmation dialog
                  notificationNotifier.deleteNotification(notification.id);
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _groupNotificationsByDate(List<NotificationModel> notifications) {
    final Map<String, List<NotificationModel>> grouped = {};
    
    for (final notification in notifications) {
      final dateKey = _getDateKey(notification.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(notification);
    }
    
    return grouped.entries.map((entry) {
      return {
        'date': entry.key,
        'notifications': entry.value,
      };
    }).toList();
  }

  String _getDateKey(DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);
    
    if (notificationDate == today) {
      return l10n.today;
    } else if (notificationDate == yesterday) {
      return l10n.yesterday;
    } else {
      // Format: "Mon, Jan 15" or "Jan 15, 2024" if older than a week
      final difference = now.difference(notificationDate).inDays;
      if (difference < 7) {
        return _formatWeekday(date);
      } else if (date.year == now.year) {
        return _formatMonthDay(date);
      } else {
        return _formatFullDate(date);
      }
    }
  }

  String _formatWeekday(DateTime date) {
    // Use localized weekday names
    final locale = Localizations.localeOf(context);
    
    if (locale.languageCode == 'ar') {
      // Arabic weekday names
      const weekdays = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
      return weekdays[date.weekday - 1];
    } else {
      // English weekday abbreviations
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    }
  }

  String _formatMonthDay(DateTime date) {
    final locale = Localizations.localeOf(context);
    
    if (locale.languageCode == 'ar') {
      // Arabic month names
      const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      return '${date.day} ${months[date.month - 1]}';
    } else {
      // English month abbreviations
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  String _formatFullDate(DateTime date) {
    final locale = Localizations.localeOf(context);
    
    if (locale.languageCode == 'ar') {
      // Arabic date format: "15 يناير 2024"
      const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      // English date format: "Jan 15, 2024"
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
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

}