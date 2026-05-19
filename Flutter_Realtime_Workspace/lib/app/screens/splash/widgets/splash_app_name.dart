import 'package:flutter/material.dart';

/// App name + tagline text block, fades in with the logo.
///
/// [fadeValue] ∈ [0, 1] — driven by BrandRevealAnim.fade.
class SplashAppName extends StatelessWidget {
  final double fadeValue;
  final Color textColor;

  const SplashAppName({
    super.key,
    required this.fadeValue,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: fadeValue.clamp(0.0, 1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TeamSpot',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Workspace',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withValues(alpha: 0.65),
              letterSpacing: 1.8,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
