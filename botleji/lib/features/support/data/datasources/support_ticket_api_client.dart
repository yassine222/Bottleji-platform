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
    final response = await _dio.post('/support-tickets', data: {
      'title': title,
      'description': description,
      'category': category.name, // Using enum name for serialization
      'priority': priority.name,
      'attachments': attachments,
      if (contextMetadata != null) 'contextMetadata': contextMetadata,
      if (relatedDropId != null) 'relatedDropId': relatedDropId,
      if (relatedCollectionId != null) 'relatedCollectionId': relatedCollectionId,
      if (relatedApplicationId != null) 'relatedApplicationId': relatedApplicationId,
      if (location != null) 'location': location,
    });

    return SupportTicket.fromJson(response.data);
  }

  Future<List<SupportTicket>> getMyTickets() async {
    final response = await _dio.get('/support-tickets/my-tickets');
    return (response.data as List)
        .map((json) => SupportTicket.fromJson(json))
        .toList();
  }

  Future<SupportTicket> getTicketById(String ticketId) async {
    final response = await _dio.get('/support-tickets/$ticketId');
    return SupportTicket.fromJson(response.data);
  }

  Future<SupportTicket> addMessage({
    required String ticketId,
    required String message,
    bool isInternal = false,
  }) async {
    final response = await _dio.post('/support-tickets/$ticketId/messages', data: {
      'message': message,
      'isInternal': isInternal,
    });

    return SupportTicket.fromJson(response.data);
  }
}
