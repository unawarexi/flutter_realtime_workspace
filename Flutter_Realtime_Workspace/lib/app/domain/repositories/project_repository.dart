import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/project_model.dart';

class ProjectRepository {
  final _api = ApiClient.instance;

  Future<List<ProjectModel>> getProjects({String? workspaceId}) async {
    final res = await _api.get(
      ApiEndpoints.projects,
      queryParameters: workspaceId != null ? {'workspaceId': workspaceId} : null,
    );
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => ProjectModel.fromJson(e)).toList();
  }

  Future<ProjectModel> getProject(String id) async {
    final res = await _api.get(ApiEndpoints.project(id));
    return ProjectModel.fromJson(res.data['data']);
  }

  Future<ProjectModel> createProject(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.projects, data: body);
    return ProjectModel.fromJson(res.data['data']);
  }

  Future<String> generateKey() async {
    final res = await _api.get(ApiEndpoints.projectGenerateKey);
    return res.data['data']['key'] as String;
  }

  Future<ProjectModel> updateProject(
      String id, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.project(id), data: body);
    return ProjectModel.fromJson(res.data['data']);
  }

  Future<void> deleteProject(String id) async {
    await _api.delete(ApiEndpoints.project(id));
  }

  Future<List<Map<String, dynamic>>> getProjectMembers(String id) async {
    final res = await _api.get(ApiEndpoints.projectMembers(id));
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<void> addMember(String projectId, String userId) async {
    await _api.post(ApiEndpoints.projectMembers(projectId),
        data: {'userId': userId});
  }

  Future<void> removeMember(String projectId, String userId) async {
    await _api.delete(ApiEndpoints.projectMember(projectId, userId));
  }

  Future<void> starProject(String id) async {
    await _api.patch(ApiEndpoints.projectStar(id));
  }

  Future<void> archiveProject(String id) async {
    await _api.patch(ApiEndpoints.projectArchive(id));
  }

  Future<void> updateCollaborators(
      String id, List<String> collaborators) async {
    await _api.patch(ApiEndpoints.projectCollaborators(id),
        data: {'collaborators': collaborators});
  }

  Future<void> addTimeline(String id, Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.projectTimeline(id), data: body);
  }

  Future<void> addAttachment(String id, Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.projectAttachments(id), data: body);
  }

  Future<void> deleteAttachment(String id, String attachmentId) async {
    await _api.delete(ApiEndpoints.projectAttachment(id, attachmentId));
  }
}
