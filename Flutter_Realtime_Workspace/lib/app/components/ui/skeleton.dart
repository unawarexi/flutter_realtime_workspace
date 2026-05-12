import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class TSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const TSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = TSizes.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? TColors.darkElevated : TColors.lightElevated,
      highlightColor: isDark ? TColors.darkHover : TColors.lightHover,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton for meeting card list.
class TMeetingCardSkeleton extends StatelessWidget {
  const TMeetingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: TSizes.sm),
      child: Row(
        children: [
          TSkeleton(width: 4, height: 48, borderRadius: 2),
          SizedBox(width: TSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TSkeleton(height: 16, width: 180),
                SizedBox(height: TSizes.sm),
                TSkeleton(height: 12, width: 120),
                SizedBox(height: TSizes.sm),
                TSkeleton(height: 12, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for avatar row.
class TAvatarSkeleton extends StatelessWidget {
  final double size;
  const TAvatarSkeleton({super.key, this.size = TSizes.avatarMd});

  @override
  Widget build(BuildContext context) {
    return TSkeleton(
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }
}
