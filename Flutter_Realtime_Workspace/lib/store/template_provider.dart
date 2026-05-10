import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/template_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/template_repository.dart';

final templateRepositoryProvider = Provider<TemplateRepository>((_) {
  return TemplateRepository();
});

final templatesProvider =
    FutureProvider.autoDispose<List<TemplateModel>>((ref) {
  return ref.watch(templateRepositoryProvider).getTemplates();
});

final templatesByTypeProvider =
    FutureProvider.autoDispose.family<List<TemplateModel>, String>((ref, type) {
  return ref
      .watch(templateRepositoryProvider)
      .getTemplates(query: {'type': type});
});

final templateDetailProvider =
    FutureProvider.autoDispose.family<TemplateModel, String>((ref, id) {
  return ref.watch(templateRepositoryProvider).getTemplate(id);
});

final templateNotifierProvider =
    StateNotifierProvider<TemplateNotifier, AsyncValue<TemplateModel?>>(
        (ref) => TemplateNotifier(ref));

class TemplateNotifier extends StateNotifier<AsyncValue<TemplateModel?>> {
  final Ref _ref;
  TemplateNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<TemplateModel> createTemplate(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final template =
          await _ref.read(templateRepositoryProvider).createTemplate(body);
      state = AsyncValue.data(template);
      return template;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<TemplateModel> updateTemplate(
      String id, Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final template =
          await _ref.read(templateRepositoryProvider).updateTemplate(id, body);
      state = AsyncValue.data(template);
      return template;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTemplate(String id) async {
    await _ref.read(templateRepositoryProvider).deleteTemplate(id);
    state = const AsyncValue.data(null);
  }

  Future<Map<String, dynamic>> previewTemplate(
      String id, Map<String, dynamic> variables) async {
    return _ref
        .read(templateRepositoryProvider)
        .previewTemplate(id, variables);
  }
}
