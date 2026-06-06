import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/workspace_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/workspace_repository.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((_) {
  return WorkspaceRepository();
});

/// All workspaces for the current user.
final workspacesProvider =
    FutureProvider<List<WorkspaceModel>>((ref) {
  ref.keepAlive();
  return ref.read(workspaceRepositoryProvider).getWorkspaces();
});

/// Active workspace state.
final activeWorkspaceProvider =
    StateNotifierProvider<ActiveWorkspaceNotifier, WorkspaceModel?>(
        (ref) => ActiveWorkspaceNotifier(ref));

class ActiveWorkspaceNotifier extends StateNotifier<WorkspaceModel?> {
  final Ref _ref;
  ActiveWorkspaceNotifier(this._ref) : super(null);

  void setWorkspace(WorkspaceModel workspace) => state = workspace;

  Future<void> refreshWorkspace(String id) async {
    final ws = await _ref.read(workspaceRepositoryProvider).getWorkspace(id);
    state = ws;
  }

  Future<void> createWorkspace(Map<String, dynamic> body) async {
    final ws = await _ref.read(workspaceRepositoryProvider).createWorkspace(body);
    state = ws;
  }
}

/// Workspace members.
final workspaceMembersProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, workspaceId) {
  return ref.watch(workspaceRepositoryProvider).getWorkspaceMembers(workspaceId);
});
