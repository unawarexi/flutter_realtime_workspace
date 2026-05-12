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

    final res = await _api.upload(
      ApiEndpoints.storageUpload,
      formData: formData,
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
    final res = await _api.get(ApiEndpoints.storageAssets, queryParameters: {
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

  Future<StorageFileModel> getFile(String id) async {
    final res = await _api.get(ApiEndpoints.storageAsset(id));
    return StorageFileModel.fromJson(res.data['data']);
  }

  Future<void> deleteFile(String id) async {
    await _api.delete(ApiEndpoints.storageAsset(id));
  }

  Future<Map<String, dynamic>> attachToResource(
      String id, Map<String, dynamic> body) async {
    final res =
        await _api.patch(ApiEndpoints.storageAssetAttach(id), data: body);
    return res.data['data'] as Map<String, dynamic>;
  }
}
