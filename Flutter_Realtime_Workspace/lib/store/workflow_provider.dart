import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/workflow_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/workflow_repository.dart';

final workflowRepositoryProvider = Provider<WorkflowRepository>((_) {
  return WorkflowRepository();
});

final workflowsProvider =
    FutureProvider.autoDispose.family<List<WorkflowModel>, String>(
        (ref, workspaceId) {
  return ref.watch(workflowRepositoryProvider).getWorkflows(workspaceId);
});

final workflowDetailProvider =
    FutureProvider.autoDispose.family<WorkflowModel, String>((ref, id) {
  return ref.watch(workflowRepositoryProvider).getWorkflow(id);
});

final workflowNotifierProvider =
    StateNotifierProvider<WorkflowNotifier, AsyncValue<WorkflowModel?>>(
        (ref) => WorkflowNotifier(ref));

class WorkflowNotifier extends StateNotifier<AsyncValue<WorkflowModel?>> {
  final Ref _ref;
  WorkflowNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<WorkflowModel> createWorkflow(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final wf =
          await _ref.read(workflowRepositoryProvider).createWorkflow(body);
      state = AsyncValue.data(wf);
      return wf;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggleWorkflow(String id) async {
    await _ref.read(workflowRepositoryProvider).toggleWorkflow(id);
  }

  Future<Map<String, dynamic>> testWorkflow(String id) async {
    return _ref.read(workflowRepositoryProvider).testWorkflow(id);
  }
}
