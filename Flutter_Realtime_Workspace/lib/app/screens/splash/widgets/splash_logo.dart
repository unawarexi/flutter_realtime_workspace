import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/image_strings.dart';

/// Central logo circle with orbiting dot-particles.
///
/// [fadeValue] ∈ [0, 1] — overall opacity.
/// [scaleValue] ∈ [0, 1] — scale entrance from BrandRevealAnim.
/// [orbitValue] ∈ [0, 1] — continuous rotation from RadarSweepAnim.
class SplashLogo extends StatelessWidget {
  final double fadeValue;
  final double scaleValue;
  final double orbitValue;
  final Color containerColor;
  final Color particleColor;
  final bool isDarkMode;

  const SplashLogo({
    super.key,
    required this.fadeValue,
    required this.scaleValue,
    required this.orbitValue,
    required this.containerColor,
    required this.particleColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: fadeValue.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scaleValue.clamp(0.0, 1.2),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow halo
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: containerColor.withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),

            // 8 orbiting particles
            for (int i = 0; i < 8; i++)
              Transform.rotate(
                angle: (orbitValue * 2 * math.pi) + (i * math.pi / 4),
                child: Transform.translate(
                  offset: const Offset(62, 0),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: particleColor.withValues(
                        alpha: isDarkMode ? 0.55 : 0.65,
                      ),
                    ),
                  ),
                ),
              ),

            // Logo container circle
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: containerColor,
                boxShadow: [
                  BoxShadow(
                    color: containerColor.withValues(alpha: 0.42),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  isDarkMode ? TImages.splashDark : TImages.splashLight,
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
