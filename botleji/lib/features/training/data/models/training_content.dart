class TrainingContent {
  final String id;
  final String title;
  final String description;
  final TrainingType type;
  final TrainingCategory category;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? content;
  final int duration; // in seconds
  final int order;
  final bool isActive;
  final bool isFeatured;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingContent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    this.mediaUrl,
    this.thumbnailUrl,
    this.content,
    this.duration = 0,
    this.order = 0,
    this.isActive = true,
    this.isFeatured = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingContent.fromJson(Map<String, dynamic> json) {
    return TrainingContent(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: _parseType(json['type']),
      category: _parseCategory(json['category']),
      mediaUrl: json['mediaUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      content: json['content'],
      duration: json['duration'] ?? 0,
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  static TrainingType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'video':
        return TrainingType.video;
      case 'image':
        return TrainingType.image;
      case 'story':
        return TrainingType.story;
      default:
        return TrainingType.story;
    }
  }

  static TrainingCategory _parseCategory(String? category) {
    switch (category) {
      case 'getting_started':
        return TrainingCategory.gettingStarted;
      case 'advanced_features':
        return TrainingCategory.advancedFeatures;
      case 'troubleshooting':
        return TrainingCategory.troubleshooting;
      case 'best_practices':
        return TrainingCategory.bestPractices;
      case 'collector_application':
        return TrainingCategory.collectorApplication;
      case 'payments':
        return TrainingCategory.payments;
      case 'notifications':
        return TrainingCategory.notifications;
      default:
        return TrainingCategory.gettingStarted;
    }
  }

  String get formattedDuration {
    if (duration == 0) return '';
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  bool isRelevantForHousehold() {
    return category == TrainingCategory.gettingStarted ||
           category == TrainingCategory.bestPractices ||
           category == TrainingCategory.troubleshooting ||
           category == TrainingCategory.notifications ||
           category == TrainingCategory.payments;
  }

  bool isRelevantForCollector() {
    return category == TrainingCategory.collectorApplication ||
           category == TrainingCategory.advancedFeatures ||
           category == TrainingCategory.troubleshooting ||
           category == TrainingCategory.payments;
  }
}

enum TrainingType {
  video,
  image,
  story,
}

enum TrainingCategory {
  gettingStarted,
  advancedFeatures,
  troubleshooting,
  bestPractices,
  collectorApplication,
  payments,
  notifications,
}

extension TrainingCategoryExtension on TrainingCategory {
  String get displayName {
    switch (this) {
      case TrainingCategory.gettingStarted:
        return 'Getting Started';
      case TrainingCategory.advancedFeatures:
        return 'Advanced Features';
      case TrainingCategory.troubleshooting:
        return 'Troubleshooting';
      case TrainingCategory.bestPractices:
        return 'Best Practices';
      case TrainingCategory.collectorApplication:
        return 'Collector Application';
      case TrainingCategory.payments:
        return 'Payments';
      case TrainingCategory.notifications:
        return 'Notifications';
    }
  }

  String get icon {
    switch (this) {
      case TrainingCategory.gettingStarted:
        return '🚀';
      case TrainingCategory.advancedFeatures:
        return '⚡';
      case TrainingCategory.troubleshooting:
        return '🔧';
      case TrainingCategory.bestPractices:
        return '💡';
      case TrainingCategory.collectorApplication:
        return '📋';
      case TrainingCategory.payments:
        return '💳';
      case TrainingCategory.notifications:
        return '🔔';
    }
  }
}

