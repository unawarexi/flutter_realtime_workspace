import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/integration_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/integration_provider.dart';

/// Business logic for the Integrations feature.
///
/// CRUD through [IntegrationNotifier], install/uninstall/test actions.
class IntegrationUseCase {
  IntegrationUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canInstallIntegration(WidgetRef ref) =>
      PermissionHelper.canCreate(_level(ref), 'integration');

  static bool canManageIntegrations(WidgetRef ref) =>
      PermissionHelper.isAdmin(_level(ref));

  // ── Install / Uninstall ──────────────────────────────────────────────────

  static Future<IntegrationModel?> install({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final integration = await ref
          .read(integrationNotifierProvider.notifier)
          .installIntegration(body);
      if (context.mounted) {
        AppToast.show(
          'Integration installed',
          type: ToastType.success,
          context: context,
        );
      }
      return integration;
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

  static Future<bool> uninstall({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      await ref.read(integrationNotifierProvider.notifier).uninstall(id);
      if (context.mounted) {
        AppToast.show(
          'Integration removed',
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

  static Future<Map<String, dynamic>?> testIntegration({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      final result =
          await ref.read(integrationNotifierProvider.notifier).test(id);
      if (context.mounted) {
        AppToast.show(
          'Integration test passed',
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

  static List<IntegrationModel> filterByType(
      List<IntegrationModel> integrations, String type) =>
      integrations.where((i) => i.type == type).toList();

  static List<IntegrationModel> filterActive(
      List<IntegrationModel> integrations) =>
      integrations.where((i) => i.enabled).toList();

  static List<IntegrationModel> searchIntegrations(
      List<IntegrationModel> integrations, String query) {
    if (query.isEmpty) return integrations;
    final q = query.toLowerCase();
    return integrations
        .where((i) =>
            i.name.toLowerCase().contains(q))
        .toList();
  }

  // ── Display helpers ──────────────────────────────────────────────────────

  static String typeLabel(String type) {
    switch (type) {
      case 'ci_cd': return 'CI/CD';
      case 'communication': return 'Communication';
      case 'monitoring': return 'Monitoring';
      case 'storage': return 'Storage';
      case 'analytics': return 'Analytics';
      case 'custom': return 'Custom';
      default: return type;
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
