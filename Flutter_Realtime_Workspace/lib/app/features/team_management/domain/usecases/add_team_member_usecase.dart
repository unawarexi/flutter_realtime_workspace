import 'package:flutter_realtime_workspace/app/features/team_management/data/team_repository.dart';
import 'package:flutter_realtime_workspace/core/network/api_exception.dart';

class AddTeamMemberUseCase {
	AddTeamMemberUseCase({TeamRepository? repository})
			: _repository = repository ?? TeamRepository();

	final TeamRepository _repository;

	Future<ApiResult<Map<String, dynamic>>> call({
		required String teamId,
		required String email,
		String? role,
	}) {
		return _repository.addTeamMember(
			teamId: teamId,
			payload: {
				'email': email,
				if (role != null && role.isNotEmpty) 'role': role,
			},
		);
	}
}
