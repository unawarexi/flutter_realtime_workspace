import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/features/home/usecases/home_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Greeting headline, display name, and a summary status pill.
class HomeWelcome extends ConsumerWidget {
  const HomeWelcome({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = HomeUseCase.displayName(ref);
    final greeting = HomeUseCase.greeting();

    return TWidgetAnimations.slideUp(
      duration: const Duration(milliseconds: 480),
      offsetY: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting row ──────────────────────────────────────
          Row(
            children: [
              Text(
                '$greeting, ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? TColors.textSecondaryDark
                      : TColors.textSecondaryLight,
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? TColors.textDark : TColors.textLight,
                ),
              ),
              const SizedBox(width: TSizes.xs),
              const Text('👋', style: TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: TSizes.xs - 2),
          // ── Headline ──────────────────────────────────────────
          Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.1,
              color: isDark ? TColors.textDark : TColors.textLight,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          // ── Status pill ───────────────────────────────────────
          TWidgetAnimations.fadeIn(
            delay: const Duration(milliseconds: 160),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.sm + 2,
                vertical: TSizes.xs - 1,
              ),
              decoration: BoxDecoration(
                color: TColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(TSizes.radiusFull),
                border: Border.all(
                  color: TColors.primary.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: TColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: TSizes.xs),
                  Text(
                    '3 active projects  •  2 pending reviews',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? TColors.blue400 : TColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
