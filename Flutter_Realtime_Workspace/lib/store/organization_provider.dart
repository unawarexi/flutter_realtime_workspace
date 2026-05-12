import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/organization_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/organization_repository.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((_) {
  return OrganizationRepository();
});

/// All organizations for the current user.
final organizationsProvider =
    FutureProvider.autoDispose<List<OrganizationModel>>((ref) {
  return ref.watch(organizationRepositoryProvider).getOrganizations();
});

/// Organization members.
final orgMembersProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, orgId) {
  return ref.watch(organizationRepositoryProvider).getMembers(orgId);
});

/// Organization CRUD + invite notifier.
final organizationNotifierProvider =
    StateNotifierProvider<OrganizationNotifier, AsyncValue<OrganizationModel?>>(
        (ref) => OrganizationNotifier(ref));

class OrganizationNotifier
    extends StateNotifier<AsyncValue<OrganizationModel?>> {
  final Ref _ref;
  OrganizationNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<OrganizationModel> create(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final org = await _ref
          .read(organizationRepositoryProvider)
          .createOrganization(body);
      state = AsyncValue.data(org);
      return org;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<OrganizationModel> update(String id, Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final org = await _ref
          .read(organizationRepositoryProvider)
          .updateOrganization(id, body);
      state = AsyncValue.data(org);
      return org;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> invite(String orgId, Map<String, dynamic> body) async {
    await _ref.read(organizationRepositoryProvider).invite(orgId, body);
  }

  Future<void> removeMember(String orgId, String userId) async {
    await _ref.read(organizationRepositoryProvider).removeMember(orgId, userId);
  }
}
