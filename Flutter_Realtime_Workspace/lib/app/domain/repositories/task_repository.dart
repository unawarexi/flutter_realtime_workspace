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
    final res = await _api.patch(ApiEndpoints.task(id), data: body);
    return TaskModel.fromJson(res.data['data']);
  }

  Future<void> deleteTask(String id) async {
    await _api.delete(ApiEndpoints.task(id));
  }

  Future<void> reorderTasks(String projectId, List<Map<String, dynamic>> order) async {
    await _api.post(ApiEndpoints.taskReorder(projectId), data: {'tasks': order});
  }
}
