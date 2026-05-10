import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/task_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((_) {
  return TaskRepository();
});

/// Tasks for a project.
final tasksProvider = FutureProvider.autoDispose
    .family<List<TaskModel>, Map<String, String?>>((ref, filters) {
  return ref.watch(taskRepositoryProvider).getTasks(
        projectId: filters['projectId'],
        workspaceId: filters['workspaceId'],
        assigneeId: filters['assigneeId'],
        status: filters['status'],
      );
});

/// My tasks (assigned to current user).
final myTasksProvider =
    FutureProvider.autoDispose.family<List<TaskModel>, String>(
        (ref, userId) {
  return ref.watch(taskRepositoryProvider).getTasks(assigneeId: userId);
});

/// Task crud notifier.
final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<TaskModel?>>(
        (ref) => TaskNotifier(ref));

class TaskNotifier extends StateNotifier<AsyncValue<TaskModel?>> {
  final Ref _ref;
  TaskNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<TaskModel> createTask(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final task = await _ref.read(taskRepositoryProvider).createTask(body);
      state = AsyncValue.data(task);
      return task;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<TaskModel> updateTask(String id, Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final task = await _ref.read(taskRepositoryProvider).updateTask(id, body);
      state = AsyncValue.data(task);
      return task;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    await _ref.read(taskRepositoryProvider).deleteTask(id);
  }
}
