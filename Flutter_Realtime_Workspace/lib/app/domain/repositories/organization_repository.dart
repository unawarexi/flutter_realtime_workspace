import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/organization_model.dart';

class OrganizationRepository {
  final _api = ApiClient.instance;

  Future<OrganizationModel> getMyOrganization() async {
    final res = await _api.get(ApiEndpoints.myOrganization);
    return OrganizationModel.fromJson(res.data['data']);
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
    final res = await _api.patch(ApiEndpoints.organization(id), data: body);
    return OrganizationModel.fromJson(res.data['data']);
  }

  Future<String> generateInviteCode(String orgId) async {
    final res = await _api.post(ApiEndpoints.orgInviteCode(orgId));
    return res.data['data']['code'] as String;
  }

  Future<void> joinByInviteCode(String code) async {
    await _api.post(ApiEndpoints.orgJoin, data: {'code': code});
  }

  Future<List<Map<String, dynamic>>> getMembers(String orgId) async {
    final res = await _api.get(ApiEndpoints.orgMembers(orgId));
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<void> removeMember(String orgId, String userId) async {
    await _api.delete(ApiEndpoints.orgMember(orgId, userId));
  }

  Future<void> updateMemberRole(
      String orgId, String userId, String role) async {
    await _api.patch(ApiEndpoints.orgMember(orgId, userId),
        data: {'role': role});
  }
}
