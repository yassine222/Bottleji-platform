import 'package:json_annotation/json_annotation.dart';

part 'support_ticket.g.dart';

enum TicketStatus {
  @JsonValue('open')
  open,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('on_hold')
  onHold,
  @JsonValue('resolved')
  resolved,
  @JsonValue('closed')
  closed,
}

enum TicketPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

enum TicketCategory {
  @JsonValue('authentication')
  authentication,
  @JsonValue('app_technical')
  appTechnical,
  @JsonValue('drop_creation')
  dropCreation,
  @JsonValue('collection_navigation')
  collectionNavigation,
  @JsonValue('collector_application')
  collectorApplication,
  @JsonValue('payment_rewards')
  paymentRewards,
  @JsonValue('statistics_history')
  statisticsHistory,
  @JsonValue('role_switching')
  roleSwitching,
  @JsonValue('communication')
  communication,
  @JsonValue('general_support')
  generalSupport,
}

@JsonSerializable()
class TicketMessage {
  final String message;
  final String senderId;
  final String senderType; // 'user', 'agent', 'system'
  final DateTime sentAt;
  final bool isInternal;

  const TicketMessage({
    required this.message,
    required this.senderId,
    required this.senderType,
    required this.sentAt,
    required this.isInternal,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) =>
      _$TicketMessageFromJson(json);

  Map<String, dynamic> toJson() => _$TicketMessageToJson(this);
}

@JsonSerializable()
class InternalNote {
  final String note;
  final String addedBy;
  final DateTime addedAt;

  const InternalNote({
    required this.note,
    required this.addedBy,
    required this.addedAt,
  });

  factory InternalNote.fromJson(Map<String, dynamic> json) =>
      _$InternalNoteFromJson(json);

  Map<String, dynamic> toJson() => _$InternalNoteToJson(this);
}

@JsonSerializable()
class SupportTicket {
  final String id;
  final String userId;
  final String title;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final String? assignedTo;
  final String? createdBy;
  final String? lastUpdatedBy;
  final List<String> tags;
  final List<String> attachments;
  final List<InternalNote> internalNotes;
  final List<TicketMessage> messages;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime? dueDate;
  final String? estimatedResolutionTime;
  final String? resolution;
  final bool isEscalated;
  final String? escalatedTo;
  final DateTime? escalatedAt;
  final String? escalatedReason;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.createdBy,
    this.lastUpdatedBy,
    this.tags = const [],
    this.attachments = const [],
    this.internalNotes = const [],
    this.messages = const [],
    this.resolvedAt,
    this.closedAt,
    this.dueDate,
    this.estimatedResolutionTime,
    this.resolution,
    this.isEscalated = false,
    this.escalatedTo,
    this.escalatedAt,
    this.escalatedReason,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketFromJson(json);

  Map<String, dynamic> toJson() => _$SupportTicketToJson(this);

  // Helper methods
  bool get isOpen => status == TicketStatus.open;
  bool get isInProgress => status == TicketStatus.inProgress;
  bool get isResolved => status == TicketStatus.resolved;
  bool get isClosed => status == TicketStatus.closed;
  bool get isOnHold => status == TicketStatus.onHold;

  String get statusDisplayName {
    switch (status) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.onHold:
        return 'On Hold';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case TicketPriority.low:
        return 'Low';
      case TicketPriority.medium:
        return 'Medium';
      case TicketPriority.high:
        return 'High';
      case TicketPriority.urgent:
        return 'Urgent';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case TicketCategory.authentication:
        return 'Authentication & Account';
      case TicketCategory.appTechnical:
        return 'App Technical Issues';
      case TicketCategory.dropCreation:
        return 'Drop Creation & Management';
      case TicketCategory.collectionNavigation:
        return 'Collection & Navigation';
      case TicketCategory.collectorApplication:
        return 'Collector Application';
      case TicketCategory.paymentRewards:
        return 'Payment & Rewards';
      case TicketCategory.statisticsHistory:
        return 'Statistics & History';
      case TicketCategory.roleSwitching:
        return 'Role Switching';
      case TicketCategory.communication:
        return 'Communication';
      case TicketCategory.generalSupport:
        return 'General Support';
    }
  }
}
