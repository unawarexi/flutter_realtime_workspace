import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';

class AdminRepository {
  final _api = ApiClient.instance;

  Future<List<Map<String, dynamic>>> getTenants() async {
    final res = await _api.get(ApiEndpoints.adminTenants);
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<void> updateTenantStatus(String id, String status) async {
    await _api.put(ApiEndpoints.adminTenantStatus(id), data: {'status': status});
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _api.get(ApiEndpoints.adminStats);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> impersonate(String userId) async {
    final res = await _api.post(ApiEndpoints.adminImpersonate,
        data: {'userId': userId});
    return res.data['data'] as Map<String, dynamic>;
  }
}
