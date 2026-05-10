import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/network/api_exception.dart';

class TeamRepository {
	TeamRepository({ApiClient? apiClient})
			: _apiClient = apiClient ?? ApiClient.instance;

	final ApiClient _apiClient;

	Future<ApiResult<List<Map<String, dynamic>>>> fetchTeams() {
		return _apiClient.get<List<Map<String, dynamic>>>(
			ApiEndpoints.teams,
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

	Future<ApiResult<Map<String, dynamic>>> createTeam(
		Map<String, dynamic> payload,
	) {
		return _apiClient.post<Map<String, dynamic>>(
			ApiEndpoints.createTeam,
			data: payload,
			fromJson: (json) => Map<String, dynamic>.from(json as Map),
		);
	}

	Future<ApiResult<Map<String, dynamic>>> addTeamMember({
		required String teamId,
		required Map<String, dynamic> payload,
	}) {
		return _apiClient.post<Map<String, dynamic>>(
			ApiEndpoints.addTeamMember(teamId),
			data: payload,
			fromJson: (json) => Map<String, dynamic>.from(json as Map),
		);
	}

	Future<ApiResult<dynamic>> removeTeamMember({
		required String teamId,
		required String userId,
	}) {
		return _apiClient.delete<dynamic>(
			ApiEndpoints.removeTeamMember(teamId, userId),
		);
	}
}
