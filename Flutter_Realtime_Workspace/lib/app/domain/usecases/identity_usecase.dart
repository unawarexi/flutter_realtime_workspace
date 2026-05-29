import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/role_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/role_provider.dart';

/// Business logic for the Identity feature.
///
/// Manages roles, policies, and user permissions through role/policy providers.
/// All CRUD goes through provider notifiers; filtering/permission checks keep the UI free of logic.
class IdentityUseCase {
  IdentityUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canCreateRole(WidgetRef ref) =>
      PermissionHelper.canManageMembers(_level(ref));

  static bool canEditRole(WidgetRef ref) =>
      PermissionHelper.canManageMembers(_level(ref));

  static bool canDeleteRole(WidgetRef ref) =>
      PermissionHelper.canManageMembers(_level(ref));

  // ── Roles ────────────────────────────────────────────────────────────────

  static Future<RoleModel?> createRole({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final role = await ref.read(roleNotifierProvider.notifier).createRole(body);
      if (context.mounted) {
        AppToast.show(
          'Role created successfully',
          type: ToastType.success,
          context: context,
        );
      }
      return role;
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

  static Future<RoleModel?> updateRole({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    try {
      final role = await ref.read(roleNotifierProvider.notifier).updateRole(id, body);
      if (context.mounted) {
        AppToast.show(
          'Role updated',
          type: ToastType.success,
          context: context,
        );
      }
      return role;
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

  static Future<bool> deleteRole({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      await ref.read(roleNotifierProvider.notifier).deleteRole(id);
      if (context.mounted) {
        AppToast.show(
          'Role deleted',
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

  // ── Policies ─────────────────────────────────────────────────────────────

  static Future<PolicyModel?> createPolicy({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final policy =
          await ref.read(policyNotifierProvider.notifier).createPolicy(body);
      if (context.mounted) {
        AppToast.show(
          'Policy created',
          type: ToastType.success,
          context: context,
        );
      }
      return policy;
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

  static Future<PolicyModel?> updatePolicy({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    try {
      final policy =
          await ref.read(policyNotifierProvider.notifier).updatePolicy(id, body);
      if (context.mounted) {
        AppToast.show(
          'Policy updated',
          type: ToastType.success,
          context: context,
        );
      }
      return policy;
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

  static List<RoleModel> filterSystemRoles(List<RoleModel> roles) =>
      roles.where((r) => r.isSystem).toList();

  static List<RoleModel> filterCustomRoles(List<RoleModel> roles) =>
      roles.where((r) => !r.isSystem).toList();

  static List<RoleModel> sortByHierarchy(List<RoleModel> roles) {
    final sorted = List<RoleModel>.from(roles)
      ..sort((a, b) => b.hierarchy.compareTo(a.hierarchy));
    return sorted;
  }

  static List<RoleModel> searchRoles(List<RoleModel> roles, String query) {
    if (query.isEmpty) return roles;
    final q = query.toLowerCase();
    return roles
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            (r.description?.toLowerCase().contains(q) ?? false) ||
            (r.slug?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
