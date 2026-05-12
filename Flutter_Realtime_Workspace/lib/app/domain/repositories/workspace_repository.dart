import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/workspace_model.dart';

class WorkspaceRepository {
  final _api = ApiClient.instance;

  Future<List<WorkspaceModel>> getWorkspaces() async {
    final res = await _api.get(ApiEndpoints.workspaces);
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => WorkspaceModel.fromJson(e)).toList();
  }

  Future<WorkspaceModel> getWorkspace(String id) async {
    final res = await _api.get(ApiEndpoints.workspace(id));
    return WorkspaceModel.fromJson(res.data['data']);
  }

  Future<WorkspaceModel> createWorkspace(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.workspaces, data: body);
    return WorkspaceModel.fromJson(res.data['data']);
  }

  Future<WorkspaceModel> updateWorkspace(
      String id, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.workspace(id), data: body);
    return WorkspaceModel.fromJson(res.data['data']);
  }

  Future<void> deleteWorkspace(String id) async {
    await _api.delete(ApiEndpoints.workspace(id));
  }

  Future<List<Map<String, dynamic>>> getWorkspaceMembers(String id) async {
    final res = await _api.get(ApiEndpoints.workspaceMembers(id));
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<void> addMember(String workspaceId, Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.workspaceMembers(workspaceId), data: body);
  }

  Future<void> removeMember(String workspaceId, String userId) async {
    await _api.delete(ApiEndpoints.workspaceMember(workspaceId, userId));
  }
}
