import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/login_password_fields.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/onboarding_divider.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/social_login_button.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/auth_usecase.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/bg_patterns.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/decorative_painters.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/image_strings.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class Authentication extends ConsumerWidget {
  const Authentication({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBg : TColors.lightBg,
      body: Stack(
        children: [
          // Ambient background orbs
          Positioned.fill(
            child: CustomPaint(
              painter: TOrbFieldPainter(
                colors: [TColors.primary, TColors.blue700],
                orbCount: 4,
                isDark: isDark,
                seed: 7,
              ),
            ),
          ),
          // Subtle dot grid
          Positioned.fill(
            child: CustomPaint(
              painter: TDotGridPainter(
                dotColor: (isDark ? TColors.darkBorder : TColors.lightBorder)
                    .withValues(alpha: 0.6),
                spacing: 28,
                dotRadius: 1.0,
              ),
            ),
          ),
          // Accent swoosh at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(TResponsive.width(context), 200),
              painter: TBroadcastRingsPainter(
                color: TColors.primary,
                isDark: isDark,
                corner: CornerPosition.topLeft,
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
                    horizontal: hPad,
                    vertical: TSizes.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      TWidgetAnimations.scaleIn(
                        child: Center(
                          child: Image.asset(
                            isDark ? TImages.darkEmblem : TImages.lightEmblem,
                            height: TResponsive.sp(context, 60,
                                tabletSize: 80, desktopSize: 96),
                            width: 130,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.md),
                      // Heading
                      TWidgetAnimations.slideUp(
                        child: Text(
                          'Welcome back',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? TColors.textDark
                                    : TColors.textLight,
                              ),
                        ),
                      ),
                      const SizedBox(height: TSizes.xs),
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 80),
                        child: Text(
                          'Sign in to continue to TeamSpot.',
                          style: TextStyle(
                            fontSize: TResponsive.sp(context, 13),
                            color: isDark
                                ? TColors.textSecondaryDark
                                : TColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.lg),
                      // Email + password form
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 120),
                        child: const PasswordAuthentication(),
                      ),
                      const SizedBox(height: TSizes.md),
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 160),
                        child: const CustomDivider(),
                      ),
                      const SizedBox(height: TSizes.md),
                      // Social buttons
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 200),
                        child: SocialLoginButton(
                          label: 'Continue with Google',
                          icon: Image.asset(TImages.googleIcon,
                              width: 20, height: 20),
                          onPressed: () => AuthUseCase.signInWithGoogle(
                            context: context,
                            ref: ref,
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.sm),
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 230),
                        child: SocialLoginButton(
                          label: 'Continue with GitHub',
                          icon: Image.asset(TImages.githubIcon,
                              width: 20, height: 20),
                          onPressed: () => AuthUseCase.signInWithGithub(
                            context: context,
                            ref: ref,
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.sm),
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 260),
                        child: SocialLoginButton(
                          label: 'Microsoft  (Coming soon)',
                          icon: const Icon(TIcons.microsoft, size: 20),
                          onPressed: () {},
                          disabled: true,
                        ),
                      ),
                      const SizedBox(height: TSizes.xl),
                      // Sign-up link
                      TWidgetAnimations.fadeIn(
                        delay: const Duration(milliseconds: 300),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Don't have an account?  ",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? TColors.textSecondaryDark
                                      : TColors.textSecondaryLight,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/signup'),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: TColors.primary,
                                  ),
                                ),
                              ),
                            ],
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
