import 'package:dio/dio.dart';
import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/storage_model.dart';

class StorageRepository {
  final _api = ApiClient.instance;

  Future<StorageFileModel> uploadFile({
    required String filePath,
    required String fileName,
    required String mimeType,
    String? workspaceId,
    String? projectId,
    String? taskId,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      if (workspaceId != null) 'workspaceId': workspaceId,
      if (projectId != null) 'projectId': projectId,
      if (taskId != null) 'taskId': taskId,
    });

    final res = await _api.post(
      ApiEndpoints.storageUpload,
      data: formData,
      onSendProgress: onProgress,
    );
    return StorageFileModel.fromJson(res.data['data']);
  }

  Future<List<StorageFileModel>> getFiles({
    String? workspaceId,
    String? projectId,
    String? taskId,
    String? mimeType,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get(ApiEndpoints.storageFiles, queryParameters: {
      if (workspaceId != null) 'workspaceId': workspaceId,
      if (projectId != null) 'projectId': projectId,
      if (taskId != null) 'taskId': taskId,
      if (mimeType != null) 'mimeType': mimeType,
      'page': page,
      'limit': limit,
    });
    final data = res.data['data'] as List? ?? [];
    return data.map((e) => StorageFileModel.fromJson(e)).toList();
  }

  Future<void> deleteFile(String id) async {
    await _api.delete(ApiEndpoints.storageFile(id));
  }

  Future<String> getDownloadUrl(String id) async {
    final res = await _api.get(ApiEndpoints.storageFileUrl(id));
    return res.data['data']['url'] as String;
  }
}
