import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';

/// Generic reusable empty-state widget shown when a list has no items.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec =
        isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;
    final iconColor =
        isDark ? TColors.textDarkTertiary : TColors.textLightTertiary;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: TResponsive.pagePadding(context),
          vertical: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: TResponsive.sp(context, 72),
              height: TResponsive.sp(context, 72),
              decoration: BoxDecoration(
                color: isDark ? TColors.darkElevated : TColors.lightElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: TResponsive.sp(context, 32),
                color: iconColor,
              ),
            ),
            SizedBox(height: TResponsive.sp(context, 16)),
            Text(
              title,
              style: TextStyle(
                fontSize: TResponsive.sp(context, 16),
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: TResponsive.sp(context, 6)),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: TResponsive.sp(context, 13),
                  color: textSec,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: TResponsive.sp(context, 20)),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
