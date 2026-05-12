import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/integration_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/integration_repository.dart';

final integrationRepositoryProvider = Provider<IntegrationRepository>((_) {
  return IntegrationRepository();
});

final integrationsProvider =
    FutureProvider.autoDispose.family<List<IntegrationModel>, String>(
        (ref, workspaceId) {
  return ref.watch(integrationRepositoryProvider).getIntegrations(workspaceId);
});

final integrationNotifierProvider =
    StateNotifierProvider<IntegrationNotifier, AsyncValue<IntegrationModel?>>(
        (ref) => IntegrationNotifier(ref));

class IntegrationNotifier extends StateNotifier<AsyncValue<IntegrationModel?>> {
  final Ref _ref;
  IntegrationNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<IntegrationModel> installIntegration(
      Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final integration = await _ref
          .read(integrationRepositoryProvider)
          .installIntegration(body);
      state = AsyncValue.data(integration);
      return integration;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> uninstall(String id) async {
    await _ref.read(integrationRepositoryProvider).uninstallIntegration(id);
  }

  Future<Map<String, dynamic>> test(String id) async {
    return _ref.read(integrationRepositoryProvider).testIntegration(id);
  }
}
