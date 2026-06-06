import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/chat_model.dart';

class ChatRepository {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> getRoomToken(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.communicationRoomToken, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<ChatRoom>> getRooms() async {
    final res = await _api.get(ApiEndpoints.communicationRooms);
    final list = res.data['data'] as List? ?? [];
    return list
        .map((e) => ChatRoom.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
  }

  Future<ChatRoom> createRoom(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.communicationRooms, data: body);
    return ChatRoom.fromJson(res.data['data']);
  }

  Future<void> deleteRoom(String name) async {
    await _api.delete(ApiEndpoints.communicationRoom(name));
  }

  Future<List<Map<String, dynamic>>> getRoomParticipants(String name) async {
    final res =
        await _api.get(ApiEndpoints.communicationRoomParticipants(name));
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<void> removeParticipant(
      String roomName, Map<String, dynamic> body) async {
    await _api.post(
        ApiEndpoints.communicationRoomRemoveParticipant(roomName), data: body);
  }

  Future<Map<String, dynamic>> initiateCall(Map<String, dynamic> body) async {
    final res =
        await _api.post(ApiEndpoints.communicationCallInitiate, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> acceptCall(String id) async {
    await _api.put(ApiEndpoints.communicationCallAccept(id));
  }

  Future<void> endCall(String id) async {
    await _api.put(ApiEndpoints.communicationCallEnd(id));
  }

  Future<void> rejectCall(String id) async {
    await _api.put(ApiEndpoints.communicationCallReject(id));
  }

  Future<List<Map<String, dynamic>>> getCallHistory() async {
    final res = await _api.get(ApiEndpoints.communicationCallHistory);
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<List<ChatMessage>> getMessages({String? cursor, int limit = 50}) async {
    final res = await _api.get(ApiEndpoints.communicationMessages,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        });
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<List<ChatMessage>> searchMessages(String query) async {
    final res = await _api.get(ApiEndpoints.communicationMessagesSearch,
        queryParameters: {'q': query});
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<ChatMessage> sendMessage(Map<String, dynamic> body) async {
    final res =
        await _api.post(ApiEndpoints.communicationMessages, data: body);
    return ChatMessage.fromJson(res.data['data']);
  }

  Future<void> deleteMessage(String id) async {
    await _api.delete(ApiEndpoints.communicationMessage(id));
  }
}
