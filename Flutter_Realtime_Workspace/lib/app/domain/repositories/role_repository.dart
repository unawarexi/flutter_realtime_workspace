import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/role_model.dart';

class RoleRepository {
  final _api = ApiClient.instance;

  // ── Roles ─────────────────────────────────────────────────────────────────

  Future<List<RoleModel>> getRoles() async {
    final res = await _api.get(ApiEndpoints.identityRoles);
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => RoleModel.fromJson(e)).toList();
  }

  Future<RoleModel> createRole(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.identityRoles, data: body);
    return RoleModel.fromJson(res.data['data']);
  }

  Future<RoleModel> updateRole(String id, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.identityRole(id), data: body);
    return RoleModel.fromJson(res.data['data']);
  }

  Future<void> deleteRole(String id) async {
    await _api.delete(ApiEndpoints.identityRole(id));
  }

  // ── Policies ──────────────────────────────────────────────────────────────

  Future<List<PolicyModel>> getPolicies() async {
    final res = await _api.get(ApiEndpoints.identityPolicies);
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => PolicyModel.fromJson(e)).toList();
  }

  Future<PolicyModel> createPolicy(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.identityPolicies, data: body);
    return PolicyModel.fromJson(res.data['data']);
  }

  Future<PolicyModel> updatePolicy(
      String id, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.identityPolicy(id), data: body);
    return PolicyModel.fromJson(res.data['data']);
  }

  // ── User permissions ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserPermissions(String userId) async {
    final res = await _api.get(ApiEndpoints.userPermissions(userId));
    return res.data['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _api.put(ApiEndpoints.userRole(userId), data: {'role': role});
  }
}
