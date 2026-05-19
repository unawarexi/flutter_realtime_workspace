import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/image_strings.dart';

/// Top strip: app logo badge on the left, skip button on the right.
/// Both use a frosted-glass surface that adapts to dark/light mode.
class OnboardingTopBar extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onSkip;

  const OnboardingTopBar({
    super.key,
    required this.isDarkMode,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceBg = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.78);
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.12)
        : TColors.borderLight.withValues(alpha: 0.55);
    final textColor =
        isDarkMode ? Colors.white : TColors.textPrimaryLight;
    final skipColor =
        isDarkMode ? Colors.white70 : TColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── App badge ──────────────────────────────────────────────────────
          _GlassBadge(
            bg: surfaceBg,
            border: borderColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  isDarkMode ? TImages.darkEmblem : TImages.lightEmblem,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 7),
                Text(
                  'TeamSpot',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // ── Skip button ────────────────────────────────────────────────────
          GestureDetector(
            onTap: onSkip,
            child: _GlassBadge(
              bg: surfaceBg,
              border: borderColor,
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: skipColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final Color bg;
  final Color border;
  final Widget child;

  const _GlassBadge({
    required this.bg,
    required this.border,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 1),
      ),
      child: child,
    );
  }
}
