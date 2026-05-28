import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/workspace_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';

/// Business logic for the Workspace feature.
///
/// CRUD through [ActiveWorkspaceNotifier], member management, switching.
class WorkspaceUseCase {
  WorkspaceUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canCreateWorkspace(WidgetRef ref) =>
      PermissionHelper.isManager(_level(ref));

  static bool canEditWorkspace(WidgetRef ref) =>
      PermissionHelper.canEdit(_level(ref), 'project');

  static bool canManageMembers(WidgetRef ref) =>
      PermissionHelper.canManageMembers(_level(ref));

  // ── CRUD ─────────────────────────────────────────────────────────────────

  static Future<bool> createWorkspace({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      await ref.read(activeWorkspaceProvider.notifier).createWorkspace(body);
      if (context.mounted) {
        AppToast.show(
          'Workspace created',
          type: ToastType.success,
          context: context,
        );
      }
      ref.invalidate(workspacesProvider);
      return true;
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
      return false;
    }
  }

  // ── Switch workspace ─────────────────────────────────────────────────────

  static void switchWorkspace(WidgetRef ref, WorkspaceModel workspace) {
    ref.read(activeWorkspaceProvider.notifier).setWorkspace(workspace);
  }

  static WorkspaceModel? activeWorkspace(WidgetRef ref) =>
      ref.watch(activeWorkspaceProvider);

  // ── Refresh ──────────────────────────────────────────────────────────────

  static Future<void> refreshWorkspace({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      await ref.read(activeWorkspaceProvider.notifier).refreshWorkspace(id);
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
    }
  }

  // ── Filtering ────────────────────────────────────────────────────────────

  static List<WorkspaceModel> searchWorkspaces(
      List<WorkspaceModel> workspaces, String query) {
    if (query.isEmpty) return workspaces;
    final q = query.toLowerCase();
    return workspaces
        .where((w) =>
            w.name.toLowerCase().contains(q) ||
            (w.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
