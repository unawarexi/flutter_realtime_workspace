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

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final isXSmall = h < 440;
        final isSmall = h < 580;

        final heroSize = isXSmall ? 88.0 : isSmall ? 108.0 : 124.0;
        final titleFont = isXSmall ? 22.0 : isSmall ? 24.0 : 26.0;
        final descFont = isXSmall ? 12.0 : 13.5;
        final vGap = isXSmall ? 8.0 : isSmall ? 12.0 : 16.0;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: TSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: vGap),

                // ── Hero with concentric glow rings ──────────────────────────
                Center(
                  child: TWidgetAnimations.scaleIn(
                    child: _HeroVisual(
                      imagePath: data['image'] as String?,
                      icon: data['icon'] as IconData?,
                      accentColor: accent,
                      imageSize: heroSize,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ),

                SizedBox(height: vGap),

                // ── Accent bar + Title ────────────────────────────────────────
                TWidgetAnimations.slideUp(
                  offsetY: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, accent.withValues(alpha: 0.35)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data['title'] as String,
                        style: TextStyle(
                          fontSize: titleFont,
                          fontWeight: FontWeight.w900,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // ── Subtitle ─────────────────────────────────────────────────
                TWidgetAnimations.fadeIn(
                  delay: const Duration(milliseconds: 60),
                  child: Text(
                    data['subtitle'] as String,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                SizedBox(height: isXSmall ? 8.0 : 10.0),

                // ── Description ──────────────────────────────────────────────
                TWidgetAnimations.fadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    data['description'] as String,
                    style: TextStyle(
                      fontSize: descFont,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.78)
                          : const Color(0xFF374151),
                      height: 1.55,
                    ),
                  ),
                ),

                SizedBox(height: vGap),

                // ── Feature pills ─────────────────────────────────────────────
                TWidgetAnimations.fadeIn(
                  delay: const Duration(milliseconds: 140),
                  child: _FeatureChips(
                    features: _featuresFor(data['title'] as String),
                    accentColor: accent,
                    isDarkMode: isDarkMode,
                  ),
                ),

                const SizedBox(height: TSizes.sm),
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
    final ringPad = imageSize * 0.22;
    final outerSize = imageSize + ringPad * 2;
    final midSize = imageSize + ringPad;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outer ring (thin border) ────────────────────────────────────
          Container(
            width: outerSize,
            height: outerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(
                    alpha: isDarkMode ? 0.14 : 0.10),
                width: 1,
              ),
            ),
          ),
          // ── Middle ring (light fill + border) ──────────────────────────
          Container(
            width: midSize,
            height: midSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(
                  alpha: isDarkMode ? 0.08 : 0.06),
              border: Border.all(
                color: accentColor.withValues(
                    alpha: isDarkMode ? 0.22 : 0.18),
                width: 1.5,
              ),
            ),
          ),
          // ── Image / icon ────────────────────────────────────────────────
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TSizes.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(
                      alpha: isDarkMode ? 0.40 : 0.22),
                  blurRadius: 30,
                  spreadRadius: 2,
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
          ),
        ],
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

  const _FeatureChips({
    required this.features,
    required this.accentColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();

    return Column(
      children: List.generate(features.length, (i) {
        final f = features[i];
        return Container(
          margin: EdgeInsets.only(bottom: i < features.length - 1 ? 9.0 : 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.12)
                  : accentColor.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                      alpha: isDarkMode ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  f['icon'] as IconData,
                  size: 18,
                  color: isDarkMode
                      ? accentColor.withValues(alpha: 0.95)
                      : accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  f['text'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.88)
                        : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: accentColor.withValues(alpha: 0.60),
              ),
            ],
          ),
        );
      }),
    );
  }
}
