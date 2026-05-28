import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/organization_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/organization_provider.dart';

/// Business logic for the Organization feature.
///
/// CRUD through [OrganizationNotifier], member management, and invite flow.
class OrganizationUseCase {
  OrganizationUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canCreateOrganization(WidgetRef ref) =>
      PermissionHelper.canCreate(_level(ref), 'organization');

  static bool canEditOrganization(WidgetRef ref) =>
      PermissionHelper.canEdit(_level(ref), 'organization');

  static bool canManageMembers(WidgetRef ref) =>
      PermissionHelper.canManageMembers(_level(ref));

  // ── CRUD ─────────────────────────────────────────────────────────────────

  static Future<OrganizationModel?> createOrganization({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> body,
  }) async {
    try {
      final org =
          await ref.read(organizationNotifierProvider.notifier).create(body);
      if (context.mounted) {
        AppToast.show(
          'Organization created',
          type: ToastType.success,
          context: context,
        );
      }
      ref.invalidate(organizationsProvider);
      return org;
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

  static Future<OrganizationModel?> updateOrganization({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    try {
      final org =
          await ref.read(organizationNotifierProvider.notifier).update(id, body);
      if (context.mounted) {
        AppToast.show(
          'Organization updated',
          type: ToastType.success,
          context: context,
        );
      }
      return org;
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

  // ── Member management ────────────────────────────────────────────────────

  static Future<void> inviteMember({
    required BuildContext context,
    required WidgetRef ref,
    required String orgId,
    required Map<String, dynamic> body,
  }) async {
    try {
      await ref.read(organizationNotifierProvider.notifier).invite(orgId, body);
      if (context.mounted) {
        AppToast.show(
          'Invitation sent',
          type: ToastType.success,
          context: context,
        );
      }
      ref.invalidate(orgMembersProvider(orgId));
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

  static Future<bool> removeMember({
    required BuildContext context,
    required WidgetRef ref,
    required String orgId,
    required String userId,
  }) async {
    try {
      await ref
          .read(organizationNotifierProvider.notifier)
          .removeMember(orgId, userId);
      if (context.mounted) {
        AppToast.show(
          'Member removed',
          type: ToastType.success,
          context: context,
        );
      }
      ref.invalidate(orgMembersProvider(orgId));
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

  static List<OrganizationModel> searchOrganizations(
      List<OrganizationModel> orgs, String query) {
    if (query.isEmpty) return orgs;
    final q = query.toLowerCase();
    return orgs
        .where((o) =>
            o.name.toLowerCase().contains(q) ||
            o.slug.toLowerCase().contains(q))
        .toList();
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
