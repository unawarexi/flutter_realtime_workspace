import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/channel_model.dart';
import 'package:flutter_realtime_workspace/app/domain/models/document_model.dart';
import 'package:flutter_realtime_workspace/app/domain/models/meeting_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/channel_provider.dart';
import 'package:flutter_realtime_workspace/store/document_provider.dart';
import 'package:flutter_realtime_workspace/store/meeting_provider.dart';

/// Business logic for the Collaboration feature.
///
/// Orchestrates chat channels, meetings, and documents through their
/// respective providers. The UI calls these static methods only.
class CollaborationUseCase {
  CollaborationUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canCreateChannel(WidgetRef ref) =>
      PermissionHelper.canCreate(_level(ref), 'channel');

  static bool canCreateDocument(WidgetRef ref) =>
      PermissionHelper.canCreate(_level(ref), 'document');

  static bool canCreateMeeting(WidgetRef ref) =>
      PermissionHelper.canCreate(_level(ref), 'schedule');

  // ── Channels ─────────────────────────────────────────────────────────────

  static Future<ChannelModel?> createChannel({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final channel = await ref
          .read(channelNotifierProvider.notifier)
          .createChannel(body);
      if (context.mounted) {
        AppToast.show(
          'Channel created',
          type: ToastType.success,
          context: context,
        );
      }
      return channel;
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

  static void setActiveChannel(WidgetRef ref, ChannelModel channel) {
    ref.read(activeChannelProvider.notifier).state = channel;
  }

  // ── Documents ────────────────────────────────────────────────────────────

  static Future<DocumentModel?> createDocument({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final doc = await ref
          .read(documentNotifierProvider.notifier)
          .createDocument(body);
      if (context.mounted) {
        AppToast.show(
          'Document created',
          type: ToastType.success,
          context: context,
        );
      }
      return doc;
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

  static Future<DocumentModel?> updateDocument({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    try {
      final doc = await ref
          .read(documentNotifierProvider.notifier)
          .updateDocument(id, body);
      if (context.mounted) {
        AppToast.show(
          'Document saved',
          type: ToastType.success,
          context: context,
        );
      }
      return doc;
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

  // ── Meetings ─────────────────────────────────────────────────────────────

  static Future<void> joinMeeting({
    required BuildContext context,
    required WidgetRef ref,
    required String meetingId,
    String? password,
  }) async {
    try {
      await ref
          .read(activeMeetingProvider.notifier)
          .joinMeeting(meetingId, password: password);
      if (context.mounted) {
        AppToast.show(
          'Joined meeting',
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

  static void leaveMeeting(WidgetRef ref) {
    ref.read(activeMeetingProvider.notifier).leaveMeeting();
  }

  static Future<void> rsvpMeeting({
    required BuildContext context,
    required WidgetRef ref,
    required String meetingId,
    required String response,
  }) async {
    try {
      await ref.read(activeMeetingProvider.notifier).rsvp(meetingId, response);
      if (context.mounted) {
        AppToast.show(
          'RSVP recorded',
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

  static List<MeetingModel> filterLiveMeetings(List<MeetingModel> meetings) =>
      meetings.where((m) => m.status == MeetingStatus.live).toList();

  static List<MeetingModel> filterUpcomingMeetings(
      List<MeetingModel> meetings) =>
      meetings
          .where((m) =>
              m.scheduledAt != null && m.scheduledAt!.isAfter(DateTime.now()))
          .toList()
        ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
