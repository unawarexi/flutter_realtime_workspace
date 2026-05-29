import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/notification_provider.dart';

/// Business logic for the Notification feature.
///
/// Manages unread count, mark-as-read, and notification preferences
/// through [notificationRepositoryProvider].
class NotificationUseCase {
  NotificationUseCase._();

  // ── Unread count ─────────────────────────────────────────────────────────

  static int unreadCount(WidgetRef ref) =>
      ref.watch(unreadNotificationCountProvider);

  static void resetUnread(WidgetRef ref) =>
      ref.read(unreadNotificationCountProvider.notifier).state = 0;

  // ── Mark as read ─────────────────────────────────────────────────────────

  static Future<void> markAllRead({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    resetUnread(ref);
    if (context.mounted) {
      AppToast.show(
        'All notifications marked as read',
        type: ToastType.success,
        context: context,
      );
    }
  }

  static void markRead({
    required WidgetRef ref,
    required String notificationId,
  }) {
    final current = ref.read(unreadNotificationCountProvider);
    if (current > 0) {
      ref.read(unreadNotificationCountProvider.notifier).state = current - 1;
    }
  }

  // ── Permission ───────────────────────────────────────────────────────────

  static bool canManagePreferences(WidgetRef ref) =>
      PermissionHelper.isMember(_level(ref));

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';
}
