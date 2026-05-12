import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/meeting_model.dart';

class MeetingRepository {
  final _api = ApiClient.instance;

  Future<List<MeetingModel>> listMeetings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get(ApiEndpoints.meetings, queryParameters: {
      if (status != null) 'status': status,
      'page': page,
      'limit': limit,
    });
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => MeetingModel.fromJson(e)).toList();
  }

  Future<MeetingModel> create(Map<String, dynamic> data) async {
    final res = await _api.post(ApiEndpoints.meetings, data: data);
    return MeetingModel.fromJson(res.data['data']);
  }

  Future<MeetingModel> getById(String id) async {
    final res = await _api.get(ApiEndpoints.meeting(id));
    return MeetingModel.fromJson(res.data['data']);
  }

  Future<MeetingModel> update(String id, Map<String, dynamic> data) async {
    final res = await _api.put(ApiEndpoints.meeting(id), data: data);
    return MeetingModel.fromJson(res.data['data']);
  }

  Future<void> delete(String id) => _api.delete(ApiEndpoints.meeting(id));

  Future<void> rsvp(String id, String response) async {
    await _api.post(ApiEndpoints.meetingRsvp(id), data: {'response': response});
  }

  Future<MeetingModel> join(String meetingId, {String? password}) async {
    await _api.post(ApiEndpoints.joinMeeting(meetingId), data: {
      if (password != null) 'password': password,
    });
    return getById(meetingId);
  }
}
