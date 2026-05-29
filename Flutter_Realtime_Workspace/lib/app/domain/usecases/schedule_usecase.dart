import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/schedule_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/schedule_provider.dart';

/// Business logic for the Schedule feature.
///
/// CRUD through [ScheduleNotifier], RSVP handling, and display helpers.
class ScheduleUseCase {
  ScheduleUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canCreateSchedule(WidgetRef ref) =>
      PermissionHelper.canCreate(_level(ref), 'schedule');

  static bool canEditSchedule(WidgetRef ref, {bool isOwner = false}) =>
      PermissionHelper.canEdit(_level(ref), 'schedule', isOwner: isOwner);

  // ── CRUD ─────────────────────────────────────────────────────────────────

  static Future<ScheduleModel?> createSchedule({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final schedule =
          await ref.read(scheduleNotifierProvider.notifier).createSchedule(body);
      if (context.mounted) {
        AppToast.show(
          'Schedule created',
          type: ToastType.success,
          context: context,
        );
      }
      return schedule;
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

  static Future<ScheduleModel?> updateSchedule({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    try {
      final schedule = await ref
          .read(scheduleNotifierProvider.notifier)
          .updateSchedule(id, body);
      if (context.mounted) {
        AppToast.show(
          'Schedule updated',
          type: ToastType.success,
          context: context,
        );
      }
      return schedule;
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

  static Future<bool> cancelSchedule({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      await ref.read(scheduleNotifierProvider.notifier).cancelSchedule(id);
      if (context.mounted) {
        AppToast.show(
          'Schedule cancelled',
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

  // ── RSVP ─────────────────────────────────────────────────────────────────

  static Future<void> rsvp({
    required BuildContext context,
    required WidgetRef ref,
    required String scheduleId,
    required String response,
  }) async {
    try {
      await ref.read(scheduleNotifierProvider.notifier).rsvp(scheduleId, response);
      if (context.mounted) {
        AppToast.show(
          'Response recorded',
          type: ToastType.success,
          context: context,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          _extractError(e),
          type: ToastType.error,
          context: context,
        );
      }
    }
  }

  // ── Filtering ────────────────────────────────────────────────────────────

  static List<ScheduleModel> filterUpcoming(List<ScheduleModel> schedules) =>
      schedules.where((s) => s.startTime.isAfter(DateTime.now())).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  static List<ScheduleModel> filterPast(List<ScheduleModel> schedules) =>
      schedules.where((s) => s.startTime.isBefore(DateTime.now())).toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

  static List<ScheduleModel> searchSchedules(
      List<ScheduleModel> schedules, String query) {
    if (query.isEmpty) return schedules;
    final q = query.toLowerCase();
    return schedules
        .where((s) => s.title.toLowerCase().contains(q))
        .toList();
  }

  // ── Display helpers ──────────────────────────────────────────────────────

  static String rsvpLabel(String response) {
    switch (response) {
      case 'accepted': return 'Accepted';
      case 'declined': return 'Declined';
      case 'tentative': return 'Tentative';
      case 'pending': return 'Pending';
      default: return response;
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
