import 'package:dio/dio.dart';
import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/app/domain/models/user_model.dart';
import 'package:flutter_realtime_workspace/app/domain/models/referral_model.dart';

class UserRepository {
  final _api = ApiClient.instance;

  Future<UserModel> getProfile() async {
    final res = await _api.get(ApiEndpoints.me);
    return UserModel.fromJson(res.data['data']);
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? bio,
  }) async {
    final res = await _api.put(ApiEndpoints.me, data: {
      if (fullName != null) 'fullName': fullName,
      if (bio != null) 'bio': bio,
    });
    return UserModel.fromJson(res.data['data']);
  }

  Future<UserModel> updateAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'profilePicture': await MultipartFile.fromFile(filePath),
    });
    final res = await _api.upload(ApiEndpoints.userUploadPicture, formData: formData);
    return UserModel.fromJson(res.data['data']);
  }

  Future<List<UserModel>> getUsers({String? query}) async {
    final res = await _api.get(ApiEndpoints.users, queryParameters: {
      if (query != null && query.isNotEmpty) 'q': query,
    });
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getUserById(String userId) async {
    final res = await _api.get(ApiEndpoints.userById(userId));
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<ReferralModel> regenerateInviteCode() async {
    final res = await _api.post(ApiEndpoints.userRegenerateInviteCode);
    return ReferralModel.fromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }
}
