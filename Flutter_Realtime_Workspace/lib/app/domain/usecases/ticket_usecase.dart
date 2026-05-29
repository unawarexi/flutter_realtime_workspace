import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/ticket_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/ticket_provider.dart';

/// Business logic for the Tickets / Support feature.
///
/// CRUD through [TicketNotifier], status flow, grouping, and display helpers.
class TicketUseCase {
  TicketUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canCreateTicket(WidgetRef ref) =>
      PermissionHelper.canCreate(_level(ref), 'ticket');

  static bool canEditTicket(WidgetRef ref, {bool isOwner = false}) =>
      PermissionHelper.canEdit(_level(ref), 'ticket', isOwner: isOwner);

  static bool canDeleteTicket(WidgetRef ref) =>
      PermissionHelper.canDelete(_level(ref), 'ticket');

  // ── CRUD ─────────────────────────────────────────────────────────────────

  static Future<TicketModel?> createTicket({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final ticket =
          await ref.read(ticketNotifierProvider.notifier).createTicket(body);
      if (context.mounted) {
        AppToast.show(
          'Ticket created',
          type: ToastType.success,
          context: context,
        );
      }
      return ticket;
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

  static Future<TicketModel?> updateTicket({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    try {
      final ticket =
          await ref.read(ticketNotifierProvider.notifier).updateTicket(id, body);
      if (context.mounted) {
        AppToast.show(
          'Ticket updated',
          type: ToastType.success,
          context: context,
        );
      }
      return ticket;
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

  static Future<bool> updateStatus({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required String newStatus,
  }) async {
    return await updateTicket(
      context: context,
      ref: ref,
      id: id,
      body: {'status': newStatus},
    ) != null;
  }

  // ── Grouping ─────────────────────────────────────────────────────────────

  static Map<String, List<TicketModel>> groupByStatus(
      List<TicketModel> tickets) {
    final Map<String, List<TicketModel>> result = {};
    for (final s in statusOrder) {
      result[s] = tickets.where((t) => t.status == s).toList();
    }
    return result;
  }

  static Map<String, List<TicketModel>> groupByPriority(
      List<TicketModel> tickets) {
    final Map<String, List<TicketModel>> result = {};
    for (final p in priorityOrder) {
      result[p] = tickets.where((t) => t.priority == p).toList();
    }
    return result;
  }

  // ── Filtering ────────────────────────────────────────────────────────────

  static List<TicketModel> searchTickets(
      List<TicketModel> tickets, String query) {
    if (query.isEmpty) return tickets;
    final q = query.toLowerCase();
    return tickets
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            (t.description?.toLowerCase().contains(q) ?? false) ||
            (t.ticketNumber?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  static List<TicketModel> filterByPriority(
      List<TicketModel> tickets, String priority) =>
      tickets.where((t) => t.priority == priority).toList();

  // ── Display helpers ──────────────────────────────────────────────────────

  static String statusLabel(String status) {
    switch (status) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'pending': return 'Pending';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      case 'escalated': return 'Escalated';
      default: return status;
    }
  }

  static String priorityLabel(String priority) {
    switch (priority) {
      case 'critical': return 'Critical';
      case 'high': return 'High';
      case 'medium': return 'Medium';
      case 'low': return 'Low';
      default: return priority;
    }
  }

  static const List<String> statusOrder = [
    'open',
    'in_progress',
    'pending',
    'resolved',
    'closed',
    'escalated',
  ];

  static const List<String> priorityOrder = [
    'critical',
    'high',
    'medium',
    'low',
  ];

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
