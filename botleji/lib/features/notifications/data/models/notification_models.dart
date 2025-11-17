class NotificationAction {
  final String label;
  final String action;
  final String? url;

  NotificationAction({
    required this.label,
    required this.action,
    this.url,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      label: json['label'] ?? '',
      action: json['action'] ?? '',
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'action': action,
      'url': url,
    };
  }
}

enum NotificationType {
  orderApproved,
  orderRejected,
  orderShipped,
  orderDelivered,
  pointsEarned,
  systemAnnouncement,
  userDeleted,
  applicationApproved,
  applicationRejected,
  applicationReversed,
  // Drop-related notifications
  dropAccepted,
  dropCollected,
  dropCollectedWithRewards,
  dropCollectedWithTierUpgrade,
  dropCancelled,
  dropExpired,
  dropNearExpiring,
  dropCensored,
  // Support ticket notifications
  ticketMessage,
  // Account notifications
  accountLocked,
  accountUnlocked,
  // Other
  test,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

class NotificationData {
  final String? orderId;
  final int? pointsAmount;
  final String? trackingNumber;
  final String? rejectionReason;
  final Map<String, dynamic>? additionalData;

  NotificationData({
    this.orderId,
    this.pointsAmount,
    this.trackingNumber,
    this.rejectionReason,
    this.additionalData,
  });

  factory NotificationData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NotificationData();
    
    return NotificationData(
      orderId: json['orderId'],
      pointsAmount: json['pointsAmount'],
      trackingNumber: json['trackingNumber'],
      rejectionReason: json['rejectionReason'],
      additionalData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'pointsAmount': pointsAmount,
      'trackingNumber': trackingNumber,
      'rejectionReason': rejectionReason,
      ...?additionalData,
    };
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime? readAt;
  final NotificationData data;
  final List<NotificationAction> actions;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    required this.isRead,
    this.readAt,
    required this.data,
    required this.actions,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: _parseNotificationType(json['type']),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: _parseNotificationPriority(json['priority']),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      data: NotificationData.fromJson(json['data']),
      actions: (json['actions'] as List<dynamic>?)
          ?.map((action) => NotificationAction.fromJson(action))
          .toList() ?? [],
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'type': _notificationTypeToString(type),
      'title': title,
      'message': message,
      'priority': _notificationPriorityToString(priority),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'data': data.toJson(),
      'actions': actions.map((action) => action.toJson()).toList(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? readAt,
    NotificationData? data,
    List<NotificationAction>? actions,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      actions: actions ?? this.actions,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'order_approved':
        return NotificationType.orderApproved;
      case 'order_rejected':
        return NotificationType.orderRejected;
      case 'order_shipped':
        return NotificationType.orderShipped;
      case 'order_delivered':
        return NotificationType.orderDelivered;
      case 'points_earned':
        return NotificationType.pointsEarned;
      case 'system_announcement':
        return NotificationType.systemAnnouncement;
      case 'user_deleted':
        return NotificationType.userDeleted;
      case 'application_approved':
        return NotificationType.applicationApproved;
      case 'application_rejected':
        return NotificationType.applicationRejected;
      case 'application_reversed':
        return NotificationType.applicationReversed;
      case 'drop_accepted':
        return NotificationType.dropAccepted;
      case 'drop_collected':
        return NotificationType.dropCollected;
      case 'drop_collected_with_rewards':
        return NotificationType.dropCollectedWithRewards;
      case 'drop_collected_with_tier_upgrade':
        return NotificationType.dropCollectedWithTierUpgrade;
      case 'drop_cancelled':
        return NotificationType.dropCancelled;
      case 'drop_expired':
        return NotificationType.dropExpired;
      case 'drop_near_expiring':
        return NotificationType.dropNearExpiring;
      case 'drop_censored':
        return NotificationType.dropCensored;
      case 'ticket_message':
        return NotificationType.ticketMessage;
      case 'account_locked':
        return NotificationType.accountLocked;
      case 'account_unlocked':
        return NotificationType.accountUnlocked;
      case 'test':
        return NotificationType.test;
      default:
        return NotificationType.systemAnnouncement;
    }
  }

  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.orderApproved:
        return 'order_approved';
      case NotificationType.orderRejected:
        return 'order_rejected';
      case NotificationType.orderShipped:
        return 'order_shipped';
      case NotificationType.orderDelivered:
        return 'order_delivered';
      case NotificationType.pointsEarned:
        return 'points_earned';
      case NotificationType.systemAnnouncement:
        return 'system_announcement';
      case NotificationType.userDeleted:
        return 'user_deleted';
      case NotificationType.applicationApproved:
        return 'application_approved';
      case NotificationType.applicationRejected:
        return 'application_rejected';
      case NotificationType.applicationReversed:
        return 'application_reversed';
      case NotificationType.dropAccepted:
        return 'drop_accepted';
      case NotificationType.dropCollected:
        return 'drop_collected';
      case NotificationType.dropCollectedWithRewards:
        return 'drop_collected_with_rewards';
      case NotificationType.dropCollectedWithTierUpgrade:
        return 'drop_collected_with_tier_upgrade';
      case NotificationType.dropCancelled:
        return 'drop_cancelled';
      case NotificationType.dropExpired:
        return 'drop_expired';
      case NotificationType.dropNearExpiring:
        return 'drop_near_expiring';
      case NotificationType.dropCensored:
        return 'drop_censored';
      case NotificationType.ticketMessage:
        return 'ticket_message';
      case NotificationType.accountLocked:
        return 'account_locked';
      case NotificationType.accountUnlocked:
        return 'account_unlocked';
      case NotificationType.test:
        return 'test';
    }
  }

  static NotificationPriority _parseNotificationPriority(String? priority) {
    switch (priority) {
      case 'low':
        return NotificationPriority.low;
      case 'medium':
        return NotificationPriority.medium;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.medium;
    }
  }

  static String _notificationPriorityToString(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'low';
      case NotificationPriority.medium:
        return 'medium';
      case NotificationPriority.high:
        return 'high';
      case NotificationPriority.urgent:
        return 'urgent';
    }
  }
}
