import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/integration_model.dart';

class IntegrationRepository {
  final _api = ApiClient.instance;

  Future<List<IntegrationModel>> getIntegrations(String workspaceId) async {
    final res = await _api.get(ApiEndpoints.integrations,
        queryParameters: {'workspaceId': workspaceId});
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => IntegrationModel.fromJson(e)).toList();
  }

  Future<IntegrationModel> installIntegration(
      Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.integrations, data: body);
    return IntegrationModel.fromJson(res.data['data']);
  }

  Future<IntegrationModel> updateIntegration(
      String id, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.integration(id), data: body);
    return IntegrationModel.fromJson(res.data['data']);
  }

  Future<void> uninstallIntegration(String id) async {
    await _api.delete(ApiEndpoints.integration(id));
  }

  Future<Map<String, dynamic>> testIntegration(String id) async {
    final res = await _api.post(ApiEndpoints.integrationTest(id));
    return res.data['data'] as Map<String, dynamic>;
  }
}
