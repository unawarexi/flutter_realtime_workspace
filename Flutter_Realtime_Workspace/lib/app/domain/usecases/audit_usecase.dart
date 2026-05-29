import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/audit_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/audit_provider.dart';

/// Business logic for the Audit Log feature.
///
/// Read-only — fetches audit logs through [auditRepositoryProvider].
/// Access gated to admin+ only.
class AuditUseCase {
  AuditUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canViewAuditLogs(WidgetRef ref) =>
      PermissionHelper.canAccessAdmin(_level(ref));

  // ── Filtering ────────────────────────────────────────────────────────────

  static List<AuditLogModel> filterByAction(
      List<AuditLogModel> logs, String action) =>
      logs.where((l) => l.action == action).toList();

  static List<AuditLogModel> filterByResourceType(
      List<AuditLogModel> logs, String resourceType) =>
      logs.where((l) => l.target?.type == resourceType).toList();

  static List<AuditLogModel> filterByDateRange(
      List<AuditLogModel> logs, DateTime from, DateTime to) =>
      logs
          .where((l) =>
              l.createdAt.isAfter(from) && l.createdAt.isBefore(to))
          .toList();

  static List<AuditLogModel> searchLogs(
      List<AuditLogModel> logs, String query) {
    if (query.isEmpty) return logs;
    final q = query.toLowerCase();
    return logs
        .where((l) =>
            l.action.toLowerCase().contains(q) ||
            (l.target?.type?.toLowerCase().contains(q) ?? false) ||
            (l.target?.name?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ── Refresh ──────────────────────────────────────────────────────────────

  static void refresh(WidgetRef ref, Map<String, dynamic> filters) =>
      ref.invalidate(auditLogsProvider(filters));

  // ── Display helpers ──────────────────────────────────────────────────────

  static String actionLabel(String action) {
    switch (action) {
      case 'create': return 'Created';
      case 'update': return 'Updated';
      case 'delete': return 'Deleted';
      case 'login': return 'Logged In';
      case 'logout': return 'Logged Out';
      case 'invite': return 'Invited';
      case 'remove': return 'Removed';
      case 'archive': return 'Archived';
      case 'restore': return 'Restored';
      default: return action;
    }
  }

  static const List<String> resourceTypes = [
    'user',
    'project',
    'task',
    'team',
    'workspace',
    'organization',
    'channel',
    'meeting',
    'document',
    'workflow',
  ];

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';
}
