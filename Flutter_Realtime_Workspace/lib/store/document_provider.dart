import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/document_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/document_repository.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((_) {
  return DocumentRepository();
});

final documentsProvider = FutureProvider.autoDispose
    .family<List<DocumentModel>, Map<String, String?>>((ref, filters) {
  return ref.watch(documentRepositoryProvider).getDocuments(
        workspaceId: filters['workspaceId'],
        projectId: filters['projectId'],
      );
});

final documentDetailProvider =
    FutureProvider.autoDispose.family<DocumentModel, String>((ref, id) {
  return ref.watch(documentRepositoryProvider).getDocument(id);
});

final documentNotifierProvider =
    StateNotifierProvider<DocumentNotifier, AsyncValue<DocumentModel?>>(
        (ref) => DocumentNotifier(ref));

class DocumentNotifier extends StateNotifier<AsyncValue<DocumentModel?>> {
  final Ref _ref;
  DocumentNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<DocumentModel> createDocument(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final doc =
          await _ref.read(documentRepositoryProvider).createDocument(body);
      state = AsyncValue.data(doc);
      return doc;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<DocumentModel> updateDocument(
      String id, Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final doc =
          await _ref.read(documentRepositoryProvider).updateDocument(id, body);
      state = AsyncValue.data(doc);
      return doc;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
