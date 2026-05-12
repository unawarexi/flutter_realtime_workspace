import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Reusable social-provider sign-in button.
/// Uses shared design tokens (TColors / TSizes) — no raw magic values.
class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
    this.disabled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget icon;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = disabled
        ? (isDark ? TColors.darkCard : TColors.lightElevated)
        : (isDark ? TColors.darkCard : TColors.lightSurface);
    final fg = disabled
        ? (isDark ? TColors.darkMuted : TColors.lightMuted)
        : (isDark ? TColors.textDark : TColors.textLight);
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;

    return SizedBox(
      width: double.infinity,
      height: TSizes.buttonHeightMd,
      child: OutlinedButton.icon(
        onPressed: disabled ? null : onPressed,
        icon: icon,
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: fg,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: BorderSide(color: border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
        ),
      ),
    );
  }
}
