import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/support_ticket.dart';
import '../../data/repositories/support_ticket_repository.dart';
import '../../data/datasources/support_ticket_api_client.dart';
import '../../../../core/api/api_client.dart';

class SupportTicketNotifier
    extends StateNotifier<AsyncValue<List<SupportTicket>>> {
  final SupportTicketRepository _repository;

  SupportTicketNotifier(this._repository) : super(const AsyncValue.data([]));

  Future<void> loadMyTickets() async {
    state = const AsyncValue.loading();
    try {
      final tickets = await _repository.getMyTickets();
      state = AsyncValue.data(tickets);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createTicket({
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
      final newTicket = await _repository.createTicket(
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

      // Add the new ticket to the current list
      state.whenData((tickets) {
        state = AsyncValue.data([newTicket, ...tickets]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> addMessage({
    required String ticketId,
    required String message,
    bool isInternal = false,
  }) async {
    try {
      final updatedTicket = await _repository.addMessage(
        ticketId: ticketId,
        message: message,
        isInternal: isInternal,
      );

      // Update the ticket in the current list
      state.whenData((tickets) {
        final updatedTickets = tickets.map((ticket) {
          if (ticket.id == ticketId) {
            return updatedTicket;
          }
          return ticket;
        }).toList();
        state = AsyncValue.data(updatedTickets);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<SupportTicket> getTicketById(String ticketId) async {
    return await _repository.getTicketById(ticketId);
  }
}

final supportTicketProvider = StateNotifierProvider<
    SupportTicketNotifier, AsyncValue<List<SupportTicket>>>((ref) {
  final dio = ApiClientConfig.createDio();
  final apiClient = SupportTicketApiClient(dio);
  final repository = SupportTicketRepositoryImpl(apiClient: apiClient);
  return SupportTicketNotifier(repository);
});
