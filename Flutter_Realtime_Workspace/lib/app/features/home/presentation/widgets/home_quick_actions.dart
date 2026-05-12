import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/features/home/usecases/home_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// 2×2 grid of quick-action cards.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final actions = HomeUseCase.quickActions(context);

    return TWidgetAnimations.slideUp(
      duration: const Duration(milliseconds: 440),
      offsetY: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Quick Actions', isDark: isDark),
          const SizedBox(height: TSizes.sm),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: TSizes.sm,
            crossAxisSpacing: TSizes.sm,
            childAspectRatio: 1.72,
            children: List.generate(actions.length, (i) {
              final action = actions[i];
              return TWidgetAnimations.fadeIn(
                delay: Duration(milliseconds: 60 * i),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, action.route),
                  child: _QuickActionCard(
                    action: action,
                    isDark: isDark,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.action,
    required this.isDark,
  });
  final HomeQuickAction action;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : TColors.lightSurface,
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        border: Border.all(
          color: isDark ? TColors.darkBorder : TColors.lightBorder,
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: action.color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(TSizes.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon pill
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(TSizes.radiusSm + 1),
            ),
            child: Icon(action.icon, color: action.color, size: TSizes.iconSm + 2),
          ),
          const Spacer(),
          Text(
            action.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? TColors.textDark : TColors.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            action.subtitle,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isDark ? TColors.darkMuted : TColors.lightMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared section title ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: isDark ? TColors.textDark : TColors.textLight,
      ),
    );
  }
}
