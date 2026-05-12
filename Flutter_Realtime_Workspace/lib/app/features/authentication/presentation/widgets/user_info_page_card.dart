import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// A framed section card used in the user-info onboarding page view.
/// Animates in with a staggered fade + slide-up on first paint.
class UserInfoPageCard extends StatelessWidget {
  const UserInfoPageCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isDarkMode,
    this.animDelay = Duration.zero,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool isDarkMode;
  final Duration animDelay;

  @override
  Widget build(BuildContext context) {
    return TWidgetAnimations.fadeIn(
      delay: animDelay,
      duration: const Duration(milliseconds: 380),
      child: TWidgetAnimations.slideUp(
        duration: const Duration(milliseconds: 400),
        offsetY: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: TSizes.md, vertical: TSizes.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TWidgetAnimations.fadeIn(
                delay: animDelay + const Duration(milliseconds: 60),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDarkMode ? TColors.textDark : TColors.textLight,
                  ),
                ),
              ),
              const SizedBox(height: TSizes.xs),
              TWidgetAnimations.fadeIn(
                delay: animDelay + const Duration(milliseconds: 100),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDarkMode
                        ? TColors.textSecondaryDark
                        : TColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(height: TSizes.md),
              TWidgetAnimations.fadeIn(
                delay: animDelay + const Duration(milliseconds: 140),
                child: Container(
                  padding: const EdgeInsets.all(TSizes.md),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? TColors.darkCard
                        : TColors.lightSurface,
                    borderRadius:
                        BorderRadius.circular(TSizes.radiusLg),
                    border: Border.all(
                      color: isDarkMode
                          ? TColors.darkBorder
                          : TColors.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDarkMode ? Colors.black : Colors.grey)
                            .withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
