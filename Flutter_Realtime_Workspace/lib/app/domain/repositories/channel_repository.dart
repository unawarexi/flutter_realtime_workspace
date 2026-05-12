import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/channel_model.dart';

class ChannelRepository {
  final _api = ApiClient.instance;

  Future<List<ChannelModel>> getChannels(String workspaceId) async {
    final res = await _api.get(ApiEndpoints.channels,
        queryParameters: {'workspaceId': workspaceId});
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => ChannelModel.fromJson(e)).toList();
  }

  Future<ChannelModel> getChannel(String id) async {
    final res = await _api.get(ApiEndpoints.channel(id));
    return ChannelModel.fromJson(res.data['data']);
  }

  Future<ChannelModel> createChannel(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.channels, data: body);
    return ChannelModel.fromJson(res.data['data']);
  }

  Future<ChannelModel> updateChannel(
      String id, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.channel(id), data: body);
    return ChannelModel.fromJson(res.data['data']);
  }

  Future<void> deleteChannel(String id) async {
    await _api.delete(ApiEndpoints.channel(id));
  }

  Future<void> addMember(String channelId, String userId) async {
    await _api.post(ApiEndpoints.channelMembers(channelId),
        data: {'userId': userId});
  }

  Future<void> removeMember(String channelId, String memberId) async {
    await _api.delete(ApiEndpoints.channelMember(channelId, memberId));
  }

  Future<List<Map<String, dynamic>>> getMessages(String channelId,
      {String? cursor, int limit = 50}) async {
    final res = await _api.get(ApiEndpoints.channelMessages(channelId),
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        });
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> sendMessage(
      String channelId, Map<String, dynamic> body) async {
    final res =
        await _api.post(ApiEndpoints.channelMessages(channelId), data: body);
    return res.data['data'];
  }
}
