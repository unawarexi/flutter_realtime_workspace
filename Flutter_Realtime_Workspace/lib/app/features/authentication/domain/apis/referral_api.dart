import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_realtime_workspace/core/config/environment.dart';

class ReferralApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${Environment.baseUrl}userinfo',
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not authenticated");
    final token = await user.getIdToken(true);
    if (token == null) throw Exception("Failed to retrieve ID token");
    return token;
  }

  static Map<String, dynamic> _safeResponseCast(dynamic responseData) {
    if (responseData == null) throw Exception("Response data is null");
    if (responseData is Map<String, dynamic>) return responseData;
    if (responseData is Map) return Map<String, dynamic>.from(responseData);
    if (responseData is List) {
      if (responseData.isNotEmpty && responseData.first is Map) {
        return Map<String, dynamic>.from(responseData.first);
      } else {
        throw Exception("Response data is a List but empty or not a Map");
      }
    }
    throw Exception("Invalid response data type: ${responseData.runtimeType}");
  }

  // Regenerate invite code
  static Future<Map<String, dynamic>> regenerateInviteCode() async {
    try {
      final idToken = await _getToken();
      final response = await _dio.post(
        "/me/regenerate-invite",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      final safeData = _safeResponseCast(response.data);
      return safeData;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to regenerate invite code';
      throw Exception(errorMsg);
    }
  }

  // Admin: revoke referral code for a user
  static Future<Map<String, dynamic>> revokeUserReferralCode(String id) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.post(
        "/$id/revoke-referral",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      final safeData = _safeResponseCast(response.data);
      return safeData;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to revoke referral code';
      throw Exception(errorMsg);
    }
  }

  // Admin: update invite permissions for a user
  static Future<Map<String, dynamic>> updateInvitePermissions(
      String id, Map<String, dynamic> invitePermissions) async {
    try {
      final idToken = await _getToken();
      final payload = {"invitePermissions": invitePermissions};
      final response = await _dio.patch(
        "/$id/invite-permissions",
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $idToken",
            "Content-Type": "application/json",
          },
        ),
      );
      final safeData = _safeResponseCast(response.data);
      return safeData;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to update invite permissions';
      throw Exception(errorMsg);
    }
  }

  // Add more referral-related API methods here as needed (e.g., getMyReferralStats, getReferralChain)
}
