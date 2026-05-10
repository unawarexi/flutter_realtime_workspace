import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/audit_model.dart';

class AuditRepository {
  final _api = ApiClient.instance;

  Future<List<AuditLogModel>> getAuditLogs({
    String? workspaceId,
    String? orgId,
    String? actorId,
    String? resourceType,
    String? action,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _api.get(ApiEndpoints.auditLogs, queryParameters: {
      if (workspaceId != null) 'workspaceId': workspaceId,
      if (orgId != null) 'orgId': orgId,
      if (actorId != null) 'actorId': actorId,
      if (resourceType != null) 'resourceType': resourceType,
      if (action != null) 'action': action,
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
      'page': page,
      'limit': limit,
    });
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => AuditLogModel.fromJson(e)).toList();
  }

  Future<AuditLogModel> getAuditLog(String id) async {
    final res = await _api.get(ApiEndpoints.auditLog(id));
    return AuditLogModel.fromJson(res.data['data']);
  }

  Future<void> exportAuditLogs(Map<String, dynamic> filters) async {
    await _api.post(ApiEndpoints.auditExport, data: filters);
  }
}
