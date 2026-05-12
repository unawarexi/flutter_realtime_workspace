import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/issue_model.dart';

class IssueRepository {
  final _api = ApiClient.instance;

  Future<List<IssueModel>> getIssues({
    String? projectId,
    String? workspaceId,
    String? assigneeId,
    String? status,
    String? priority,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _api.get(ApiEndpoints.issues, queryParameters: {
      if (projectId != null) 'projectId': projectId,
      if (workspaceId != null) 'workspaceId': workspaceId,
      if (assigneeId != null) 'assigneeId': assigneeId,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      'page': page,
      'limit': limit,
    });
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => IssueModel.fromJson(e)).toList();
  }

  Future<IssueModel> getIssue(String id) async {
    final res = await _api.get(ApiEndpoints.issue(id));
    return IssueModel.fromJson(res.data['data']);
  }

  Future<IssueModel> createIssue(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.issues, data: body);
    return IssueModel.fromJson(res.data['data']);
  }

  Future<IssueModel> updateIssue(String id, Map<String, dynamic> body) async {
    final res = await _api.put(ApiEndpoints.issue(id), data: body);
    return IssueModel.fromJson(res.data['data']);
  }

  Future<void> deleteIssue(String id) async {
    await _api.delete(ApiEndpoints.issue(id));
  }

  Future<List<Map<String, dynamic>>> getComments(String issueId) async {
    final res = await _api.get(ApiEndpoints.issueComments(issueId));
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<void> addComment(String issueId, String content) async {
    await _api.post(ApiEndpoints.issueComments(issueId),
        data: {'content': content});
  }

  Future<void> linkIssue(String issueId, Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.issueLink(issueId), data: body);
  }

  Future<void> addAttachment(String issueId, Map<String, dynamic> body) async {
    await _api.post(ApiEndpoints.issueAttachments(issueId), data: body);
  }
}
