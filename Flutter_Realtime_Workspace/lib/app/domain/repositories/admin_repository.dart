import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';

class AdminRepository {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> getOrgStats(String orgId) async {
    final res = await _api.get(ApiEndpoints.adminOrgStats(orgId));
    return res.data['data'];
  }

  Future<List<Map<String, dynamic>>> getAllUsers({
    String? orgId,
    String? workspaceId,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _api.get(ApiEndpoints.adminUsers, queryParameters: {
      if (orgId != null) 'orgId': orgId,
      if (workspaceId != null) 'workspaceId': workspaceId,
      'page': page,
      'limit': limit,
    });
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<void> suspendUser(String userId) async {
    await _api.post(ApiEndpoints.adminSuspendUser(userId));
  }

  Future<void> unsuspendUser(String userId) async {
    await _api.post(ApiEndpoints.adminUnsuspendUser(userId));
  }

  Future<void> deleteUserAccount(String userId) async {
    await _api.delete(ApiEndpoints.adminDeleteUser(userId));
  }

  Future<void> impersonateUser(String userId) async {
    await _api.post(ApiEndpoints.adminImpersonate(userId));
  }

  Future<List<Map<String, dynamic>>> getSystemLogs({
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _api.get(ApiEndpoints.adminLogs,
        queryParameters: {'page': page, 'limit': limit});
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> getSystemHealth() async {
    final res = await _api.get(ApiEndpoints.adminHealth);
    return res.data['data'];
  }

  Future<void> updateOrgSettings(
      String orgId, Map<String, dynamic> settings) async {
    await _api.patch(ApiEndpoints.adminOrgSettings(orgId), data: settings);
  }

  Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    final res = await _api.get(ApiEndpoints.adminApprovals);
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<void> approveRequest(String requestId) async {
    await _api.post(ApiEndpoints.adminApprove(requestId));
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    await _api.post(ApiEndpoints.adminReject(requestId),
        data: {'reason': reason});
  }
}
