import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/network/api_exception.dart';

class ProjectRepository {
	ProjectRepository({ApiClient? apiClient})
			: _apiClient = apiClient ?? ApiClient.instance;

	final ApiClient _apiClient;

	Future<ApiResult<List<Map<String, dynamic>>>> fetchProjects() {
		return _apiClient.get<List<Map<String, dynamic>>>(
			ApiEndpoints.projects,
			fromJson: (json) {
				if (json is List) {
					return json
							.whereType<Map>()
							.map((item) => Map<String, dynamic>.from(item))
							.toList();
				}
				return const <Map<String, dynamic>>[];
			},
		);
	}

	Future<ApiResult<Map<String, dynamic>>> createProject(
		Map<String, dynamic> payload,
	) {
		return _apiClient.post<Map<String, dynamic>>(
			ApiEndpoints.createProject,
			data: payload,
			fromJson: (json) => Map<String, dynamic>.from(json as Map),
		);
	}

	Future<ApiResult<Map<String, dynamic>>> updateProject(
		String projectId,
		Map<String, dynamic> payload,
	) {
		return _apiClient.put<Map<String, dynamic>>(
			ApiEndpoints.updateProject(projectId),
			data: payload,
			fromJson: (json) => Map<String, dynamic>.from(json as Map),
		);
	}

	Future<ApiResult<dynamic>> deleteProject(String projectId) {
		return _apiClient.delete<dynamic>(ApiEndpoints.deleteProject(projectId));
	}
}
