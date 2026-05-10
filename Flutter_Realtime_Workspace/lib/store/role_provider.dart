import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/role_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/role_repository.dart';

final roleRepositoryProvider = Provider<RoleRepository>((_) {
  return RoleRepository();
});

// ── Roles ──────────────────────────────────────────────────────────────────

final rolesProvider = FutureProvider.autoDispose<List<RoleModel>>((ref) {
  return ref.watch(roleRepositoryProvider).getRoles();
});

final roleNotifierProvider =
    StateNotifierProvider<RoleNotifier, AsyncValue<RoleModel?>>(
        (ref) => RoleNotifier(ref));

class RoleNotifier extends StateNotifier<AsyncValue<RoleModel?>> {
  final Ref _ref;
  RoleNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<RoleModel> createRole(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final role = await _ref.read(roleRepositoryProvider).createRole(body);
      state = AsyncValue.data(role);
      return role;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<RoleModel> updateRole(String id, Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final role =
          await _ref.read(roleRepositoryProvider).updateRole(id, body);
      state = AsyncValue.data(role);
      return role;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteRole(String id) async {
    await _ref.read(roleRepositoryProvider).deleteRole(id);
    state = const AsyncValue.data(null);
  }
}

// ── Policies ───────────────────────────────────────────────────────────────

final policiesProvider = FutureProvider.autoDispose<List<PolicyModel>>((ref) {
  return ref.watch(roleRepositoryProvider).getPolicies();
});

final policyNotifierProvider =
    StateNotifierProvider<PolicyNotifier, AsyncValue<PolicyModel?>>(
        (ref) => PolicyNotifier(ref));

class PolicyNotifier extends StateNotifier<AsyncValue<PolicyModel?>> {
  final Ref _ref;
  PolicyNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<PolicyModel> createPolicy(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final policy =
          await _ref.read(roleRepositoryProvider).createPolicy(body);
      state = AsyncValue.data(policy);
      return policy;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<PolicyModel> updatePolicy(String id, Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final policy =
          await _ref.read(roleRepositoryProvider).updatePolicy(id, body);
      state = AsyncValue.data(policy);
      return policy;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// ── User Permissions ───────────────────────────────────────────────────────

final userPermissionsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
        (ref, userId) {
  return ref.watch(roleRepositoryProvider).getUserPermissions(userId);
});
