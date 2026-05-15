import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/project_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((_) {
  return ProjectRepository();
});

/// All projects for a workspace.
final projectsProvider = FutureProvider.autoDispose
    .family<List<ProjectModel>, String?>((ref, workspaceId) {
  return ref
      .watch(projectRepositoryProvider)
      .getProjects(workspaceId: workspaceId);
});

/// Single project detail.
final projectDetailProvider =
    FutureProvider.autoDispose.family<ProjectModel, String>((ref, id) {
  return ref.watch(projectRepositoryProvider).getProject(id);
});

/// Create/update project state.
final projectFormProvider =
    StateNotifierProvider<ProjectFormNotifier, AsyncValue<ProjectModel?>>(
        (ref) => ProjectFormNotifier(ref));

class ProjectFormNotifier extends StateNotifier<AsyncValue<ProjectModel?>> {
  final Ref _ref;
  ProjectFormNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<ProjectModel> createProject(Map<String, dynamic> body,
      {List<String>? filePaths}) async {
    state = const AsyncValue.loading();
    try {
      final project =
          await _ref.read(projectRepositoryProvider).createProject(body);
      state = AsyncValue.data(project);
      return project;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<String> fetchNewProjectKey() async {
    return await _ref.read(projectRepositoryProvider).generateKey();
  }

  Future<ProjectModel> updateProject(
      String id, Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final project =
          await _ref.read(projectRepositoryProvider).updateProject(id, body);
      state = AsyncValue.data(project);
      return project;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
