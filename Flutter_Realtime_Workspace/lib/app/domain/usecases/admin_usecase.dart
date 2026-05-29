import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/admin_provider.dart';

/// Business logic for the Admin feature.
///
/// Strict RBAC gating (admin+ / super_admin). Tenant management,
/// impersonation, and stats through [adminActionsProvider].
class AdminUseCase {
  AdminUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canAccessAdmin(WidgetRef ref) =>
      PermissionHelper.canAccessAdmin(_level(ref));

  static bool canImpersonate(WidgetRef ref) =>
      PermissionHelper.canImpersonate(_level(ref));

  static bool isSuperAdmin(WidgetRef ref) =>
      PermissionHelper.isSuperAdmin(_level(ref));

  // ── Tenant management ────────────────────────────────────────────────────

  static Future<bool> updateTenantStatus({
    required BuildContext context,
    required WidgetRef ref,
    required String tenantId,
    required String status,
  }) async {
    try {
      await ref
          .read(adminActionsProvider.notifier)
          .updateTenantStatus(tenantId, status);
      if (context.mounted) {
        AppToast.show(
          'Tenant ${status == 'active' ? 'activated' : 'suspended'}',
          type: ToastType.success,
          context: context,
        );
      }
      // Refresh tenant list
      ref.invalidate(adminTenantsProvider);
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

  // ── Impersonation ────────────────────────────────────────────────────────

  static Future<bool> impersonate({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
  }) async {
    try {
      await ref.read(adminActionsProvider.notifier).impersonate(userId);
      if (context.mounted) {
        AppToast.show(
          'Now impersonating user',
          type: ToastType.warning,
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

  // ── Data refresh ─────────────────────────────────────────────────────────

  static void refreshStats(WidgetRef ref) =>
      ref.invalidate(adminStatsProvider);

  static void refreshTenants(WidgetRef ref) =>
      ref.invalidate(adminTenantsProvider);

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
