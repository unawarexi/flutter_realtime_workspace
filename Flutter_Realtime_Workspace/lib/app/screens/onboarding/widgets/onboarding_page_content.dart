import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Content displayed on a single onboarding page — hero image/icon,
/// title badge, subtitle pill, description, and feature chips.
///
/// Entry animations are handled via [TWidgetAnimations] so each newly-visible
/// page animates in independently.
class OnboardingPageContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDarkMode;

  const OnboardingPageContent({
    super.key,
    required this.data,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final accent = data['color'] as Color;
    final titleColor = isDarkMode ? Colors.white : TColors.textPrimaryLight;
    final descColor =
        isDarkMode ? const Color(0xFFCBD5E0) : TColors.textTertiaryLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        // Three tiers based on available height
        final isXSmall = h < 440;
        final isSmall = h < 580;

        final imageSize = isXSmall ? 96.0 : isSmall ? 120.0 : 148.0;
        final titleFont = isXSmall ? 20.0 : isSmall ? 22.0 : 24.0;
        final descFont = isXSmall ? 12.0 : 13.0;
        final topGap = isXSmall ? TSizes.xs : isSmall ? TSizes.sm : TSizes.md;
        final midGap = isXSmall ? TSizes.xs : isSmall ? TSizes.sm : TSizes.md;
        final descGap = isXSmall ? TSizes.xs : TSizes.sm;

        return SingleChildScrollView(
          // Allow scrolling on very small devices as a safety net
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: TSizes.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: topGap),

                // ── Hero visual ──────────────────────────────────────────────
                TWidgetAnimations.scaleIn(
                  child: _HeroVisual(
                    imagePath: data['image'] as String?,
                    icon: data['icon'] as IconData?,
                    accentColor: accent,
                    imageSize: imageSize,
                    isDarkMode: isDarkMode,
                  ),
                ),

                SizedBox(height: midGap),

                // ── Title ────────────────────────────────────────────────────
                TWidgetAnimations.slideUp(
                  offsetY: 16,
                  child: Text(
                    data['title'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleFont,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                SizedBox(height: TSizes.xs + 2),

                // ── Subtitle pill ────────────────────────────────────────────
                TWidgetAnimations.fadeIn(
                  delay: const Duration(milliseconds: 60),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.md,
                      vertical: TSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.13),
                      borderRadius:
                          BorderRadius.circular(TSizes.radiusFull),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      data['subtitle'] as String,
                      style: TextStyle(
                        fontSize: TSizes.fontSizeXS + 1,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: descGap),

                // ── Description ──────────────────────────────────────────────
                TWidgetAnimations.fadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    data['description'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: descFont,
                      color: descColor,
                      height: 1.55,
                    ),
                  ),
                ),

                SizedBox(height: midGap),

                // ── Feature chips ────────────────────────────────────────────
                TWidgetAnimations.fadeIn(
                  delay: const Duration(milliseconds: 140),
                  child: _FeatureChips(
                    features: _featuresFor(data['title'] as String),
                    accentColor: accent,
                    isDarkMode: isDarkMode,
                    compact: isSmall,
                  ),
                ),

                SizedBox(height: TSizes.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  static List<Map<String, dynamic>> _featuresFor(String title) {
    switch (title) {
      case 'Real-time Collaboration':
        return [
          {'icon': Icons.speed_rounded, 'text': 'Instant Sync'},
          {'icon': Icons.lock_outline_rounded, 'text': 'Secure'},
          {'icon': Icons.cloud_done_outlined, 'text': 'Cloud'},
        ];
      case 'Smart Task Management':
        return [
          {'icon': Icons.auto_awesome_rounded, 'text': 'AI Powered'},
          {'icon': Icons.track_changes_rounded, 'text': 'Progress'},
          {'icon': Icons.notifications_active_outlined, 'text': 'Alerts'},
        ];
      case 'Seamless Communication':
        return [
          {'icon': Icons.chat_bubble_outline_rounded, 'text': 'Live Chat'},
          {'icon': Icons.videocam_outlined, 'text': 'Video Calls'},
          {'icon': Icons.share_outlined, 'text': 'File Share'},
        ];
      case 'Project Timeline Tracking':
        return [
          {'icon': Icons.calendar_today_outlined, 'text': 'Milestones'},
          {'icon': Icons.timeline_rounded, 'text': 'Timeline'},
          {'icon': Icons.insights_rounded, 'text': 'Insights'},
        ];
      case 'Performance Analytics':
        return [
          {'icon': Icons.bar_chart_rounded, 'text': 'Reports'},
          {'icon': Icons.trending_up_rounded, 'text': 'Metrics'},
          {'icon': Icons.psychology_outlined, 'text': 'AI Insights'},
        ];
      default:
        return [];
    }
  }
}

// ─── Hero visual ─────────────────────────────────────────────────────────────

class _HeroVisual extends StatelessWidget {
  final String? imagePath;
  final IconData? icon;
  final Color accentColor;
  final double imageSize;
  final bool isDarkMode;

  const _HeroVisual({
    required this.imagePath,
    required this.icon,
    required this.accentColor,
    required this.imageSize,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDarkMode ? 0.28 : 0.15),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TSizes.radiusXl),
        child: imagePath != null
            ? Image.asset(
                imagePath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _IconFallback(
                  icon: icon,
                  accentColor: accentColor,
                  isDarkMode: isDarkMode,
                ),
              )
            : _IconFallback(
                icon: icon,
                accentColor: accentColor,
                isDarkMode: isDarkMode,
              ),
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  final IconData? icon;
  final Color accentColor;
  final bool isDarkMode;

  const _IconFallback({
    required this.icon,
    required this.accentColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDarkMode ? 0.12 : 0.09),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.22),
          width: 2,
        ),
      ),
      child: Icon(
        icon ?? Icons.workspace_premium_outlined,
        size: 72,
        color: accentColor,
      ),
    );
  }
}

// ─── Feature chips row ───────────────────────────────────────────────────────

class _FeatureChips extends StatelessWidget {
  final List<Map<String, dynamic>> features;
  final Color accentColor;
  final bool isDarkMode;
  final bool compact;

  const _FeatureChips({
    required this.features,
    required this.accentColor,
    required this.isDarkMode,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();

    final chipVPad = compact ? TSizes.xs : TSizes.sm;
    final iconSz = compact ? TSizes.iconSm : TSizes.iconSm + 2.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: features.map((f) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: TSizes.xs + 1),
          padding: EdgeInsets.symmetric(
            horizontal: TSizes.sm + 2,
            vertical: chipVPad,
          ),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.07)
                : accentColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(TSizes.radiusMd),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.10)
                  : accentColor.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                f['icon'] as IconData,
                size: iconSz,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.80)
                    : accentColor,
              ),
              SizedBox(height: TSizes.xs),
              Text(
                f['text'] as String,
                style: TextStyle(
                  fontSize: TSizes.fontSizeXS,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.68)
                      : accentColor.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
