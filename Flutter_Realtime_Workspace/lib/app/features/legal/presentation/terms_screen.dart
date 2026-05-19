import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/features/legal/usecases/legal_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final termsAsync = ref.watch(termsOfServiceProvider);

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBg : TColors.lightBg,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: isDark ? TColors.darkBg : TColors.lightBg,
        foregroundColor: isDark ? TColors.textDark : TColors.textLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: termsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: 'Failed to load Terms of Service.',
          onRetry: () => ref.invalidate(termsOfServiceProvider),
        ),
        data: (doc) => _LegalDocView(doc: doc, isDark: isDark),
      ),
    );
  }
}

class _LegalDocView extends StatelessWidget {
  final LegalDoc doc;
  final bool isDark;

  const _LegalDocView({required this.doc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hPad = TResponsive.pagePadding(context);

    return SingleChildScrollView(
      padding:
          EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
          // Sections
          ...doc.sections.map((section) => _SectionWidget(
                section: section,
                isDark: isDark,
              )),
          const SizedBox(height: TSizes.xxl),
        ],
      ),
    );
  }
}

class _SectionWidget extends StatelessWidget {
  final LegalSection section;
  final bool isDark;

  const _SectionWidget({required this.section, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? TColors.textDark : TColors.textLight,
                ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            section.content,
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
        color: (isDark ? TColors.darkCard : TColors.lightElevated),
        borderRadius: BorderRadius.circular(TSizes.radiusFull),
        border: Border.all(
          color: isDark ? TColors.darkBorder : TColors.lightBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

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
            Text(message, textAlign: TextAlign.center),
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
