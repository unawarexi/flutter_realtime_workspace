import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/storage/usecases/storage_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/storage_provider.dart';

class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});
  @override
  ConsumerState<StorageScreen> createState() => _State();
}

class _State extends ConsumerState<StorageScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final filesAsync = ref.watch(storageFilesProvider);
    final canUpload = StorageUseCase.canUpload(ref);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: SAppBar(title: 'Files', showBack: true, actions: [
        if (canUpload) IconButton(onPressed: () => context.go('/files/upload'), icon: const Icon(Icons.upload_rounded)),
      ]),
      body: filesAsync.when(
        loading: () => Padding(padding: EdgeInsets.all(hPad), child: Column(children: List.generate(5, (_) => const Padding(padding: EdgeInsets.only(bottom: TSizes.sm), child: TSkeleton(height: 56))))),
        error: (_, __) => const Center(child: Text('Failed to load files')),
        data: (files) {
          final filtered = StorageUseCase.searchFiles(files, _query);
          return Column(children: [
            Padding(padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.sm), child: TSearchBar(hint: 'Search files...', onChanged: (q) => setState(() => _query = q))),
            Padding(padding: EdgeInsets.symmetric(horizontal: hPad), child: Row(children: [
              Text('${filtered.length} file${filtered.length == 1 ? '' : 's'}', style: TextStyle(fontSize: TResponsive.sp(context, 12), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
            ])),
            const SizedBox(height: TSizes.sm),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.folder_open_outlined, size: 48, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                      const SizedBox(height: TSizes.sm),
                      Text('No files', style: TextStyle(color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(storageFilesProvider),
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: TSizes.xs),
                        itemBuilder: (_, i) {
                          final f = filtered[i];
                          return TCard(
                            hasBorder: true,
                            padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: _mimeColor(f.mimeType).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: Icon(_mimeIcon(f.mimeType), size: 18, color: _mimeColor(f.mimeType)),
                              ),
                              const SizedBox(width: TSizes.sm),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(f.filename, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: TResponsive.sp(context, 14), fontWeight: FontWeight.w500, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                                Text(StorageUseCase.formatSize(f.size), style: TextStyle(fontSize: TResponsive.sp(context, 11), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                              ])),
                              if (StorageUseCase.canDelete(ref))
                                IconButton(
                                  onPressed: () => StorageUseCase.deleteFile(context: context, ref: ref, fileId: f.id),
                                  icon: Icon(Icons.delete_outline, size: 18, color: TColors.error.withValues(alpha: 0.7)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                            ]),
                          );
                        },
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  IconData _mimeIcon(String? mime) {
    if (mime == null) return Icons.insert_drive_file_outlined;
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime.startsWith('video/')) return Icons.videocam_outlined;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (mime.contains('zip') || mime.contains('rar')) return Icons.archive_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color _mimeColor(String? mime) {
    if (mime == null) return TColors.neutralGray;
    if (mime.startsWith('image/')) return TColors.quickActionPurple;
    if (mime.startsWith('video/')) return TColors.quickActionBlue;
    if (mime.contains('pdf')) return TColors.error;
    return TColors.neutralGray;
  }
}
