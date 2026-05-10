import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((_) {
  return AdminRepository();
});

final adminOrgStatsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
        (ref, orgId) {
  return ref.watch(adminRepositoryProvider).getOrgStats(orgId);
});

final adminUsersProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>,
        Map<String, dynamic>>((ref, filters) {
  return ref.watch(adminRepositoryProvider).getAllUsers(
        orgId: filters['orgId'] as String?,
        workspaceId: filters['workspaceId'] as String?,
      );
});

final systemHealthProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getSystemHealth();
});

final pendingApprovalsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).getPendingApprovals();
});

final adminActionsProvider =
    StateNotifierProvider<AdminActionsNotifier, AsyncValue<void>>(
        (ref) => AdminActionsNotifier(ref));

class AdminActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AdminActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> suspendUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(adminRepositoryProvider).suspendUser(userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> unsuspendUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(adminRepositoryProvider).unsuspendUser(userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> approveRequest(String requestId) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(adminRepositoryProvider).approveRequest(requestId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(adminRepositoryProvider)
          .rejectRequest(requestId, reason);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
