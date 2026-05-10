import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/team_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/team_repository.dart';

final teamRepositoryProvider = Provider<TeamRepository>((_) {
  return TeamRepository();
});

final teamsProvider =
    FutureProvider.autoDispose.family<List<TeamModel>, String>(
        (ref, workspaceId) {
  return ref.watch(teamRepositoryProvider).getTeams(workspaceId);
});

final teamDetailProvider =
    FutureProvider.autoDispose.family<TeamModel, String>((ref, id) {
  return ref.watch(teamRepositoryProvider).getTeam(id);
});

final teamNotifierProvider =
    StateNotifierProvider<TeamNotifier, AsyncValue<TeamModel?>>(
        (ref) => TeamNotifier(ref));

class TeamNotifier extends StateNotifier<AsyncValue<TeamModel?>> {
  final Ref _ref;
  TeamNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<TeamModel> createTeam(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final team = await _ref.read(teamRepositoryProvider).createTeam(body);
      state = AsyncValue.data(team);
      return team;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addMember(String teamId, String userId) async {
    await _ref.read(teamRepositoryProvider).addMember(teamId, userId);
  }

  Future<void> removeMember(String teamId, String userId) async {
    await _ref.read(teamRepositoryProvider).removeMember(teamId, userId);
  }
}
