import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/models/storage_model.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/storage_repository.dart';

final storageRepositoryProvider = Provider<StorageRepository>((_) {
  return StorageRepository();
});

final storageFilesProvider = FutureProvider.autoDispose
    .family<List<StorageFileModel>, Map<String, String?>>((ref, filters) {
  return ref.watch(storageRepositoryProvider).getFiles(
        workspaceId: filters['workspaceId'],
        projectId: filters['projectId'],
        taskId: filters['taskId'],
        mimeType: filters['mimeType'],
      );
});

final storageUploadProvider =
    StateNotifierProvider<StorageUploadNotifier, StorageUploadState>(
        (ref) => StorageUploadNotifier(ref));

class StorageUploadState {
  final bool isUploading;
  final double progress;
  final StorageFileModel? file;
  final String? error;

  const StorageUploadState({
    this.isUploading = false,
    this.progress = 0,
    this.file,
    this.error,
  });

  StorageUploadState copyWith({
    bool? isUploading,
    double? progress,
    StorageFileModel? file,
    String? error,
  }) =>
      StorageUploadState(
        isUploading: isUploading ?? this.isUploading,
        progress: progress ?? this.progress,
        file: file ?? this.file,
        error: error ?? this.error,
      );
}

class StorageUploadNotifier extends StateNotifier<StorageUploadState> {
  final Ref _ref;
  StorageUploadNotifier(this._ref) : super(const StorageUploadState());

  Future<StorageFileModel?> uploadFile({
    required String filePath,
    required String fileName,
    required String mimeType,
    String? workspaceId,
    String? projectId,
    String? taskId,
  }) async {
    state = state.copyWith(isUploading: true, progress: 0, error: null);
    try {
      final file = await _ref.read(storageRepositoryProvider).uploadFile(
            filePath: filePath,
            fileName: fileName,
            mimeType: mimeType,
            workspaceId: workspaceId,
            projectId: projectId,
            taskId: taskId,
            onProgress: (sent, total) {
              state = state.copyWith(progress: sent / total);
            },
          );
      state = state.copyWith(isUploading: false, progress: 1.0, file: file);
      return file;
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
      return null;
    }
  }

  void reset() => state = const StorageUploadState();
}
