import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/shapes.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';

/// Semi-transparent theme overlay + layered decorative shapes rendered
/// above the video (or gradient fallback) background.
///
/// Shapes used: [TOrbFieldPainter], [TDotGridPainter], [TCornerArcPainter],
/// [TBroadcastRingsPainter], [TNetworkArcsPainter], [TDataFlowPainter],
/// [SGrainPainter] (dark only).
class OnboardingShapeOverlay extends StatelessWidget {
  final bool isDarkMode;
  final Color accentColor;

  const OnboardingShapeOverlay({
    super.key,
    required this.isDarkMode,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned.fill(
      child: Stack(
        children: [
          // ── 1. Base theme-tinted gradient overlay ─────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [
                        const Color(0xFF0A0E1A).withValues(alpha: 0.80),
                        const Color(0xFF0A0E1A).withValues(alpha: 0.52),
                        const Color(0xFF0A0E1A).withValues(alpha: 0.90),
                      ]
                    : [
                        const Color(0xFFFFFFFF).withValues(alpha: 0.75),
                        const Color(0xFFFFFFFF).withValues(alpha: 0.52),
                        const Color(0xFFFFFFFF).withValues(alpha: 0.85),
                      ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // ── 2. Ambient orb field ───────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: TOrbFieldPainter(
                colors: [accentColor, TColors.purple],
                orbCount: 5,
                isDark: isDarkMode,
                seed: 7,
              ),
            ),
          ),

          // ── 3. Dot-grid texture ────────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: TDotGridPainter(
                dotColor: (isDarkMode ? Colors.white : TColors.primary)
                    .withValues(alpha: isDarkMode ? 0.055 : 0.045),
                spacing: 30,
                dotRadius: 1.0,
              ),
            ),
          ),

          // ── 4. Top-right corner radial arc ────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: TCornerArcPainter(
                color: accentColor,
                radius: size.width * 0.70,
                corner: CornerPosition.topRight,
              ),
            ),
          ),

          // ── 5. Bottom-left corner arc (purple accent) ─────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: TCornerArcPainter(
                color: TColors.purple,
                radius: size.width * 0.52,
                corner: CornerPosition.bottomLeft,
              ),
            ),
          ),

          // ── 6. Broadcast rings emanating from top-right ───────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: TBroadcastRingsPainter(
                color: accentColor,
                isDark: isDarkMode,
                ringCount: 5,
                corner: CornerPosition.topRight,
              ),
            ),
          ),

          // ── 7. Network arc graph ──────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: TNetworkArcsPainter(
                color: accentColor,
                isDark: isDarkMode,
                seed: 37,
                nodeCount: 8,
              ),
            ),
          ),

          // ── 8. Data-flow sinusoidal lines ─────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: TDataFlowPainter(
                color: accentColor,
                isDark: isDarkMode,
                lineCount: 5,
                phase: 0.8,
              ),
            ),
          ),

          // ── 9. Grain texture (dark mode premium finish) ───────────────────
          if (isDarkMode)
            Positioned.fill(
              child: CustomPaint(
                painter: SGrainPainter(opacity: 0.022, density: 2000),
              ),
            ),
        ],
      ),
    );
  }
}
