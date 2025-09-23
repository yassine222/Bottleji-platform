import '../models/support_ticket.dart';
import '../datasources/support_ticket_api_client.dart';
import '../../../../core/api/api_client.dart';

abstract class SupportTicketRepository {
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
  });

  Future<List<SupportTicket>> getMyTickets();
  Future<SupportTicket> getTicketById(String ticketId);
  Future<SupportTicket> addMessage({
    required String ticketId,
    required String message,
    bool isInternal = false,
  });
}

class SupportTicketRepositoryImpl implements SupportTicketRepository {
  final SupportTicketApiClient _apiClient;

  SupportTicketRepositoryImpl({required SupportTicketApiClient apiClient})
      : _apiClient = apiClient;

  static Future<SupportTicketRepositoryImpl> create() async {
    final dio = ApiClientConfig.createDio();
    final apiClient = SupportTicketApiClient(dio);
    return SupportTicketRepositoryImpl(apiClient: apiClient);
  }

  @override
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
      return await _apiClient.createTicket(
        title: title,
        description: description,
        category: category,
        priority: priority,
        attachments: attachments,
        contextMetadata: contextMetadata,
        relatedDropId: relatedDropId,
        relatedCollectionId: relatedCollectionId,
        relatedApplicationId: relatedApplicationId,
        location: location,
      );
    } catch (e) {
      print('Error creating support ticket: $e');
      rethrow;
    }
  }

  @override
  Future<List<SupportTicket>> getMyTickets() async {
    try {
      return await _apiClient.getMyTickets();
    } catch (e) {
      print('Error fetching support tickets: $e');
      rethrow;
    }
  }

  @override
  Future<SupportTicket> getTicketById(String ticketId) async {
    try {
      return await _apiClient.getTicketById(ticketId);
    } catch (e) {
      print('Error fetching support ticket: $e');
      rethrow;
    }
  }

  @override
  Future<SupportTicket> addMessage({
    required String ticketId,
    required String message,
    bool isInternal = false,
  }) async {
    try {
      return await _apiClient.addMessage(
        ticketId: ticketId,
        message: message,
        isInternal: isInternal,
      );
    } catch (e) {
      print('Error adding message to support ticket: $e');
      rethrow;
    }
  }
}
