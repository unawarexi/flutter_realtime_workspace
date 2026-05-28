import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/app/domain/models/storage_model.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/storage_provider.dart';

/// Business logic for the Storage / File Management feature.
///
/// Upload through [StorageUploadNotifier], file listing, delete, and
/// display helpers for file sizes and types.
class StorageUseCase {
  StorageUseCase._();

  // ── Permissions ──────────────────────────────────────────────────────────

  static bool canUpload(WidgetRef ref) =>
      PermissionHelper.isEmployee(_level(ref));

  static bool canDelete(WidgetRef ref) =>
      PermissionHelper.canDelete(_level(ref), 'document');

  // ── Upload ───────────────────────────────────────────────────────────────

  static Future<StorageFileModel?> uploadFile({
    required BuildContext context,
    required WidgetRef ref,
    required String filePath,
    required String fileName,
    required String mimeType,
    String? workspaceId,
    String? projectId,
    String? taskId,
  }) async {
    try {
      final file = await ref.read(storageUploadProvider.notifier).uploadFile(
            filePath: filePath,
            fileName: fileName,
            mimeType: mimeType,
            workspaceId: workspaceId,
            projectId: projectId,
            taskId: taskId,
          );
      if (file != null && context.mounted) {
        AppToast.show(
          'File uploaded successfully',
          type: ToastType.success,
          context: context,
        );
      }
      return file;
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

  static Future<bool> deleteFile({
    required BuildContext context,
    required WidgetRef ref,
    required String fileId,
  }) async {
    try {
      await ref.read(storageRepositoryProvider).deleteFile(fileId);
      if (context.mounted) {
        AppToast.show(
          'File deleted',
          type: ToastType.success,
          context: context,
        );
      }
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

  static List<StorageFileModel> filterByMimeType(
      List<StorageFileModel> files, String mimeType) =>
      files.where((f) => f.mimeType.startsWith(mimeType)).toList();

  static List<StorageFileModel> searchFiles(
      List<StorageFileModel> files, String query) {
    if (query.isEmpty) return files;
    final q = query.toLowerCase();
    return files
        .where((f) => f.filename.toLowerCase().contains(q))
        .toList();
  }

  // ── Display helpers ──────────────────────────────────────────────────────

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String fileTypeLabel(String mimeType) {
    if (mimeType.startsWith('image/')) return 'Image';
    if (mimeType.startsWith('video/')) return 'Video';
    if (mimeType.startsWith('audio/')) return 'Audio';
    if (mimeType.contains('pdf')) return 'PDF';
    if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) return 'Spreadsheet';
    if (mimeType.contains('document') || mimeType.contains('word')) return 'Document';
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) return 'Presentation';
    if (mimeType.contains('zip') || mimeType.contains('compressed')) return 'Archive';
    return 'File';
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static String _level(WidgetRef ref) =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  static String _extractError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
