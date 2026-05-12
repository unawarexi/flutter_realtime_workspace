import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((_) {
  return AdminRepository();
});

final adminTenantsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).getTenants();
});

final adminStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getStats();
});

final adminActionsProvider =
    StateNotifierProvider<AdminActionsNotifier, AsyncValue<void>>(
        (ref) => AdminActionsNotifier(ref));

class AdminActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AdminActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> updateTenantStatus(String id, String status) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(adminRepositoryProvider).updateTenantStatus(id, status);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> impersonate(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(adminRepositoryProvider).impersonate(userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
