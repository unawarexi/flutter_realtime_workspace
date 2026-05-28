import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/project_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/project_provider.dart';

/// Business logic for the Project feature.
///
/// All CRUD goes through provider notifiers; filtering/grouping helpers
/// keep the UI free of logic. Permission checks use [PermissionHelper].
class ProjectUseCase {
  ProjectUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canCreateProject(WidgetRef ref) =>
      PermissionHelper.canCreate(_level(ref), 'project');

  static bool canEditProject(WidgetRef ref, {bool isOwner = false}) =>
      PermissionHelper.canEdit(_level(ref), 'project', isOwner: isOwner);

  static bool canDeleteProject(WidgetRef ref) =>
      PermissionHelper.canDelete(_level(ref), 'project');

  static bool canManageMembers(WidgetRef ref) =>
      PermissionHelper.canManageMembers(_level(ref));

  // ── CRUD ─────────────────────────────────────────────────────────────────

  static Future<ProjectModel?> createProject({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final project =
          await ref.read(projectFormProvider.notifier).createProject(body);
      if (context.mounted) {
        AppToast.show(
          'Project created successfully',
          type: ToastType.success,
          context: context,
        );
      }
      return project;
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

  static Future<ProjectModel?> updateProject({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    try {
      final project =
          await ref.read(projectFormProvider.notifier).updateProject(id, body);
      if (context.mounted) {
        AppToast.show(
          'Project updated',
          type: ToastType.success,
          context: context,
        );
      }
      return project;
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

  static Future<bool> deleteProject({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      await ref.read(projectRepositoryProvider).deleteProject(id);
      if (context.mounted) {
        AppToast.show(
          'Project deleted',
          type: ToastType.success,
          context: context,
        );
      }
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

  static Future<void> starProject({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      await ref.read(projectRepositoryProvider).starProject(id);
      if (context.mounted) {
        AppToast.show('Starred', type: ToastType.success, context: context);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(_extractError(e), type: ToastType.error, context: context);
      }
    }
  }

  static Future<void> archiveProject({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      await ref.read(projectRepositoryProvider).archiveProject(id);
      if (context.mounted) {
        AppToast.show('Archived', type: ToastType.success, context: context);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(_extractError(e), type: ToastType.error, context: context);
      }
    }
  }

  static Future<String?> generateKey(WidgetRef ref) async {
    try {
      return await ref.read(projectFormProvider.notifier).fetchNewProjectKey();
    } catch (_) {
      return null;
    }
  }

  // ── Filtering ────────────────────────────────────────────────────────────

  static List<ProjectModel> filterByStatus(
      List<ProjectModel> projects, String status) {
    if (status == 'All') return projects;
    return projects.where((p) => p.status == status.toLowerCase()).toList();
  }

  static List<ProjectModel> filterStarred(List<ProjectModel> projects) =>
      projects.where((p) => p.starred).toList();

  static List<ProjectModel> filterArchived(List<ProjectModel> projects) =>
      projects.where((p) => p.status == 'archived').toList();

  static List<ProjectModel> filterRecent(List<ProjectModel> projects) {
    final sorted = List<ProjectModel>.from(projects)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(10).toList();
  }

  static List<ProjectModel> searchProjects(
      List<ProjectModel> projects, String query) {
    if (query.isEmpty) return projects;
    final q = query.toLowerCase();
    return projects
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.description?.toLowerCase().contains(q) ?? false) ||
            (p.key?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ── Display helpers ──────────────────────────────────────────────────────

  static String statusLabel(String status) {
    switch (status) {
      case 'planning': return 'Planning';
      case 'active': return 'Active';
      case 'on_hold': return 'On Hold';
      case 'completed': return 'Completed';
      case 'archived': return 'Archived';
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

  static String typeLabel(String type) {
    switch (type) {
      case 'software': return 'Software';
      case 'marketing': return 'Marketing';
      case 'design': return 'Design';
      case 'research': return 'Research';
      case 'operations': return 'Operations';
      case 'other': return 'Other';
      default: return type;
    }
  }

  static const List<String> statusOrder = [
    'planning',
    'active',
    'on_hold',
    'completed',
    'archived',
    'cancelled',
  ];

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
