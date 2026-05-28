import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/storage/usecases/storage_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});
  @override
  ConsumerState<UploadScreen> createState() => _State();
}

class _State extends ConsumerState<UploadScreen> {
  bool _loading = false;

  Future<void> _upload() async {
    setState(() => _loading = true);
    await StorageUseCase.uploadFile(context: context, ref: ref);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Upload', showBack: true),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: TSizes.xxl),
              decoration: BoxDecoration(
                color: isDark ? TColors.darkCard : TColors.lightCard,
                borderRadius: BorderRadius.circular(TSizes.radiusLg),
                border: Border.all(color: TColors.primary.withValues(alpha: 0.3), width: 2),
              ),
              child: Column(children: [
                Icon(Icons.cloud_upload_outlined, size: TResponsive.sp(context, 56), color: TColors.primary),
                const SizedBox(height: TSizes.md),
                Text('Tap to upload a file', style: TextStyle(fontSize: TResponsive.sp(context, 16), fontWeight: FontWeight.w600, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                const SizedBox(height: 4),
                Text('Images, documents, videos up to 100MB', style: TextStyle(fontSize: TResponsive.sp(context, 12), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
              ]),
            ),
            const SizedBox(height: TSizes.lg),
            TButton(text: 'Select File', onPressed: _loading ? null : _upload, isLoading: _loading, prefixIcon: Icons.attach_file_rounded),
          ]),
        ),
      ),
    );
  }
}
