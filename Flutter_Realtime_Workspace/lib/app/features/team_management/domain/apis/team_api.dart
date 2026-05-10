import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_realtime_workspace/core/config/environment.dart';
import 'package:flutter_realtime_workspace/core/network/auto_retry.dart'; // <-- import auto_retry

class TeamApi {
  // Use the retry-enabled Dio instance from NetworkModule
   static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${Environment.baseUrl}teams',
      connectTimeout: const Duration(minutes: 2), // ⏱️ 2 minutes
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(minutes: 2),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );
  // static final Dio _dio = NetworkModule.getDioWithBaseUrl(
  //   '${Environment.baseUrl}teams', // Environment.baseUrl must end with /
  // );

  static Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not authenticated");
    final token = await user.getIdToken(true);
    if (token == null) throw Exception("Failed to retrieve ID token");
    return token;
  }

  // ------------------------------------------- Create a new team
  static Future<dynamic> createTeam(dynamic data) async {
    try {
      final idToken = await _getToken();
      final url = "${_dio.options.baseUrl}/";
      print('[TeamApi] POST $url with data: $data');
      final response = await _dio.post(
        "/",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('[TeamApi][ERROR] createTeam DioException: ${e.message}');
      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to create team';
      throw Exception(errorMsg);
    } catch (e) {
      print('[TeamApi][ERROR] createTeam: $e');
      rethrow;
    }
  }

  // Get all teams for the authenticated user
  static Future<dynamic> getUserTeams() async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] GET /teams');
      final response = await _dio.get(
        "/",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('[TeamApi][ERROR] getUserTeams DioException: ${e.message}');
      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to get teams';
      throw Exception(errorMsg);
    } catch (e) {
      print('[TeamApi][ERROR] getUserTeams: $e');
      rethrow;
    }
  }

  // Get team by ID or slug
  static Future<dynamic> getTeam(String identifier) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] GET /teams/$identifier');
      final response = await _dio.get(
        "/$identifier",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('[TeamApi][ERROR] getTeam DioException: ${e.message}');
      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to get team';
      throw Exception(errorMsg);
    } catch (e) {
      print('[TeamApi][ERROR] getTeam: $e');
      rethrow;
    }
  }

  // Update team
  static Future<dynamic> updateTeam(String teamId, dynamic data) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] PUT /teams/$teamId with data: $data');
      final response = await _dio.put(
        "/$teamId",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('[TeamApi][ERROR] updateTeam DioException: ${e.message}');
      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to update team';
      throw Exception(errorMsg);
    } catch (e) {
      print('[TeamApi][ERROR] updateTeam: $e');
      rethrow;
    }
  }

  // Delete/Archive team
  static Future<void> deleteTeam(String teamId) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] DELETE /teams/$teamId');
      await _dio.delete(
        "/$teamId",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Team deleted');
    } on DioException catch (e) {
      print('[TeamApi][ERROR] deleteTeam DioException: ${e.message}');
      final errorMsg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Failed to delete team';
      throw Exception(errorMsg);
    } catch (e) {
      print('[TeamApi][ERROR] deleteTeam: $e');
      rethrow;
    }
  }

  // Search teams
  static Future<dynamic> searchTeams(String query, {int limit = 10, bool includePublic = false}) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] GET /teams/search?q=$query&limit=$limit&includePublic=$includePublic');
      final response = await _dio.get(
        "/search",
        queryParameters: {
          "q": query,
          "limit": limit,
          "includePublic": includePublic.toString(),
        },
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('[TeamApi][ERROR] searchTeams DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to search teams');
    }
  }

  // Invite member to team
  static Future<void> inviteMember(String teamId, dynamic data) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] POST /teams/$teamId/invite with data: $data');
      await _dio.post(
        "/$teamId/invite",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Member invited');
    } on DioException catch (e) {
      print('[TeamApi][ERROR] inviteMember DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to invite member');
    }
  }

  // Accept team invitation
  static Future<dynamic> acceptInvitation(String token) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] POST /teams/invitations/$token/accept');
      final response = await _dio.post(
        "/invitations/$token/accept",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('[TeamApi][ERROR] acceptInvitation DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to accept invitation');
    }
  }

  // Update member role
  static Future<void> updateMemberRole(String teamId, String memberId, String role) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] PUT /teams/$teamId/members/$memberId/role with role: $role');
      await _dio.put(
        "/$teamId/members/$memberId/role",
        data: {"role": role},
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Member role updated');
    } on DioException catch (e) {
      print('[TeamApi][ERROR] updateMemberRole DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to update member role');
    }
  }

  // Remove member from team
  static Future<void> removeMember(String teamId, String memberId) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] DELETE /teams/$teamId/members/$memberId');
      await _dio.delete(
        "/$teamId/members/$memberId",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Member removed');
    } on DioException catch (e) {
      print('[TeamApi][ERROR] removeMember DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to remove member');
    }
  }

  // Leave team
  static Future<void> leaveTeam(String teamId) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] POST /teams/$teamId/leave');
      await _dio.post(
        "/$teamId/leave",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Left team');
    } on DioException catch (e) {
      print('[TeamApi][ERROR] leaveTeam DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to leave team');
    }
  }

  // Transfer team ownership
  static Future<void> transferOwnership(String teamId, String newOwnerId) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] POST /teams/$teamId/transfer-ownership to $newOwnerId');
      await _dio.post(
        "/$teamId/transfer-ownership",
        data: {"newOwnerId": newOwnerId},
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Ownership transferred');
    } on DioException catch (e) {
      print('[TeamApi][ERROR] transferOwnership DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to transfer ownership');
    }
  }

  // Bulk update member permissions
  static Future<void> bulkUpdatePermissions(String teamId, dynamic updates) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] PUT /teams/$teamId/members/bulk-permissions with updates: $updates');
      await _dio.put(
        "/$teamId/members/bulk-permissions",
        data: {"updates": updates},
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Bulk permissions updated');
    } on DioException catch (e) {
      print('[TeamApi][ERROR] bulkUpdatePermissions DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to bulk update permissions');
    }
  }

  // Get team projects
  static Future<dynamic> getTeamProjects(String teamId, {dynamic query}) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] GET /teams/$teamId/projects with query: $query');
      final response = await _dio.get(
        "/$teamId/projects",
        queryParameters: query,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('[TeamApi][ERROR] getTeamProjects DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to get team projects');
    }
  }

  // Assign project to team members
  static Future<void> assignProject(String teamId, String projectId, dynamic memberIds) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] POST /teams/$teamId/projects/$projectId/assign with memberIds: $memberIds');
      await _dio.post(
        "/$teamId/projects/$projectId/assign",
        data: {"memberIds": memberIds},
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Project assigned');
    } on DioException catch (e) {
      print('[TeamApi][ERROR] assignProject DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to assign project');
    }
  }

  // Get team analytics
  static Future<dynamic> getTeamAnalytics(String teamId, {String period = "30d"}) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] GET /teams/$teamId/analytics?period=$period');
      final response = await _dio.get(
        "/$teamId/analytics",
        queryParameters: {"period": period},
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('[TeamApi][ERROR] getTeamAnalytics DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to get team analytics');
    }
  }

  // Get team activity feed
  static Future<dynamic> getActivityFeed(String teamId, {int limit = 20, int page = 1, String? type}) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] GET /teams/$teamId/activity?limit=$limit&page=$page&type=$type');
      final response = await _dio.get(
        "/$teamId/activity",
        queryParameters: {
          "limit": limit,
          "page": page,
          if (type != null) "type": type,
        },
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('[TeamApi][ERROR] getActivityFeed DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to get activity feed');
    }
  }

  // Update team integrations
  static Future<dynamic> updateIntegrations(String teamId, dynamic integrations) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] PUT /teams/$teamId/integrations with integrations: $integrations');
      final response = await _dio.put(
        "/$teamId/integrations",
        data: {"integrations": integrations},
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('[TeamApi][ERROR] updateIntegrations DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to update integrations');
    }
  }

  // Check user permissions for team
  static Future<dynamic> checkPermissions(String teamId) async {
    try {
      final idToken = await _getToken();
      print('[TeamApi] GET /teams/$teamId/permissions');
      final response = await _dio.get(
        "/$teamId/permissions",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      print('[TeamApi] Response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('[TeamApi][ERROR] checkPermissions DioException: ${e.message}');
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to check permissions');
    }
  }
}
