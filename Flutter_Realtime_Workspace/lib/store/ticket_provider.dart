import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/ticket_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/ticket_repository.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((_) {
  return TicketRepository();
});

final ticketsProvider = FutureProvider.autoDispose
    .family<List<TicketModel>, Map<String, String?>>((ref, filters) {
  return ref.watch(ticketRepositoryProvider).getTickets(
        workspaceId: filters['workspaceId'],
        status: filters['status'],
      );
});

final ticketDetailProvider =
    FutureProvider.autoDispose.family<TicketModel, String>((ref, id) {
  return ref.watch(ticketRepositoryProvider).getTicket(id);
});

final ticketNotifierProvider =
    StateNotifierProvider<TicketNotifier, AsyncValue<TicketModel?>>(
        (ref) => TicketNotifier(ref));

class TicketNotifier extends StateNotifier<AsyncValue<TicketModel?>> {
  final Ref _ref;
  TicketNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<TicketModel> createTicket(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final ticket =
          await _ref.read(ticketRepositoryProvider).createTicket(body);
      state = AsyncValue.data(ticket);
      return ticket;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<TicketModel> updateTicket(String id, Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final ticket =
          await _ref.read(ticketRepositoryProvider).updateTicket(id, body);
      state = AsyncValue.data(ticket);
      return ticket;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
