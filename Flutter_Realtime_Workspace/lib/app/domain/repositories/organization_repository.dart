import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/organization_model.dart';

class OrganizationRepository {
  final _api = ApiClient.instance;

  Future<List<OrganizationModel>> getOrganizations() async {
    final res = await _api.get(ApiEndpoints.organizations);
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => OrganizationModel.fromJson(e)).toList();
  }

  Future<OrganizationModel> getOrganization(String id) async {
    final res = await _api.get(ApiEndpoints.organization(id));
    return OrganizationModel.fromJson(res.data['data']);
  }

  Future<OrganizationModel> createOrganization(
      Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.organizations, data: body);
    return OrganizationModel.fromJson(res.data['data']);
  }

  Future<OrganizationModel> updateOrganization(
      String id, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.organization(id), data: body);
    return OrganizationModel.fromJson(res.data['data']);
  }

  Future<void> invite(String orgId, Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.orgInvite(orgId), data: body);
  }

  Future<List<Map<String, dynamic>>> getMembers(String orgId) async {
    final res = await _api.get(ApiEndpoints.orgMembers(orgId));
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<void> removeMember(String orgId, String userId) async {
    await _api.delete(ApiEndpoints.orgMember(orgId, userId));
  }

  Future<Map<String, dynamic>> getSettings(String orgId) async {
    final res = await _api.get(ApiEndpoints.orgSettings(orgId));
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSettings(
      String orgId, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.orgSettings(orgId), data: body);
    return res.data['data'] as Map<String, dynamic>;
  }
}
