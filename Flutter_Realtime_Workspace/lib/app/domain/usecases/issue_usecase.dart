import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/issue_provider.dart';
import 'package:flutter_realtime_workspace/app/domain/models/issue_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';

class IssueUseCase {
  // ── Permissions ──────────────────────────────────────────────────────────

  /// Anyone member+ can create an issue.
  static bool canCreateIssue(WidgetRef ref) {
    final level = _level(ref);
    return PermissionHelper.canCreate(level, 'issue');
  }

  /// Owner or manager+ can edit.
  static bool canEditIssue(WidgetRef ref, {bool isOwner = false}) {
    final level = _level(ref);
    return PermissionHelper.canEdit(level, 'issue', isOwner: isOwner);
  }

  /// Manager+ (or owner) can delete.
  static bool canDeleteIssue(WidgetRef ref) {
    final level = _level(ref);
    return PermissionHelper.canDelete(level, 'issue');
  }

  /// Any member+ can comment.
  static bool canComment(WidgetRef ref) {
    final level = _level(ref);
    return PermissionHelper.isMember(level);
  }

  /// Admin+ can manage project issues.
  static bool canManageIssues(WidgetRef ref) {
    final level = _level(ref);
    return PermissionHelper.isAdmin(level);
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  static Future<IssueModel> createIssue(
      WidgetRef ref, Map<String, dynamic> body) async {
    return ref.read(issueNotifierProvider.notifier).createIssue(body);
  }

  static Future<IssueModel> updateIssue(
      WidgetRef ref, String id, Map<String, dynamic> body) async {
    return ref.read(issueNotifierProvider.notifier).updateIssue(id, body);
  }

  static Future<void> deleteIssue(WidgetRef ref, String id) async {
    return ref.read(issueNotifierProvider.notifier).deleteIssue(id);
  }

  static Future<void> addComment(
      WidgetRef ref, String issueId, String content) async {
    await ref
        .read(issueRepositoryProvider)
        .addComment(issueId, content);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Group a list of issues by status, ordered appropriately.
  static Map<String, List<IssueModel>> groupByStatus(
      List<IssueModel> issues) {
    final Map<String, List<IssueModel>> result = {};
    for (final s in statusOrder) {
      result[s] = issues.where((i) => i.status == s).toList();
    }
    return result;
  }

  /// Group by type.
  static Map<String, List<IssueModel>> groupByType(
      List<IssueModel> issues) {
    final Map<String, List<IssueModel>> result = {};
    for (final t in typeOrder) {
      result[t] = issues.where((i) => i.type == t).toList();
    }
    return result;
  }

  /// Filter issues by search query.
  static List<IssueModel> searchIssues(
      List<IssueModel> issues, String query) {
    if (query.isEmpty) return issues;
    final q = query.toLowerCase();
    return issues
        .where((i) =>
            i.title.toLowerCase().contains(q) ||
            (i.description?.toLowerCase().contains(q) ?? false) ||
            (i.key?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  /// Filter by severity.
  static List<IssueModel> filterBySeverity(
      List<IssueModel> issues, String severity) {
    return issues.where((i) => i.severity == severity).toList();
  }

  // ── Constants ─────────────────────────────────────────────────────────────

  static const List<String> statusOrder = [
    'open',
    'in_progress',
    'resolved',
    'closed',
    'reopened',
    'wont_fix',
  ];

  static const List<String> typeOrder = [
    'bug',
    'feature',
    'improvement',
    'task',
    'epic',
    'story',
  ];

  static const List<String> severityOrder = [
    'trivial',
    'minor',
    'major',
    'blocker',
  ];

  // ── Private ───────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) {
    final user = ref.read(currentUserProvider).valueOrNull;
    return user?.permissionsLevel ?? 'guest';
  }
}
