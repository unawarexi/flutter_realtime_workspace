import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/features/legal/usecases/legal_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final privacyAsync = ref.watch(privacyPolicyProvider);

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBg : TColors.lightBg,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: isDark ? TColors.darkBg : TColors.lightBg,
        foregroundColor: isDark ? TColors.textDark : TColors.textLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: privacyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _PrivacyErrorView(
          onRetry: () => ref.invalidate(privacyPolicyProvider),
        ),
        data: (doc) => _PrivacyDocView(doc: doc, isDark: isDark),
      ),
    );
  }
}

class _PrivacyDocView extends StatelessWidget {
  final LegalDoc doc;
  final bool isDark;

  const _PrivacyDocView({required this.doc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hPad = TResponsive.pagePadding(context);

    return SingleChildScrollView(
      padding:
          EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doc.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? TColors.textDark : TColors.textLight,
                ),
          ),
          const SizedBox(height: TSizes.xs),
          Row(
            children: [
              _MetaChip(label: 'Effective: ${doc.effectiveDate}', isDark: isDark),
              const SizedBox(width: TSizes.sm),
              _MetaChip(label: 'v${doc.version}', isDark: isDark),
            ],
          ),
          const SizedBox(height: TSizes.xl),
          ...doc.sections.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: TSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? TColors.textDark
                                    : TColors.textLight,
                              ),
                    ),
                    const SizedBox(height: TSizes.sm),
                    Text(
                      s.content,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: isDark
                            ? TColors.textSecondaryDark
                            : TColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: TSizes.xxl),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _MetaChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : TColors.lightElevated,
        borderRadius: BorderRadius.circular(TSizes.radiusFull),
        border: Border.all(
            color: isDark ? TColors.darkBorder : TColors.lightBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isDark
              ? TColors.textSecondaryDark
              : TColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _PrivacyErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _PrivacyErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: TColors.error),
            const SizedBox(height: TSizes.md),
            const Text('Failed to load Privacy Policy.',
                textAlign: TextAlign.center),
            const SizedBox(height: TSizes.md),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry',
                  style: TextStyle(color: TColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
