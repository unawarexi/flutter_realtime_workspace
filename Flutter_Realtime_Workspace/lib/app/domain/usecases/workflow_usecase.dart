import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/workflow_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/workflow_provider.dart';

/// Business logic for the Workflows feature.
///
/// CRUD through [WorkflowNotifier], toggle/test actions, and display helpers.
class WorkflowUseCase {
  WorkflowUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canCreateWorkflow(WidgetRef ref) =>
      PermissionHelper.canCreate(_level(ref), 'workflow');

  static bool canEditWorkflow(WidgetRef ref) =>
      PermissionHelper.canEdit(_level(ref), 'workflow');

  static bool canDeleteWorkflow(WidgetRef ref) =>
      PermissionHelper.canDelete(_level(ref), 'workflow');

  // ── CRUD ─────────────────────────────────────────────────────────────────

  static Future<WorkflowModel?> createWorkflow({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final wf = await ref
          .read(workflowNotifierProvider.notifier)
          .createWorkflow(body);
      if (context.mounted) {
        AppToast.show(
          'Workflow created',
          type: ToastType.success,
          context: context,
        );
      }
      return wf;
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

  // ── Toggle / Test ────────────────────────────────────────────────────────

  static Future<void> toggleWorkflow({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      await ref.read(workflowNotifierProvider.notifier).toggleWorkflow(id);
      if (context.mounted) {
        AppToast.show(
          'Workflow toggled',
          type: ToastType.success,
          context: context,
        );
      }
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

  static Future<Map<String, dynamic>?> testWorkflow({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      final result =
          await ref.read(workflowNotifierProvider.notifier).testWorkflow(id);
      if (context.mounted) {
        AppToast.show(
          'Workflow test completed',
          type: ToastType.success,
          context: context,
        );
      }
      return result;
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

  // ── Filtering ────────────────────────────────────────────────────────────

  static List<WorkflowModel> filterActive(List<WorkflowModel> workflows) =>
      workflows.where((w) => w.enabled).toList();

  static List<WorkflowModel> searchWorkflows(
      List<WorkflowModel> workflows, String query) {
    if (query.isEmpty) return workflows;
    final q = query.toLowerCase();
    return workflows
        .where((w) =>
            w.name.toLowerCase().contains(q) ||
            (w.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ── Display helpers ──────────────────────────────────────────────────────

  static String triggerLabel(String trigger) {
    switch (trigger) {
      case 'manual': return 'Manual';
      case 'schedule': return 'Scheduled';
      case 'webhook': return 'Webhook';
      case 'event': return 'Event-based';
      default: return trigger;
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
