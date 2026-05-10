import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/organization_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/organization_repository.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((_) {
  return OrganizationRepository();
});

/// Current user's organization.
final currentOrganizationProvider =
    FutureProvider.autoDispose<OrganizationModel>((ref) {
  return ref.watch(organizationRepositoryProvider).getMyOrganization();
});

/// Organization members.
final orgMembersProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, orgId) {
  return ref.watch(organizationRepositoryProvider).getMembers(orgId);
});

/// Invite code generation state.
final inviteCodeProvider = StateProvider<String?>((ref) => null);

final inviteCodeNotifierProvider =
    StateNotifierProvider<InviteCodeNotifier, AsyncValue<String?>>((ref) {
  return InviteCodeNotifier(ref);
});

class InviteCodeNotifier extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;
  InviteCodeNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> generateCode(String orgId) async {
    state = const AsyncValue.loading();
    try {
      final code =
          await _ref.read(organizationRepositoryProvider).generateInviteCode(orgId);
      state = AsyncValue.data(code);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> joinByCode(String code) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(organizationRepositoryProvider).joinByInviteCode(code);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
