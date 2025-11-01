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
