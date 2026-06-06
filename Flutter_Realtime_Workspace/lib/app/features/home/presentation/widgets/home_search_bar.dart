import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Decorated search bar with filter icon.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TWidgetAnimations.fadeIn(
      delay: const Duration(milliseconds: 80),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? TColors.darkCard : TColors.lightSurface,
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          border: Border.all(
            color: isDark ? TColors.darkBorder : TColors.lightBorder,
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(TSizes.xs),
          child: TSearchBar(
            hint: 'Search projects, files or people…',
          ),
        ),
      ),
    );
  }
}
