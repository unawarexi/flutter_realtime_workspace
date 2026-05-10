import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/document_model.dart';

class DocumentRepository {
  final _api = ApiClient.instance;

  Future<List<DocumentModel>> getDocuments({
    String? workspaceId,
    String? projectId,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get(ApiEndpoints.documents, queryParameters: {
      if (workspaceId != null) 'workspaceId': workspaceId,
      if (projectId != null) 'projectId': projectId,
      'page': page,
      'limit': limit,
    });
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => DocumentModel.fromJson(e)).toList();
  }

  Future<DocumentModel> getDocument(String id) async {
    final res = await _api.get(ApiEndpoints.document(id));
    return DocumentModel.fromJson(res.data['data']);
  }

  Future<DocumentModel> createDocument(Map<String, dynamic> body) async {
    final res = await _api.post(ApiEndpoints.documents, data: body);
    return DocumentModel.fromJson(res.data['data']);
  }

  Future<DocumentModel> updateDocument(
      String id, Map<String, dynamic> body) async {
    final res = await _api.patch(ApiEndpoints.document(id), data: body);
    return DocumentModel.fromJson(res.data['data']);
  }

  Future<void> deleteDocument(String id) async {
    await _api.delete(ApiEndpoints.document(id));
  }

  Future<List<Map<String, dynamic>>> getVersionHistory(String id) async {
    final res = await _api.get(ApiEndpoints.documentVersions(id));
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  Future<void> shareDocument(String id, List<String> userIds) async {
    await _api.post(ApiEndpoints.documentShare(id), data: {'userIds': userIds});
  }
}
