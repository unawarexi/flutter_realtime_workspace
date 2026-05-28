import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/feedback/usecases/feedback_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/feedback_provider.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final fbAsync = ref.watch(feedbackListProvider);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: SAppBar(title: 'Feedback', showBack: true, actions: [
        IconButton(onPressed: () => context.go('/feedback/submit'), icon: const Icon(Icons.add_rounded)),
      ]),
      body: fbAsync.when(
        loading: () => Padding(padding: EdgeInsets.all(hPad), child: Column(children: List.generate(4, (_) => const Padding(padding: EdgeInsets.only(bottom: TSizes.sm), child: TSkeleton(height: 72))))),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (feedbacks) {
          if (feedbacks.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.feedback_outlined, size: 48, color: isDark ? TColors.darkMuted : TColors.lightMuted),
              const SizedBox(height: TSizes.sm),
              Text('No feedback yet', style: TextStyle(color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
              const SizedBox(height: TSizes.md),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(feedbackListProvider),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.md),
              itemCount: feedbacks.length,
              separatorBuilder: (_, __) => const SizedBox(height: TSizes.sm),
              itemBuilder: (_, i) {
                final fb = feedbacks[i];
                final color = _typeColor(fb.type);
                return TCard(
                  hasBorder: true,
                  padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusFull)),
                        child: Text(FeedbackUseCase.typeLabel(fb.type), style: TextStyle(fontSize: TResponsive.sp(context, 10), fontWeight: FontWeight.w600, color: color)),
                      ),
                      const Spacer(),
                      Text('${fb.createdAt.day}/${fb.createdAt.month}/${fb.createdAt.year}', style: TextStyle(fontSize: TResponsive.sp(context, 10), color: isDark ? TColors.textTertiaryDark : TColors.textTertiaryLight)),
                    ]),
                    const SizedBox(height: 6),
                    Text(fb.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: TResponsive.sp(context, 14), color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                    if (fb.rating != null) ...[
                      const SizedBox(height: 6),
                      Row(children: List.generate(5, (j) => Icon(j < (fb.rating ?? 0) ? Icons.star_rounded : Icons.star_border_rounded, size: 16, color: TColors.yellow))),
                    ],
                  ]),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _typeColor(String t) => switch (t) { 'bug' => TColors.error, 'feature' => TColors.info, 'improvement' => TColors.quickActionGreen, 'praise' => TColors.yellow, _ => TColors.neutralGray };
}
