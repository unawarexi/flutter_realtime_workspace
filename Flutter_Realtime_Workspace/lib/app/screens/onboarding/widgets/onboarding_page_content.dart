import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
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
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final descColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF374151);

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
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(
                              alpha: isDarkMode ? 0.50 : 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                      color: isDarkMode
                          ? accent.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.90),
                      borderRadius:
                          BorderRadius.circular(TSizes.radiusFull),
                      border: Border.all(
                        color: accent.withValues(
                            alpha: isDarkMode ? 0.50 : 0.38),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.20),
                          blurRadius: 14,
                        ),
                      ],
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: features.asMap().entries.map((entry) {
        final idx = entry.key;
        final f = entry.value;
        // Middle card is scaled down to create a "hollow" concave effect
        final isMiddle = idx == 1 && features.length == 3;
        final scale = isMiddle ? 0.82 : 1.0;

        return Expanded(
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: TSizes.xs),
              padding: EdgeInsets.symmetric(
                horizontal: TSizes.sm,
                vertical: compact ? TSizes.sm + 2 : TSizes.md + 2,
              ),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: isMiddle ? 0.05 : 0.13)
                    : (isMiddle
                        ? accentColor.withValues(alpha: 0.07)
                        : Colors.white.withValues(alpha: 0.88)),
                borderRadius: BorderRadius.circular(TSizes.radiusMd + 2),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white
                          .withValues(alpha: isMiddle ? 0.10 : 0.24)
                      : accentColor
                          .withValues(alpha: isMiddle ? 0.20 : 0.35),
                  width: 1.4,
                ),
                boxShadow: isMiddle
                    ? null
                    : [
                        BoxShadow(
                          color: accentColor
                              .withValues(alpha: isDarkMode ? 0.18 : 0.14),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f['icon'] as IconData,
                    size: compact ? 26 : 30,
                    color: isDarkMode
                        ? Colors.white.withValues(
                            alpha: isMiddle ? 0.50 : 0.92)
                        : accentColor.withValues(
                            alpha: isMiddle ? 0.55 : 1.0),
                  ),
                  SizedBox(height: TSizes.xs + 2),
                  Text(
                    f['text'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode
                          ? Colors.white.withValues(
                              alpha: isMiddle ? 0.45 : 0.90)
                          : accentColor.withValues(
                              alpha: isMiddle ? 0.55 : 0.95),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
