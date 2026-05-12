import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/store/schedule_provider.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';

class CollaborationRepository {
  static Future<dynamic> submitScheduleMeeting({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> meetingData,
    required VoidCallback onSuccess,
    required VoidCallback onError,
    required Function(bool) setSubmitting,
    TextEditingController? titleController,
  }) async {
    setSubmitting(true);
    dynamic result;
    try {
      print('[CollabRepo] Submitting meeting data: $meetingData');
      result = await ref.read(scheduleNotifierProvider.notifier)
          .createSchedule(meetingData);
      print('[CollabRepo] Received result: $result');
    } on TimeoutException catch (_) {
      setSubmitting(false);
      context.showToast(
        "Request timed out. Please check your connection and try again.",
        type: ToastType.error,
      );
      onError();
      return;
    } catch (e, stack) {
      setSubmitting(false);
      print('[CollabRepo][ERROR] $e\n$stack');
      context.showToast(
        "An unexpected error occurred. Please try again.",
        type: ToastType.error,
      );
      onError();
      return;
    }

    setSubmitting(false);

    if (result != null && result['success'] == true) {
      context.showToast(
        'Meeting "${titleController?.text ?? ''}" has been scheduled successfully.',
        type: ToastType.success,
      );
      onSuccess();
    } else {
      context.showToast(
        result?['message'] ?? 'Failed to schedule meeting. Please try again.',
        type: ToastType.error,
      );
      onError();
    }
    return result;
  }
}
