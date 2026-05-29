import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';

/// Generic labeled meta-info row used in detail screens.
/// Shows [icon] + [label] on left, [value] on right.
/// Set [isLast] to hide the bottom divider.
/// Set [highlight] to color the value in [TColors.error].
class MetaInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  final bool highlight;

  const MetaInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec =
        isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    final labelSize = TResponsive.sp(context, 12);
    final valueSize = TResponsive.sp(context, 13);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon,
                  size: TResponsive.sp(context, 15), color: textSec),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(fontSize: labelSize, color: textSec)),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w600,
                  color: highlight ? TColors.error : textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: border),
      ],
    );
  }
}
