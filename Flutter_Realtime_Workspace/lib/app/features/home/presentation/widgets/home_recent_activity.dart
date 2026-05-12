import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Recent activity feed showing project cards.
class HomeRecentActivity extends StatelessWidget {
  const HomeRecentActivity({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TWidgetAnimations.slideUp(
      duration: const Duration(milliseconds: 460),
      offsetY: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle(title: 'Recent Activity', isDark: isDark),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDark ? TColors.blue400 : TColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.sm, vertical: TSizes.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          TWidgetAnimations.fadeIn(
            delay: const Duration(milliseconds: 60),
            child: _ActivityCard(
              icon: TIcons.file,
              title: 'Mobile App Design',
              subtitle: 'Updated 2 hours ago  •  Design Team',
              isDark: isDark,
            ),
          ),
          const SizedBox(height: TSizes.xs + 2),
          TWidgetAnimations.fadeIn(
            delay: const Duration(milliseconds: 120),
            child: _ActivityCard(
              icon: TIcons.issue,
              title: 'Bug Fixes — Sprint 3',
              subtitle: 'Updated 5 hours ago  •  Development',
              isDark: isDark,
            ),
          ),
          const SizedBox(height: TSizes.xs + 2),
          TWidgetAnimations.fadeIn(
            delay: const Duration(milliseconds: 180),
            child: _ActivityCard(
              icon: TIcons.task,
              title: 'Q2 Marketing Goals',
              subtitle: 'Updated yesterday  •  Marketing',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: TSizes.sm + 2, vertical: TSizes.sm),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : TColors.lightSurface,
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        border: Border.all(
          color: isDark ? TColors.darkBorder : TColors.lightBorder,
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: TColors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(TSizes.radiusSm),
            ),
            child: Icon(
              icon,
              size: TSizes.iconSm,
              color: isDark ? TColors.blue400 : TColors.primary,
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? TColors.textDark : TColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            TIcons.more,
            size: TSizes.iconSm,
            color: isDark ? TColors.darkMuted : TColors.lightMuted,
          ),
        ],
      ),
    );
  }
}

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
