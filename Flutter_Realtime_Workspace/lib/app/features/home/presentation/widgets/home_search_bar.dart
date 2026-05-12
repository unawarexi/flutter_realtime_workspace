import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
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
              color: (isDark ? Colors.black : Colors.grey)
                  .withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? TColors.textDark : TColors.textLight,
          ),
          decoration: InputDecoration(
            hintText: 'Search projects, files or people…',
            hintStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? TColors.darkMuted : TColors.lightMuted,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(TSizes.sm),
              child: Icon(
                TIcons.search,
                size: TSizes.iconSm + 2,
                color: isDark ? TColors.blue400 : TColors.primary,
              ),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.all(TSizes.xs),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDark ? TColors.darkBorder : TColors.lightElevated,
                  borderRadius: BorderRadius.circular(TSizes.radiusSm),
                ),
                child: Icon(
                  TIcons.filter,
                  size: TSizes.iconSm - 2,
                  color: isDark
                      ? TColors.textSecondaryDark
                      : TColors.textSecondaryLight,
                ),
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: TSizes.sm + 2,
              horizontal: TSizes.sm,
            ),
          ),
        ),
      ),
    );
  }
}
