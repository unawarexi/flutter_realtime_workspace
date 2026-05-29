import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/team_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/team_provider.dart';

/// Business logic for the Teams feature.
///
/// CRUD through [TeamNotifier], filtering, search, and display helpers.
class TeamUseCase {
  TeamUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canCreateTeam(WidgetRef ref) =>
      PermissionHelper.canCreate(_level(ref), 'team');

  static bool canEditTeam(WidgetRef ref, {bool isOwner = false}) =>
      PermissionHelper.canEdit(_level(ref), 'team', isOwner: isOwner);

  static bool canDeleteTeam(WidgetRef ref) =>
      PermissionHelper.canDelete(_level(ref), 'team');

  static bool canManageMembers(WidgetRef ref) =>
      PermissionHelper.canManageMembers(_level(ref));

  // ── CRUD ─────────────────────────────────────────────────────────────────

  static Future<TeamModel?> createTeam({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final team =
          await ref.read(teamNotifierProvider.notifier).createTeam(body);
      if (context.mounted) {
        AppToast.show(
          'Team created successfully',
          type: ToastType.success,
          context: context,
        );
      }
      return team;
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

  static Future<void> inviteMember({
    required BuildContext context,
    required WidgetRef ref,
    required String teamId,
    required Map<String, dynamic> body,
  }) async {
    try {
      await ref.read(teamNotifierProvider.notifier).invite(teamId, body);
      if (context.mounted) {
        AppToast.show(
          'Invitation sent',
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

  static Future<bool> deleteTeam({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
  }) async {
    try {
      await ref.read(teamRepositoryProvider).deleteTeam(id);
      if (context.mounted) {
        AppToast.show(
          'Team deleted',
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

  // ── Filtering ────────────────────────────────────────────────────────────

  static List<TeamModel> filterActive(List<TeamModel> teams) =>
      teams.where((t) => t.isActive).toList();

  static List<TeamModel> searchTeams(List<TeamModel> teams, String query) {
    if (query.isEmpty) return teams;
    final q = query.toLowerCase();
    return teams
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            (t.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  static List<TeamModel> filterByType(List<TeamModel> teams, String type) =>
      teams.where((t) => t.type == type).toList();

  // ── Display helpers ──────────────────────────────────────────────────────

  static String typeLabel(String type) {
    switch (type) {
      case 'company': return 'Company';
      case 'agency': return 'Agency';
      case 'startup': return 'Startup';
      case 'non-profit': return 'Non-Profit';
      case 'educational': return 'Educational';
      case 'personal': return 'Personal';
      default: return type;
    }
  }

  static String memberRoleLabel(String role) {
    switch (role) {
      case 'owner': return 'Owner';
      case 'admin': return 'Admin';
      case 'manager': return 'Manager';
      case 'member': return 'Member';
      case 'viewer': return 'Viewer';
      case 'guest': return 'Guest';
      default: return role;
    }
  }

  static const List<String> typeOrder = [
    'company',
    'agency',
    'startup',
    'non-profit',
    'educational',
    'personal',
  ];

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
