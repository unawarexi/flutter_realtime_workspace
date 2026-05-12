import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/bg_patterns.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/user_information.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/image_strings.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class OrganisationOptionsScreen extends StatelessWidget {
  const OrganisationOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBg : TColors.lightBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: TOrbFieldPainter(
                colors: [TColors.primary, TColors.blue700],
                orbCount: 4,
                isDark: isDark,
                seed: 5,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: TDotGridPainter(
                dotColor: (isDark ? TColors.darkBorder : TColors.lightBorder)
                    .withValues(alpha: 0.5),
                spacing: 28,
                dotRadius: 1.0,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: TResponsive.maxContentWidth(context),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: hPad, vertical: TSizes.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      TWidgetAnimations.scaleIn(
                        child: Image.asset(
                          isDark ? TImages.darkEmblem : TImages.lightEmblem,
                          height: TResponsive.sp(context, 100, tabletSize: 120),
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: TSizes.xl),
                      TWidgetAnimations.slideUp(
                        child: Text(
                          'Welcome!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color:
                                    isDark ? TColors.textDark : TColors.textLight,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: TSizes.sm),
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 80),
                        child: Text(
                          'Get started by creating a new organisation\nor joining an existing one.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? TColors.textSecondaryDark
                                : TColors.textSecondaryLight,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: TSizes.xxl),
                      // Create org button
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 120),
                        child: TButton(
                          text: 'Create New Organisation',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserInformationScreen(
                                  mode: UserInfoMode.create),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.sm + 4),
                      // Join org button
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 150),
                        child: TButton(
                          text: 'Join an Existing Organisation',
                          variant: SButtonVariant.outline,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserInformationScreen(
                                  mode: UserInfoMode.join),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
