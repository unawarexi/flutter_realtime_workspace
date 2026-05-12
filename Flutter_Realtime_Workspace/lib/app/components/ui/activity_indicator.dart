import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';

/// Hybrid activity indicator — uses CupertinoActivityIndicator for a premium
/// iOS-style spinner, with Material fallback for branding when needed.
class TActivityIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final bool adaptive;

  const TActivityIndicator({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.5,
    this.adaptive = true,
  });

  @override
  Widget build(BuildContext context) {
    if (adaptive) {
      return CupertinoActivityIndicator(
        radius: size / 2,
        color: color ?? TColors.primary,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation(
          color ?? TColors.primary,
        ),
      ),
    );
  }
}

/// Full-screen loading overlay with Cupertino spinner.
class TLoadingOverlay extends StatelessWidget {
  final String? message;

  const TLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? TColors.textDarkSecondary
                        : TColors.textLightSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
