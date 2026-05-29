import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/analytics_provider.dart';

/// Business logic for the Dashboard feature.
///
/// Orchestrates analytics, workspace info, recent activity, and quick stats.
/// All data flows through analytics provider. Filtering and grouping logic
/// keeps the UI clean and stateless.
class DashboardUseCase {
  DashboardUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canViewDashboard(WidgetRef ref) {
    final current = ref.read(currentUserProvider).valueOrNull;
    return current != null;
  }

  static bool canViewAdvancedMetrics(WidgetRef ref) =>
      PermissionHelper.canAccessAnalytics(_level(ref));

  // ── Analytics Data ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getDashboardData({
    required BuildContext context,
    required WidgetRef ref,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // analyticsReportProvider is FutureProvider.family — requires filters
      final data = await ref.read(
        analyticsReportProvider(filters ?? {'period': '7d'}).future,
      );
      return data;
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

  // ── Helper methods ───────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
