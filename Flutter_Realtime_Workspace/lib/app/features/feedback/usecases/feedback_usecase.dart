import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/feedback_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/feedback_provider.dart';

/// Business logic for the Feedback feature.
///
/// CRUD through [FeedbackSubmitNotifier], filtering, and permission checks.
class FeedbackUseCase {
  FeedbackUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canSubmitFeedback(WidgetRef ref) =>
      PermissionHelper.canCreate(_level(ref), 'feedback');

  // ── CRUD ─────────────────────────────────────────────────────────────────

  static Future<FeedbackModel?> submitFeedback({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final feedback =
          await ref.read(feedbackSubmitProvider.notifier).submit(body);
      if (context.mounted) {
        AppToast.show(
          'Feedback submitted. Thank you!',
          type: ToastType.success,
          context: context,
        );
      }
      return feedback;
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

  static List<FeedbackModel> filterByType(
      List<FeedbackModel> items, String type) =>
      items.where((f) => f.type == type).toList();

  static List<FeedbackModel> filterByStatus(
      List<FeedbackModel> items, String status) =>
      items.where((f) => f.status == status).toList();

  static List<FeedbackModel> searchFeedback(
      List<FeedbackModel> items, String query) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items
        .where((f) =>
            f.title.toLowerCase().contains(q) ||
            (f.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ── Display helpers ──────────────────────────────────────────────────────

  static String typeLabel(String type) {
    switch (type) {
      case 'bug': return 'Bug Report';
      case 'feature': return 'Feature Request';
      case 'improvement': return 'Improvement';
      case 'question': return 'Question';
      default: return type;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'open': return 'Open';
      case 'in_review': return 'In Review';
      case 'planned': return 'Planned';
      case 'completed': return 'Completed';
      case 'declined': return 'Declined';
      default: return status;
    }
  }

  static const List<String> typeOrder = [
    'bug',
    'feature',
    'improvement',
    'question',
  ];

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
