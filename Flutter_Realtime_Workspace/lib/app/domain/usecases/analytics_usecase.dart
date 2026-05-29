import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/analytics_provider.dart';

/// Business logic for the Analytics feature.
///
/// RBAC gating for dashboard/report access. Data fetching through
/// [analyticsRepositoryProvider]. Display helpers for metric formatting.
class AnalyticsUseCase {
  AnalyticsUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canViewAnalytics(WidgetRef ref) =>
      PermissionHelper.canAccessAnalytics(_level(ref));

  // ── Data ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getDashboard({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    try {
      return await ref.read(analyticsRepositoryProvider).getDashboard();
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

  static Future<Map<String, dynamic>?> generateReport({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> params,
  }) async {
    try {
      final result =
          await ref.read(analyticsRepositoryProvider).generateReport(params);
      if (context.mounted) {
        AppToast.show(
          'Report generated',
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

  // ── Display helpers ──────────────────────────────────────────────────────

  /// Format a completion rate (0.0–1.0) as a percentage string.
  static String formatPercent(double rate) =>
      '${(rate * 100).toStringAsFixed(0)}%';

  /// Format a large number with K/M suffixes.
  static String formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
