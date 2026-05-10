import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_realtime_workspace/core/config/environment.dart';
import 'package:flutter_realtime_workspace/core/network/auto_retry.dart'; // <-- import auto_retry

class ProjectApi {
  // Use the retry-enabled Dio instance from NetworkModule
   static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${Environment.baseUrl}projects',
      connectTimeout: const Duration(minutes: 2), // ⏱️ 2 minutes
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(minutes: 2),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );
  // static final Dio _dio = NetworkModule.getDioWithBaseUrl(
  //   '${Environment.baseUrl}projects', // Environment.baseUrl must end with /
  // );

  static Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not authenticated");

    try {
      final token = await user.getIdToken(true);
      if (token!.isEmpty) throw Exception("Empty ID token received");
      print('[ProjectApi] Firebase ID token obtained for user: ${user.email}');
      return token;
    } catch (e) {
      print('[ProjectApi][ERROR] Failed to get Firebase token: $e');
      throw Exception("Failed to retrieve authentication token: $e");
    }
  }

  // Extract error message from DioException
  static String _extractErrorMessage(DioException e) {
    try {
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          return data['message']?.toString() ??
              data['error']?.toString() ??
              data['details']?.toString() ??
              'Server error occurred';
        }
        if (data is String) {
          return data;
        }
      }
      return e.message ?? 'Network error occurred';
    } catch (_) {
      return 'Unknown error occurred';
    }
  }

  // Create project (with optional attachments)
  static Future<dynamic> createProject(
    Map<String, dynamic> data, {
    List<String>? filePaths,
  }) async {
    try {
      final idToken = await _getToken();
      print('[ProjectApi] Creating project with data: $data');

      Response response;

      if (filePaths != null && filePaths.isNotEmpty) {
        // Create multipart form data
        final formData = FormData();

        // Add all text fields
        data.forEach((key, value) {
          if (value != null) {
            formData.fields.add(MapEntry(key, value.toString()));
          }
        });

        // Add file attachments
        for (final path in filePaths) {
          try {
            final file = await MultipartFile.fromFile(path,
                filename: path.split('/').last);
            formData.files.add(MapEntry('attachments', file));
          } catch (e) {
            print('[ProjectApi][WARN] Failed to add file $path: $e');
          }
        }

        print('[ProjectApi] POST / (multipart) with ${filePaths.length} files');
        response = await _dio.post(
          "/",
          data: formData,
          options: Options(
            headers: {
              "Authorization": "Bearer $idToken",
              "Content-Type": "multipart/form-data",
            },
          ),
        );
      } else {
        // Send as JSON
        print('[ProjectApi] POST / (json)');
        response = await _dio.post(
          "/",
          data: data,
          options: Options(
            headers: {
              "Authorization": "Bearer $idToken",
              "Content-Type": "application/json",
            },
          ),
        );
      }

      print('[ProjectApi] Response status: ${response.statusCode}');
      print('[ProjectApi] Raw response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('[ProjectApi][ERROR] createProject DioException: ${e.type}');
      print('[ProjectApi][ERROR] Status code: ${e.response?.statusCode}');
      print('[ProjectApi][ERROR] Response data: ${e.response?.data}');

      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    } catch (e) {
      print('[ProjectApi][ERROR] createProject unexpected error: $e');
      throw Exception('Failed to create project: $e');
    }
  }

  // Get all projects (optionally by teamId)
  static Future<dynamic> getProjects({String? teamId}) async {
    try {
      final idToken = await _getToken();
      final queryParams = <String, dynamic>{};

      if (teamId != null && teamId.isNotEmpty) {
        queryParams['teamId'] = teamId;
      }

      print('[ProjectApi] GET / with params: $queryParams');

      final response = await _dio.get(
        "/",
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );

      print('[ProjectApi] Response status: ${response.statusCode}');
      print('[ProjectApi] Raw response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('[ProjectApi][ERROR] getProjects DioException: ${e.type}');
      print('[ProjectApi][ERROR] Response data: ${e.response?.data}');

      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    } catch (e) {
      print('[ProjectApi][ERROR] getProjects unexpected error: $e');
      throw Exception('Failed to get projects: $e');
    }
  }

  // Get project by id
  static Future<dynamic> getProjectById(String id) async {
    if (id.isEmpty) {
      throw Exception('Project ID cannot be empty');
    }

    try {
      final idToken = await _getToken();
      print('[ProjectApi] GET /$id');

      final response = await _dio.get(
        "/$id",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );

      print('[ProjectApi] Response status: ${response.statusCode}');
      print('[ProjectApi] Raw response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('[ProjectApi][ERROR] getProjectById DioException: ${e.type}');
      print('[ProjectApi][ERROR] Response data: ${e.response?.data}');

      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    } catch (e) {
      print('[ProjectApi][ERROR] getProjectById unexpected error: $e');
      throw Exception('Failed to get project: $e');
    }
  }

  // Generate new project key
  static Future<dynamic> getNewProjectKey() async {
    try {
      final idToken = await _getToken();
      print('[ProjectApi] GET /generate/project-key');

      final response = await _dio.get(
        "/generate/project-key",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );

      print('[ProjectApi] Response status: ${response.statusCode}');
      print('[ProjectApi] Raw response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('[ProjectApi][ERROR] getNewProjectKey DioException: ${e.type}');
      print('[ProjectApi][ERROR] Response data: ${e.response?.data}');

      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    } catch (e) {
      print('[ProjectApi][ERROR] getNewProjectKey unexpected error: $e');
      throw Exception('Failed to generate project key: $e');
    }
  }

  // Generate new team id
  static Future<dynamic> getNewTeamId() async {
    try {
      final idToken = await _getToken();
      print('[ProjectApi] GET /generate/team-id');

      final response = await _dio.get(
        "/generate/team-id",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );

      print('[ProjectApi] Response status: ${response.statusCode}');
      print('[ProjectApi] Raw response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('[ProjectApi][ERROR] getNewTeamId DioException: ${e.type}');
      print('[ProjectApi][ERROR] Response data: ${e.response?.data}');

      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    } catch (e) {
      print('[ProjectApi][ERROR] getNewTeamId unexpected error: $e');
      throw Exception('Failed to generate team ID: $e');
    }
  }

  // Update a project
  static Future<dynamic> updateProject(String id, Map<String, dynamic> data) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.put(
        "/$id",
        data: data,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Delete a project
  static Future<dynamic> deleteProject(String id) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.delete(
        "/$id",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Toggle project star status
  static Future<dynamic> toggleProjectStar(String id) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.patch(
        "/$id/star",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Toggle project archive status
  static Future<dynamic> toggleProjectArchive(String id) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.patch(
        "/$id/archive",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Update project progress
  static Future<dynamic> updateProjectProgress(String id, double progress) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.patch(
        "/$id/progress",
        data: {"progress": progress},
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Duplicate a project
  static Future<dynamic> duplicateProject(String id, {String? name, bool includeAttachments = false, String? key}) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.post(
        "/$id/duplicate",
        data: {
          if (name != null) "name": name,
          "includeAttachments": includeAttachments,
          if (key != null) "key": key,
        },
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Update project collaborators
  static Future<dynamic> updateProjectCollaborators(String id, List<String> collaboratorIds, {String action = "add"}) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.patch(
        "/$id/collaborators",
        data: {"collaboratorIds": collaboratorIds, "action": action},
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Upload attachment to project
  static Future<dynamic> uploadAttachment(String id, String filePath) async {
    try {
      final idToken = await _getToken();
      final formData = FormData.fromMap({
        "attachment": await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });
      final response = await _dio.post(
        "/$id/attachments",
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $idToken",
            "Content-Type": "multipart/form-data",
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Get project attachments
  static Future<dynamic> getProjectAttachments(String id, {String? type, int page = 1, int limit = 10}) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.get(
        "/$id/attachments",
        queryParameters: {
          if (type != null) "type": type,
          "page": page,
          "limit": limit,
        },
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Delete a specific attachment
  static Future<dynamic> deleteAttachment(String id, String attachmentId) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.delete(
        "/$id/attachments/$attachmentId",
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Add timeline event
  static Future<dynamic> addTimelineEvent(String id, String title, {String? description, String? type}) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.post(
        "/$id/timeline",
        data: {
          "title": title,
          if (description != null) "description": description,
          if (type != null) "type": type,
        },
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Get project timeline
  static Future<dynamic> getProjectTimeline(String id, {int page = 1, int limit = 20, String? type}) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.get(
        "/$id/timeline",
        queryParameters: {
          "page": page,
          "limit": limit,
          if (type != null) "type": type,
        },
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Get project statistics
  static Future<dynamic> getProjectStats({String? teamId}) async {
    try {
      final idToken = await _getToken();
      final response = await _dio.get(
        "/stats",
        queryParameters: teamId != null ? {"teamId": teamId} : null,
        options: Options(headers: {"Authorization": "Bearer $idToken"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }
}
        