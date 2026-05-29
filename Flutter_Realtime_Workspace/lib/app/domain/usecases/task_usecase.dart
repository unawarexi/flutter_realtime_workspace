import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/task_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/task_provider.dart';

/// Business logic for the Tasks feature.
///
/// CRUD through [TaskNotifier], Kanban grouping helpers, permission checks,
/// and display label constants. The UI calls these static methods only.
class TaskUseCase {
  TaskUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canCreateTask(WidgetRef ref) =>
      PermissionHelper.canCreate(_level(ref), 'task');

  static bool canEditTask(WidgetRef ref, {bool isOwner = false}) =>
      PermissionHelper.canEdit(_level(ref), 'task', isOwner: isOwner);

  static bool canDeleteTask(WidgetRef ref) =>
      PermissionHelper.canDelete(_level(ref), 'task');

  // ── CRUD ─────────────────────────────────────────────────────────────────

  static Future<TaskModel?> createTask({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final task =
          await ref.read(taskNotifierProvider.notifier).createTask(body);
      if (context.mounted) {
        AppToast.show(
          'Task created',
          type: ToastType.success,
          context: context,
        );
      }
      return task;
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
      return null;
    }
  }

  static Future<TaskModel?> updateTask({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    try {
      final task =
          await ref.read(taskNotifierProvider.notifier).updateTask(id, body);
      if (context.mounted) {
        AppToast.show('Task updated', type: ToastType.success, context: context);
      }
      return task;
    } catch (e) {
      if (context.mounted) {
        AppToast.show(_extractError(e), type: ToastType.error, context: context);
      }
      return null;
    }
  }

  static Future<bool> deleteTask({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      await ref.read(taskNotifierProvider.notifier).deleteTask(id);
      if (context.mounted) {
        AppToast.show('Task deleted', type: ToastType.success, context: context);
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        AppToast.show(_extractError(e), type: ToastType.error, context: context);
      }
      return false;
    }
  }

  static Future<bool> updateStatus({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required String newStatus,
  }) async {
    return await updateTask(
      context: context,
      ref: ref,
      id: id,
      body: {'status': newStatus},
    ) != null;
  }

  static Future<void> addComment({
    required BuildContext context,
    required WidgetRef ref,
    required String taskId,
    required String content,
  }) async {
    try {
      await ref.read(taskRepositoryProvider).addComment(taskId, content);
      if (context.mounted) {
        AppToast.show('Comment added', type: ToastType.success, context: context);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(_extractError(e), type: ToastType.error, context: context);
      }
    }
  }

  // ── Kanban grouping ──────────────────────────────────────────────────────

  /// Groups tasks by status in the canonical Kanban order.
  static Map<String, List<TaskModel>> groupByStatus(List<TaskModel> tasks) {
    final Map<String, List<TaskModel>> result = {};
    for (final s in statusOrder) {
      result[s] = tasks.where((t) => t.status == s).toList();
    }
    return result;
  }

  /// Group by assignee ID (for workload views).
  static Map<String, List<TaskModel>> groupByAssignee(List<TaskModel> tasks) {
    final Map<String, List<TaskModel>> result = {};
    for (final t in tasks) {
      final key = t.assignedTo ?? 'unassigned';
      result.putIfAbsent(key, () => []).add(t);
    }
    return result;
  }

  // ── Filtering ────────────────────────────────────────────────────────────

  static List<TaskModel> searchTasks(List<TaskModel> tasks, String query) {
    if (query.isEmpty) return tasks;
    final q = query.toLowerCase();
    return tasks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            (t.description?.toLowerCase().contains(q) ?? false) ||
            (t.key?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  static List<TaskModel> filterByPriority(
      List<TaskModel> tasks, String priority) =>
      tasks.where((t) => t.priority == priority).toList();

  static List<TaskModel> filterByAssignee(
      List<TaskModel> tasks, String assigneeId) =>
      tasks.where((t) => t.assignedTo == assigneeId).toList();

  // ── Status transition validation ─────────────────────────────────────────

  /// Whether a given status transition is allowed based on role.
  static bool canTransition(WidgetRef ref, String from, String to) {
    final level = _level(ref);
    // Anyone can move to in_progress or done
    if (['in_progress', 'done'].contains(to)) return PermissionHelper.isMember(level);
    // Moving to blocked or cancelled requires manager+
    if (['blocked', 'cancelled'].contains(to)) return PermissionHelper.isManager(level);
    // Moving back to backlog requires employee+
    if (to == 'backlog') return PermissionHelper.isEmployee(level);
    return PermissionHelper.isEmployee(level);
  }

  // ── Display helpers ──────────────────────────────────────────────────────

  static String statusLabel(String status) {
    switch (status) {
      case 'backlog': return 'Backlog';
      case 'todo': return 'To Do';
      case 'in_progress': return 'In Progress';
      case 'in_review': return 'In Review';
      case 'done': return 'Done';
      case 'blocked': return 'Blocked';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  static String priorityLabel(String priority) {
    switch (priority) {
      case 'critical': return 'Critical';
      case 'high': return 'High';
      case 'medium': return 'Medium';
      case 'low': return 'Low';
      default: return priority;
    }
  }

  static const List<String> statusOrder = [
    'backlog',
    'todo',
    'in_progress',
    'in_review',
    'done',
    'blocked',
    'cancelled',
  ];

  static const List<String> priorityOrder = [
    'critical',
    'high',
    'medium',
    'low',
  ];

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
