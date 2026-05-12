import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/schedule_model.dart';

class ScheduleRepository {
  final _api = ApiClient.instance;

  Future<List<ScheduleModel>> getSchedules({
    String? workspaceId,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _api.get(ApiEndpoints.schedules, queryParameters: {
      if (workspaceId != null) 'workspaceId': workspaceId,
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    });
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => ScheduleModel.fromJson(e)).toList();
  }

  Future<ScheduleModel> getSchedule(String id) async {
    final res = await _api.get(ApiEndpoints.schedule(id));
    return ScheduleModel.fromJson(res.data['data']);
  }

  Future<ScheduleModel> createSchedule(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.schedules, data: body);
    return ScheduleModel.fromJson(res.data['data']);
  }

  Future<ScheduleModel> updateSchedule(
      String id, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.schedule(id), data: body);
    return ScheduleModel.fromJson(res.data['data']);
  }

  Future<void> cancelSchedule(String id) async {
    await _api.patch(ApiEndpoints.scheduleCancel(id));
  }

  Future<void> deleteSchedule(String id) async {
    await _api.delete(ApiEndpoints.schedule(id));
  }

  Future<Map<String, dynamic>> getCalendar() async {
    final res = await _api.get(ApiEndpoints.scheduleCalendar);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAvailability() async {
    final res = await _api.get(ApiEndpoints.scheduleAvailability);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> addAttendee(String id, Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.scheduleAttendees(id), data: body);
  }

  Future<void> rsvp(String id, String response) async {
    await _api.patch(ApiEndpoints.scheduleRsvp(id),
        data: {'response': response});
  }
}
