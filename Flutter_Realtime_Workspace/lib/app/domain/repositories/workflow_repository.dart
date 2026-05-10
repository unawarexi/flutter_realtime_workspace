import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/workflow_model.dart';

class WorkflowRepository {
  final _api = ApiClient.instance;

  Future<List<WorkflowModel>> getWorkflows(String workspaceId) async {
    final res = await _api.get(ApiEndpoints.workflows,
        queryParameters: {'workspaceId': workspaceId});
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => WorkflowModel.fromJson(e)).toList();
  }

  Future<WorkflowModel> getWorkflow(String id) async {
    final res = await _api.get(ApiEndpoints.workflow(id));
    return WorkflowModel.fromJson(res.data['data']);
  }

  Future<WorkflowModel> createWorkflow(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.workflows, data: body);
    return WorkflowModel.fromJson(res.data['data']);
  }

  Future<WorkflowModel> updateWorkflow(
      String id, Map<String, dynamic> body) async {
    final res = await _api.patch(ApiEndpoints.workflow(id), data: body);
    return WorkflowModel.fromJson(res.data['data']);
  }

  Future<void> deleteWorkflow(String id) async {
    await _api.delete(ApiEndpoints.workflow(id));
  }

  Future<void> toggleWorkflow(String id, bool isActive) async {
    await _api.patch(ApiEndpoints.workflow(id), data: {'isActive': isActive});
  }

  Future<List<Map<String, dynamic>>> getWorkflowRuns(String id) async {
    final res = await _api.get(ApiEndpoints.workflowRuns(id));
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }
}
