import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_realtime_workspace/core/config/environment.dart';

class UserApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${Environment.baseUrl}userinfo',
       connectTimeout: const Duration(minutes: 2), // ⏱️ 2 minutes
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(minutes: 2),
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
    print('[UserApi] Firebase ID token for user ${user.email}: $token');
    return token;
  }

  // Simplified response handling - returns dynamic
  static dynamic _safeResponseCast(dynamic responseData) {
    if (responseData == null) {
      throw Exception("Response data is null");
    }
    return responseData;
  }

  // Simplified list response handling - returns dynamic
  static dynamic _safeListResponseCast(dynamic responseData) {
    if (responseData == null) {
      throw Exception("Response data is null");
    }
    return responseData;
  }

  // Get current user's info from backend
  static Future<dynamic> getMyUserInfo() async {
    try {
      final idToken = await _getToken();
      print('[UserApi] GET /me with token: $idToken');

      final response = await _dio.get(
        "/me",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );

      print('[UserApi] Raw response from /me: ${response.data}');
      print('[UserApi] Response type: ${response.data.runtimeType}');

      final safeData = _safeResponseCast(response.data);
      print('[UserApi] Processed response from /me: $safeData');

      return safeData;
    } on DioException catch (e) {
      print('[UserApi][ERROR] getMyUserInfo DioException: ${e.message}');
      print('[UserApi][ERROR] Response status: ${e.response?.statusCode}');
      print('[UserApi][ERROR] Response data: ${e.response?.data}');
      print('[UserApi][ERROR] Response headers: ${e.response?.headers}');

      // Print raw response if not a Map
      if (e.response?.data != null && e.response?.data is! Map) {
        print(
            '[UserApi][ERROR] Raw response body: ${e.response?.data.toString()}');
      }

      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Unknown error occurred';
      throw Exception(errorMsg);
    } catch (e) {
      print('[UserApi][ERROR] getMyUserInfo: $e');
      rethrow;
    }
  }

  // Create or update (upsert) user info (supports image upload)
  static Future<dynamic> createOrUpdateMyUserInfo(dynamic data,
      {String? imagePath}) async {
    try {
      final idToken = await _getToken();
      final cleanData = _cleanPayloadData(data);
      print('[UserApi] Cleaned payload data: $cleanData');

      // Print the full URL being called
      final fullUrl = _dio.options.baseUrl.endsWith('/')
          ? '${_dio.options.baseUrl}me'
          : '${_dio.options.baseUrl}/me';
      print('[UserApi] Full POST URL: $fullUrl');

      Response response;
      if (imagePath != null) {
        final formData = FormData.fromMap({
          ...cleanData,
          'profilePicture':
              await MultipartFile.fromFile(imagePath, filename: 'profile.jpg'),
        });

        print(
            '[UserApi] POST /me (multipart) with token: $idToken, imagePath: $imagePath');
        print(
            '[UserApi] FormData fields: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')}');

        response = await _dio.post(
          "/me",
          data: formData,
          options: Options(
            headers: {
              "Authorization": "Bearer $idToken",
              "Content-Type": "multipart/form-data",
            },
          ),
        );
      } else {
        print('[UserApi] POST /me with token: $idToken, data: $cleanData');

        response = await _dio.post(
          "/me",
          data: cleanData,
          options: Options(
            headers: {
              "Authorization": "Bearer $idToken",
              "Content-Type": "application/json",
            },
          ),
        );
      }

      print('[UserApi] Raw response from POST /me: ${response.data}');
      print('[UserApi] Response type: ${response.data.runtimeType}');

      final safeData = _safeResponseCast(response.data);
      print('[UserApi] Processed response from POST /me: $safeData');

      return safeData;
    } on DioException catch (e) {
      print(
          '[UserApi][ERROR] createOrUpdateMyUserInfo DioException: ${e.message}');
      print('[UserApi][ERROR] DioException details: $e');
      print('[UserApi][ERROR] Request data: ${e.requestOptions.data}');
      print('[UserApi][ERROR] Request headers: ${e.requestOptions.headers}');
      print('[UserApi][ERROR] Response status: ${e.response?.statusCode}');
      print('[UserApi][ERROR] Response data: ${e.response?.data}');
      print('[UserApi][ERROR] Response headers: ${e.response?.headers}');

      // Print raw response if not a Map
      if (e.response?.data != null && e.response?.data is! Map) {
        print(
            '[UserApi][ERROR] Raw response body: ${e.response?.data.toString()}');
      }

      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to create/update user info';
      throw Exception(errorMsg);
    } catch (e) {
      print('[UserApi][ERROR] createOrUpdateMyUserInfo: $e');
      rethrow;
    }
  }

  // Update user info (supports image upload)
  static Future<dynamic> updateMyUserInfo(dynamic data,
      {String? imagePath}) async {
    try {
      final idToken = await _getToken();

      // Clean and validate data before sending
      final cleanData = _cleanPayloadData(data);
      print('[UserApi] Cleaned payload data for update: $cleanData');

      Response response;
      if (imagePath != null) {
        final formData = FormData.fromMap({
          ...cleanData,
          'profilePicture':
              await MultipartFile.fromFile(imagePath, filename: 'profile.jpg'),
        });

        print(
            '[UserApi] PUT /me (multipart) with token: $idToken, imagePath: $imagePath');

        response = await _dio.put(
          "/me",
          data: formData,
          options: Options(
            headers: {
              "Authorization": "Bearer $idToken",
              "Content-Type": "multipart/form-data",
            },
          ),
        );
      } else {
        print('[UserApi] PUT /me with token: $idToken, data: $cleanData');

        response = await _dio.put(
          "/me",
          data: cleanData,
          options: Options(
            headers: {
              "Authorization": "Bearer $idToken",
              "Content-Type": "application/json",
            },
          ),
        );
      }

      print('[UserApi] Raw response from PUT /me: ${response.data}');
      final safeData = _safeResponseCast(response.data);
      print('[UserApi] Processed response from PUT /me: $safeData');

      return safeData;
    } on DioException catch (e) {
      print('[UserApi][ERROR] updateMyUserInfo DioException: ${e.message}');
      print('[UserApi][ERROR] Response status: ${e.response?.statusCode}');
      print('[UserApi][ERROR] Response data: ${e.response?.data}');

      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to update user info';
      throw Exception(errorMsg);
    } catch (e) {
      print('[UserApi][ERROR] updateMyUserInfo: $e');
      rethrow;
    }
  }

  // Helper method to clean and validate payload data - now accepts dynamic
  static dynamic _cleanPayloadData(dynamic data) {
    if (data == null) return {};

    if (data is Map) {
      final cleanData = <String, dynamic>{};

      for (final entry in data.entries) {
        final key = entry.key?.toString() ?? '';
        final value = entry.value;

        // Skip null or empty string values
        if (value == null || (value is String && value.trim().isEmpty)) {
          continue;
        }

        // Handle nested objects
        if (value is Map) {
          final nestedClean = _cleanPayloadData(value);
          if (nestedClean is Map && nestedClean.isNotEmpty) {
            cleanData[key] = nestedClean;
          }
        }
        // Handle arrays
        else if (value is List) {
          final cleanList = value
              .where((item) =>
                  item != null && (item is! String || item.trim().isNotEmpty))
              .toList();
          if (cleanList.isNotEmpty) {
            cleanData[key] = cleanList;
          }
        }
        // Handle primitive values
        else {
          cleanData[key] = value;
        }
      }

      return cleanData;
    }

    return data;
  }

  // Delete user info
  static Future<void> deleteMyUserInfo() async {
    try {
      final idToken = await _getToken();
      print('[UserApi] DELETE /me with token: $idToken');

      await _dio.delete(
        "/me",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );

      print('[UserApi] User info deleted successfully');
    } on DioException catch (e) {
      print('[UserApi][ERROR] deleteMyUserInfo DioException: ${e.message}');

      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to delete user info';
      throw Exception(errorMsg);
    } catch (e) {
      print('[UserApi][ERROR] deleteMyUserInfo: $e');
      rethrow;
    }
  }

  // Regenerate invite code
  static Future<dynamic> regenerateInviteCode() async {
    try {
      final idToken = await _getToken();
      print('[UserApi] POST /me/regenerate-invite with token: $idToken');

      final response = await _dio.post(
        "/me/regenerate-invite",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );

      print(
          '[UserApi] Raw response from /me/regenerate-invite: ${response.data}');
      final safeData = _safeResponseCast(response.data);
      print(
          '[UserApi] Processed response from /me/regenerate-invite: $safeData');

      return safeData;
    } on DioException catch (e) {
      print('[UserApi][ERROR] regenerateInviteCode DioException: ${e.message}');

      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to regenerate invite code';
      throw Exception(errorMsg);
    } catch (e) {
      print('[UserApi][ERROR] regenerateInviteCode: $e');
      rethrow;
    }
  }

  // Upload profile picture only
  static Future<dynamic> uploadProfilePicture(String imagePath) async {
    try {
      final idToken = await _getToken();
      final formData = FormData.fromMap({
        'profilePicture':
            await MultipartFile.fromFile(imagePath, filename: 'profile.jpg'),
      });

      print(
          '[UserApi] POST /me/upload-picture with token: $idToken, imagePath: $imagePath');

      final response = await _dio.post(
        "/me/upload-picture",
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $idToken",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      print('[UserApi] Raw response from /me/upload-picture: ${response.data}');
      final safeData = _safeResponseCast(response.data);
      print('[UserApi] Processed response from /me/upload-picture: $safeData');

      return safeData;
    } on DioException catch (e) {
      print('[UserApi][ERROR] uploadProfilePicture DioException: ${e.message}');

      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to upload profile picture';
      throw Exception(errorMsg);
    } catch (e) {
      print('[UserApi][ERROR] uploadProfilePicture: $e');
      rethrow;
    }
  }

  // Admin/utility: get all user infos
  static Future<dynamic> getAllUserInfos() async {
    try {
      final idToken = await _getToken();
      print('[UserApi] GET / (all users) with token: $idToken');

      final response = await _dio.get(
        "/",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );

      print('[UserApi] Raw response from GET /: ${response.data}');
      final safeData = _safeListResponseCast(response.data);
      print('[UserApi] Processed response from GET /: $safeData');

      return safeData;
    } on DioException catch (e) {
      print('[UserApi][ERROR] getAllUserInfos DioException: ${e.message}');

      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to get all user infos';
      throw Exception(errorMsg);
    } catch (e) {
      print('[UserApi][ERROR] getAllUserInfos: $e');
      rethrow;
    }
  }

  // Admin/utility: get user info by id
  static Future<dynamic> getUserInfoById(String id) async {
    try {
      final idToken = await _getToken();
      print('[UserApi] GET /$id with token: $idToken');

      final response = await _dio.get(
        "/$id",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );

      print('[UserApi] Raw response from GET /$id: ${response.data}');
      final safeData = _safeResponseCast(response.data);
      print('[UserApi] Processed response from GET /$id: $safeData');

      return safeData;
    } on DioException catch (e) {
      print('[UserApi][ERROR] getUserInfoById DioException: ${e.message}');

      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to get user info by ID';
      throw Exception(errorMsg);
    } catch (e) {
      print('[UserApi][ERROR] getUserInfoById: $e');
      rethrow;
    }
  }

  // Admin: revoke referral code for a user
  static Future<dynamic> revokeUserReferralCode(String id) async {
    try {
      final idToken = await _getToken();
      print('[UserApi] POST /$id/revoke-referral with token: $idToken');

      final response = await _dio.post(
        "/$id/revoke-referral",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );

      print(
          '[UserApi] Raw response from /$id/revoke-referral: ${response.data}');
      final safeData = _safeResponseCast(response.data);
      print(
          '[UserApi] Processed response from /$id/revoke-referral: $safeData');

      return safeData;
    } on DioException catch (e) {
      print(
          '[UserApi][ERROR] revokeUserReferralCode DioException: ${e.message}');

      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to revoke referral code';
      throw Exception(errorMsg);
    } catch (e) {
      print('[UserApi][ERROR] revokeUserReferralCode: $e');
      rethrow;
    }
  }

  // Admin: update invite permissions for a user
  static Future<dynamic> updateInvitePermissions(
      String id, dynamic invitePermissions) async {
    try {
      final idToken = await _getToken();
      final payload = {"invitePermissions": invitePermissions};

      print('[UserApi] PATCH /$id/invite-permissions with token: $idToken');
      print('[UserApi] Payload: $payload');

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

      print(
          '[UserApi] Raw response from /$id/invite-permissions: ${response.data}');
      final safeData = _safeResponseCast(response.data);
      print(
          '[UserApi] Processed response from /$id/invite-permissions: $safeData');

      return safeData;
    } on DioException catch (e) {
      print(
          '[UserApi][ERROR] updateInvitePermissions DioException: ${e.message}');

      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to update invite permissions';
      throw Exception(errorMsg);
    } catch (e) {
      print('[UserApi][ERROR] updateInvitePermissions: $e');
      rethrow;
    }
  }

  // Fetch user by invite code or email
  static Future<dynamic> getUserByInviteCodeOrEmail(
      {String? inviteCode, String? email}) async {
    try {
      final idToken = await _getToken();
      final queryParams = <String, String>{};
      if (inviteCode != null && inviteCode.isNotEmpty)
        queryParams['inviteCode'] = inviteCode;
      if (email != null && email.isNotEmpty) queryParams['email'] = email;
      if (queryParams.isEmpty) throw Exception("Provide inviteCode or email");

      final uri = Uri.parse("${_dio.options.baseUrl}/find")
          .replace(queryParameters: queryParams);
      final response = await _dio.getUri(
        uri,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      final safeData = _safeResponseCast(response.data);
      return safeData;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to fetch user by invite code/email';
      throw Exception(errorMsg);
    } catch (e) {
      rethrow;
    }
  }
}
