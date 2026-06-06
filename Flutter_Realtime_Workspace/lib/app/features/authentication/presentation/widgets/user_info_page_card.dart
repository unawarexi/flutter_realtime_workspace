import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// A framed section card used in the user-info onboarding page view.
///
/// When [headerIcon] and [accentColor] are provided the card renders a
/// gradient hero banner at the top (icon + title + subtitle inside the card).
/// Otherwise it falls back to the original above-card text header layout.
class UserInfoPageCard extends StatelessWidget {
  const UserInfoPageCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isDarkMode,
    this.animDelay = Duration.zero,
    this.accentColor,
    this.headerIcon,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool isDarkMode;
  final Duration animDelay;
  /// Optional accent colour used for the hero gradient header.
  final Color? accentColor;
  /// Optional icon shown inside the hero gradient header.
  final IconData? headerIcon;

  bool get _hasHero => headerIcon != null && accentColor != null;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? TColors.primary;

    return TWidgetAnimations.fadeIn(
      delay: animDelay,
      duration: const Duration(milliseconds: 380),
      child: TWidgetAnimations.slideUp(
        duration: const Duration(milliseconds: 400),
        offsetY: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: TSizes.md, vertical: TSizes.sm),
          child: _hasHero
              ? _heroCard(accent)
              : _classicCard(accent),
        ),
      ),
    );
  }

  // ── Hero-style card (gradient banner inside the card) ─────────────────────
  Widget _heroCard(Color accent) {
    return TWidgetAnimations.fadeIn(
      delay: animDelay + const Duration(milliseconds: 60),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? TColors.darkCard : TColors.lightSurface,
          borderRadius: BorderRadius.circular(TSizes.radiusXl),
          border: Border.all(
            color: isDarkMode ? TColors.darkBorder : TColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDarkMode ? 0.08 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: (isDarkMode ? Colors.black : Colors.grey)
                  .withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient hero banner
            Container(
              padding: const EdgeInsets.fromLTRB(
                  TSizes.md, TSizes.md, TSizes.md, TSizes.sm + 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: isDarkMode ? 0.20 : 0.12),
                    accent.withValues(alpha: isDarkMode ? 0.06 : 0.03),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(TSizes.radiusXl)),
                border: Border(
                  bottom: BorderSide(
                    color: accent.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Icon bubble
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          accent.withValues(alpha: isDarkMode ? 0.25 : 0.14),
                      borderRadius: BorderRadius.circular(TSizes.radiusMd),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.20)),
                    ),
                    child: Icon(headerIcon, size: 20, color: accent),
                  ),
                  const SizedBox(width: TSizes.sm + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDarkMode
                                ? TColors.textPrimaryDark
                                : TColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isDarkMode
                                ? TColors.textSecondaryDark
                                : TColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(TSizes.md),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  // ── Classic card (text header above card, original layout) ────────────────
  Widget _classicCard(Color accent) {
    return Column(
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
              color: isDarkMode ? TColors.darkCard : TColors.lightSurface,
              borderRadius: BorderRadius.circular(TSizes.radiusLg),
              border: Border.all(
                color:
                    isDarkMode ? TColors.darkBorder : TColors.lightBorder,
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
    );
  }
}
