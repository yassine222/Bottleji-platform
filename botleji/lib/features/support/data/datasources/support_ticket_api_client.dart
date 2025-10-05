import 'package:dio/dio.dart';
import '../models/support_ticket.dart';

class SupportTicketApiClient {
  final Dio _dio;

  SupportTicketApiClient(this._dio);

  Future<SupportTicket> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    TicketPriority priority = TicketPriority.medium,
    List<String> attachments = const [],
    Map<String, dynamic>? contextMetadata,
    String? relatedDropId,
    String? relatedCollectionId,
    String? relatedApplicationId,
    Map<String, dynamic>? location,
  }) async {
    try {
      final response = await _dio.post('/support-tickets', data: {
        'title': title,
        'description': description,
        'category': _getCategoryJsonValue(category), // Using JSON value for serialization
        'priority': _getPriorityJsonValue(priority),
        'attachments': attachments,
        if (contextMetadata != null) 'contextMetadata': contextMetadata,
        if (relatedDropId != null) 'relatedDropId': relatedDropId,
        if (relatedCollectionId != null) 'relatedCollectionId': relatedCollectionId,
        if (relatedApplicationId != null) 'relatedApplicationId': relatedApplicationId,
        if (location != null) 'location': location,
      });

      return SupportTicket.fromJson(response.data);
    } on DioException catch (e) {
      // Friendly message when server is unreachable
      if (e.type == DioExceptionType.connectionError || e.message?.contains('Connection refused') == true) {
        throw Exception('Cannot reach the server. Please ensure the backend is running and try again.');
      }
      rethrow;
    }
  }

  Future<List<SupportTicket>> getMyTickets() async {
    try {
      final response = await _dio.get('/support-tickets/my-tickets');
      return (response.data as List)
          .map((json) => SupportTicket.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.message?.contains('Connection refused') == true) {
        throw Exception('Cannot reach the server. Please ensure the backend is running and try again.');
      }
      rethrow;
    }
  }

  Future<SupportTicket> getTicketById(String ticketId) async {
    try {
      final response = await _dio.get('/support-tickets/$ticketId');
      return SupportTicket.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.message?.contains('Connection refused') == true) {
        throw Exception('Cannot reach the server. Please ensure the backend is running and try again.');
      }
      rethrow;
    }
  }

  Future<SupportTicket> addMessage({
    required String ticketId,
    required String message,
    bool isInternal = false,
  }) async {
    try {
      final response = await _dio.post(
        '/support-tickets/$ticketId/messages',
        data: {
          'message': message,
          'isInternal': isInternal,
        },
      );
      return SupportTicket.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.message?.contains('Connection refused') == true) {
        throw Exception('Cannot reach the server. Please ensure the backend is running and try again.');
      }
      rethrow;
    }
  }

  String _getCategoryJsonValue(TicketCategory category) {
    switch (category) {
      case TicketCategory.authentication:
        return 'authentication';
      case TicketCategory.appTechnical:
        return 'app_technical';
      case TicketCategory.dropCreation:
        return 'drop_creation';
      case TicketCategory.collectionNavigation:
        return 'collection_navigation';
      case TicketCategory.collectorApplication:
        return 'collector_application';
      case TicketCategory.paymentRewards:
        return 'payment_rewards';
      case TicketCategory.statisticsHistory:
        return 'statistics_history';
      case TicketCategory.roleSwitching:
        return 'role_switching';
      case TicketCategory.communication:
        return 'communication';
      case TicketCategory.generalSupport:
        return 'general_support';
    }
  }

  String _getPriorityJsonValue(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'low';
      case TicketPriority.medium:
        return 'medium';
      case TicketPriority.high:
        return 'high';
      case TicketPriority.urgent:
        return 'urgent';
    }
  }

  
}
