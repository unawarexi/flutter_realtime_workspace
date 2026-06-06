import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/task_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((_) {
  return TaskRepository();
});

/// Single task by ID.
final taskDetailProvider =
    FutureProvider.autoDispose.family<TaskModel, String>((ref, id) {
  return ref.watch(taskRepositoryProvider).getTask(id);
});

/// Filter key record — uses structural equality so Riverpod won't fire a new
/// provider on every widget rebuild (unlike Map which uses reference equality).
typedef TaskFilterKey = ({String? workspaceId, String? projectId, String? assigneeId, String? status});

/// Tasks for a project.
final tasksProvider = FutureProvider.family<List<TaskModel>, TaskFilterKey>((ref, filters) {
  ref.keepAlive();
  return ref.read(taskRepositoryProvider).getTasks(
        projectId: filters.projectId,
        workspaceId: filters.workspaceId,
        assigneeId: filters.assigneeId,
        status: filters.status,
      );
});

/// Tasks scoped to a single workspace — stable String? key avoids Map
/// reference-equality issue that caused a new provider (and API call)
/// to be created on every widget rebuild.
final workspaceTasksProvider =
    FutureProvider.family<List<TaskModel>, String?>((ref, workspaceId) {
  ref.keepAlive();
  return ref.read(taskRepositoryProvider).getTasks(workspaceId: workspaceId);
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
