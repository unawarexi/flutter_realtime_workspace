import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/task_model.dart';

class TaskRepository {
  final _api = ApiClient.instance;

  Future<List<TaskModel>> getTasks({
    String? projectId,
    String? workspaceId,
    String? assigneeId,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _api.get(ApiEndpoints.tasks, queryParameters: {
      if (projectId != null) 'projectId': projectId,
      if (workspaceId != null) 'workspaceId': workspaceId,
      if (assigneeId != null) 'assigneeId': assigneeId,
      if (status != null) 'status': status,
      'page': page,
      'limit': limit,
    });
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<TaskModel> getTask(String id) async {
    final res = await _api.get(ApiEndpoints.task(id));
    return TaskModel.fromJson(res.data['data']);
  }

  Future<TaskModel> createTask(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.tasks, data: body);
    return TaskModel.fromJson(res.data['data']);
  }

  Future<TaskModel> updateTask(String id, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.task(id), data: body);
    return TaskModel.fromJson(res.data['data']);
  }

  Future<void> deleteTask(String id) async {
    await _api.delete(ApiEndpoints.task(id));
  }

  Future<void> addComment(String id, String content) async {
    await _api.post(ApiEndpoints.taskComments(id), data: {'content': content});
  }

  Future<void> updateChecklist(
      String id, List<Map<String, dynamic>> checklist) async {
    await _api.put(ApiEndpoints.taskChecklist(id), data: {'checklist': checklist});
  }

  Future<void> addAttachment(String id, Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.taskAttachments(id), data: body);
  }
}
