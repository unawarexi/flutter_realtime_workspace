import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Auth screen "or" divider using shared tokens.
class CustomDivider extends StatelessWidget {
  final String label;
  const CustomDivider({super.key, this.label = 'or'});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? TColors.darkBorder : TColors.lightBorder;
    final textColor = isDark ? TColors.darkMuted : TColors.lightMuted;

    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 1)),
      ],
    );
  }
}
