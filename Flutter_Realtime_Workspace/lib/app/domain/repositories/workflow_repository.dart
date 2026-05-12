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
    final res = await _api.put(ApiEndpoints.workflow(id), data: body);
    return WorkflowModel.fromJson(res.data['data']);
  }

  Future<void> deleteWorkflow(String id) async {
    await _api.delete(ApiEndpoints.workflow(id));
  }

  Future<void> toggleWorkflow(String id) async {
    await _api.patch(ApiEndpoints.workflowToggle(id));
  }

  Future<Map<String, dynamic>> testWorkflow(String id) async {
    final res = await _api.post(ApiEndpoints.workflowTest(id));
    return res.data['data'] as Map<String, dynamic>;
  }
}
