import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/features/home/usecases/home_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/services/google_geo_location.dart';

/// Workspace tools list and "Find Chill Spots" CTA.
class HomeWorkspaceTools extends StatelessWidget {
  const HomeWorkspaceTools({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tools = HomeUseCase.workspaceTools();

    return TWidgetAnimations.slideUp(
      duration: const Duration(milliseconds: 480),
      offsetY: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Workspace Tools', isDark: isDark),
          const SizedBox(height: TSizes.sm),
          ...List.generate(tools.length, (i) {
            final tool = tools[i];
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i < tools.length - 1 ? TSizes.xs + 2 : 0),
              child: TWidgetAnimations.fadeIn(
                delay: Duration(milliseconds: 50 * i),
                child: _ToolCard(tool: tool, isDark: isDark),
              ),
            );
          }),
          const SizedBox(height: TSizes.sm + 2),
          // ── Chill Spots CTA ───────────────────────────────────
          TWidgetAnimations.scaleIn(
            duration: const Duration(milliseconds: 360),
            child: _ChillSpotButton(isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.isDark});
  final HomeWorkspaceTool tool;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, tool.route),
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
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: TSizes.sm + 2,
            vertical: TSizes.xs,
          ),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: TColors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(TSizes.radiusSm + 1),
            ),
            child: Icon(
              tool.icon,
              size: TSizes.iconSm + 2,
              color: isDark ? TColors.blue400 : TColors.primary,
            ),
          ),
          title: Text(
            tool.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? TColors.textDark : TColors.textLight,
            ),
          ),
          subtitle: Text(
            tool.subtitle,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isDark ? TColors.darkMuted : TColors.lightMuted,
            ),
          ),
          trailing: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isDark ? TColors.darkBorder : TColors.lightElevated,
              borderRadius: BorderRadius.circular(TSizes.radiusSm - 1),
            ),
            child: Icon(
              TIcons.back,
              size: TSizes.iconSm - 4,
              color: isDark ? TColors.darkMuted : TColors.lightMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChillSpotButton extends StatelessWidget {
  const _ChillSpotButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GoogleMapScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: TSizes.sm + 2, horizontal: TSizes.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [TColors.blue900, TColors.primary, TColors.blue700],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          boxShadow: [
            BoxShadow(
              color: TColors.primary.withValues(alpha: 0.26),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: TSizes.iconSm + 2,
            ),
            SizedBox(width: TSizes.sm - 2),
            Text(
              'Find Chill Spots Nearby',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: isDark ? TColors.textDark : TColors.textLight,
      ),
    );
  }
}
