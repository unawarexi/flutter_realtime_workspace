import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Bottom bar: smooth page indicator, progress counter, and nav buttons.
///
/// Fades in over the page background from transparent to opaque.
/// Buttons use [TButton] — outline for back, custom gradient for next
/// since the accent color changes per page.
class OnboardingBottomBar extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final PageController pageController;
  final bool isDarkMode;
  final Color accentColor;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const OnboardingBottomBar({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.pageController,
    required this.isDarkMode,
    required this.accentColor,
    required this.onNext,
    required this.onPrev,
  });

  bool get _isLast => currentPage == pageCount - 1;

  @override
  Widget build(BuildContext context) {
    final bgBase =
        isDarkMode ? TColors.darkBg : const Color(0xFFF8FAFC);

    return Container(
      padding: EdgeInsets.fromLTRB(
        TSizes.pagePadding,
        TSizes.sm,
        TSizes.pagePadding,
        MediaQuery.of(context).padding.bottom + TSizes.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bgBase.withValues(alpha: 0.0),
            bgBase.withValues(alpha: 0.88),
            bgBase,
          ],
          stops: const [0.0, 0.48, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Page indicator ─────────────────────────────────────────────────
          SmoothPageIndicator(
            controller: pageController,
            count: pageCount,
            effect: ExpandingDotsEffect(
              dotWidth: TSizes.sm,
              dotHeight: TSizes.sm,
              expansionFactor: 4,
              spacing: TSizes.xs + 2,
              dotColor: (isDarkMode ? Colors.white : TColors.primary)
                  .withValues(alpha: 0.22),
              activeDotColor: accentColor,
            ),
          ),

          SizedBox(height: TSizes.xs),

          // ── Progress counter ───────────────────────────────────────────────
          Text(
            '${currentPage + 1} / $pageCount',
            style: TextStyle(
              fontSize: TSizes.fontSizeSM,
              color: (isDarkMode ? Colors.white : TColors.textSecondaryLight)
                  .withValues(alpha: 0.50),
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: TSizes.md),

          // ── Navigation buttons ─────────────────────────────────────────────
          Row(
            children: [
              if (currentPage > 0) ...[
                Expanded(
                  child: TButton(
                    text: 'Back',
                    variant: SButtonVariant.outline,
                    size: SButtonSize.md,
                    prefixIcon: Icons.arrow_back_rounded,
                    onPressed: onPrev,
                  ),
                ),
                SizedBox(width: TSizes.sm),
              ],
              Expanded(
                child: _AccentButton(
                  label: _isLast ? 'Get Started' : 'Continue',
                  isLast: _isLast,
                  accentColor: accentColor,
                  onPressed: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Accent-colored primary button (gradient uses per-page accentColor) ───────

class _AccentButton extends StatelessWidget {
  final String label;
  final bool isLast;
  final Color accentColor;
  final VoidCallback onPressed;

  const _AccentButton({
    required this.label,
    required this.isLast,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final darker = Color.lerp(accentColor, Colors.black, 0.18)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        gradient: LinearGradient(
          colors: [accentColor, darker],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          minimumSize: Size(double.infinity, TSizes.buttonHeightMd),
          padding: EdgeInsets.symmetric(
            horizontal: TSizes.md,
            vertical: TSizes.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.radiusMd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: TSizes.fontSizeMD - 1,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(width: TSizes.xs + 2),
            Icon(
              isLast
                  ? Icons.rocket_launch_rounded
                  : Icons.arrow_forward_rounded,
              size: TSizes.iconSm + 1,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
