import 'package:flutter/material.dart';

/// Animated radar-ring background layer for the splash screen.
///
/// [sweepValue] ∈ [0, 1] — drives the expanding ring expansion.
/// [pulseValue] ∈ [0.8, 1.2] — drives the pulse ring scale.
class SplashBackground extends StatelessWidget {
  final Color ringColor;
  final double sweepValue;
  final double pulseValue;
  final bool isDarkMode;

  const SplashBackground({
    super.key,
    required this.ringColor,
    required this.sweepValue,
    required this.pulseValue,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final bg1 = isDarkMode ? const Color(0xFF0A0E1A) : const Color(0xFFEFF6FF);
    final bg2 = isDarkMode ? const Color(0xFF0D1423) : const Color(0xFFDBEAFE);

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [bg1, bg2, bg1],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Three expanding radar rings with staggered offsets
          for (int i = 0; i < 3; i++)
            Transform.scale(
              scale: 0.5 + (sweepValue + i * 0.33) % 1.0 * 1.5,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ringColor.withValues(
                      alpha:
                          (1.0 - (sweepValue + i * 0.33) % 1.0) *
                          (isDarkMode ? 0.28 : 0.32),
                    ),
                    width: 2.0,
                  ),
                ),
              ),
            ),

          // Pulse ring around the logo area
          Transform.scale(
            scale: pulseValue,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ringColor.withValues(
                    alpha: isDarkMode ? 0.18 : 0.22,
                  ),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
