import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/team_model.dart';

class TeamRepository {
  final _api = ApiClient.instance;

  Future<List<TeamModel>> getTeams(String workspaceId) async {
    final res = await _api.get(ApiEndpoints.teams,
        queryParameters: {'workspaceId': workspaceId});
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => TeamModel.fromJson(e)).toList();
  }

  Future<TeamModel> getTeam(String id) async {
    final res = await _api.get(ApiEndpoints.team(id));
    return TeamModel.fromJson(res.data['data']);
  }

  Future<TeamModel> createTeam(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.teams, data: body);
    return TeamModel.fromJson(res.data['data']);
  }

  Future<TeamModel> updateTeam(String id, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.team(id), data: body);
    return TeamModel.fromJson(res.data['data']);
  }

  Future<void> deleteTeam(String id) async {
    await _api.delete(ApiEndpoints.team(id));
  }

  Future<void> invite(String teamId, Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.teamInvite(teamId), data: body);
  }
}
