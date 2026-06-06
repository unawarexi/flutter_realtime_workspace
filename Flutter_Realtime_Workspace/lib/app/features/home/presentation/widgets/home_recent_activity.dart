import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/home_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:go_router/go_router.dart';

/// Recent activity feed showing project cards.
class HomeRecentActivity extends StatelessWidget {
  const HomeRecentActivity({
    super.key,
    required this.isDark,
    required this.items,
    required this.isLoading,
  });
  final bool isDark;
  final List<HomeActivityItem> items;
  final bool isLoading;

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
                onPressed: () => context.push('/tasks'),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? TColors.blue400 : TColors.primary,
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
          if (isLoading)
            const Column(
              children: [
                TSkeleton(height: 60),
                SizedBox(height: TSizes.xs + 2),
                TSkeleton(height: 60),
                SizedBox(height: TSizes.xs + 2),
                TSkeleton(height: 60),
              ],
            )
          else if (items.isEmpty)
            TCard(
              hasBorder: true,
              padding: const EdgeInsets.symmetric(
                  vertical: TSizes.md, horizontal: TSizes.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted,
                    size: TSizes.iconMd,
                  ),
                  const SizedBox(width: TSizes.sm),
                  Text(
                    'No recent activity available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? TColors.darkMuted : TColors.lightMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == items.length - 1 ? 0 : TSizes.xs + 2,
                ),
                child: TWidgetAnimations.fadeIn(
                  delay: Duration(milliseconds: 60 * (index + 1)),
                  child: _ActivityCard(
                    icon: item.icon,
                    title: item.title,
                    subtitle:
                        '${item.subtitle}  •  ${HomeUseCase.timeAgo(item.date)}',
                    accentColor: item.color,
                    isDark: isDark,
                  ),
                ),
              );
            }),
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
    required this.accentColor,
    required this.isDark,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TCard(
      hasBorder: true,
      hasShadow: true,
      padding: const EdgeInsets.symmetric(
          horizontal: TSizes.sm + 2, vertical: TSizes.sm),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(TSizes.radiusSm),
            ),
            child: Icon(
              icon,
              size: TSizes.iconSm,
              color: accentColor,
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
