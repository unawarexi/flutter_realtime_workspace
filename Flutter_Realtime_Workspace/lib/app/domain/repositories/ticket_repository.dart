import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/ticket_model.dart';

class TicketRepository {
  final _api = ApiClient.instance;

  Future<List<TicketModel>> getTickets({
    String? workspaceId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get(ApiEndpoints.tickets, queryParameters: {
      if (workspaceId != null) 'workspaceId': workspaceId,
      if (status != null) 'status': status,
      'page': page,
      'limit': limit,
    });
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => TicketModel.fromJson(e)).toList();
  }

  Future<TicketModel> getTicket(String id) async {
    final res = await _api.get(ApiEndpoints.ticket(id));
    return TicketModel.fromJson(res.data['data']);
  }

  Future<TicketModel> createTicket(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.tickets, data: body);
    return TicketModel.fromJson(res.data['data']);
  }

  Future<TicketModel> updateTicket(String id, Map<String, dynamic> body) async {
    final res = await _api.patch(ApiEndpoints.ticket(id), data: body);
    return TicketModel.fromJson(res.data['data']);
  }

  Future<void> deleteTicket(String id) async {
    await _api.delete(ApiEndpoints.ticket(id));
  }

  Future<void> assignTicket(String id, String userId) async {
    await _api.patch(ApiEndpoints.ticketAssign(id), data: {'userId': userId});
  }

  Future<void> resolveTicket(String id, String resolution) async {
    await _api.post(ApiEndpoints.ticketResolve(id), data: {'resolution': resolution});
  }
}
