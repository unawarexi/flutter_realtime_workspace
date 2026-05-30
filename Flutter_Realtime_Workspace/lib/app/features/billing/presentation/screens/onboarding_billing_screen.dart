import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/shapes/bg_patterns.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/billing_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/image_strings.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Paywall shown once during onboarding — right after user fills in their
/// profile (UserInformationScreen) and before they reach the home screen.
///
/// Selecting any plan (including Free) leads to /home.  All plan logic is
/// delegated to [BillingUseCase] so this screen stays presentational.
class OnboardingBillingScreen extends ConsumerWidget {
  const OnboardingBillingScreen({super.key});

  static const _plans = [
    {
      'id': 'free',
      'name': 'Free',
      'price': '\$0',
      'period': 'forever',
      'badge': null,
      'features': [
        '5 members',
        '3 projects',
        '1 GB storage',
        'Basic task management',
      ],
    },
    {
      'id': 'starter',
      'name': 'Starter',
      'price': '\$12',
      'period': '/month',
      'badge': null,
      'features': [
        '25 members',
        '15 projects',
        '10 GB storage',
        'Time tracking',
        'Priority inbox',
      ],
    },
    {
      'id': 'professional',
      'name': 'Professional',
      'price': '\$29',
      'period': '/month',
      'badge': 'Most Popular',
      'features': [
        '100 members',
        'Unlimited projects',
        '50 GB storage',
        'AI features',
        'Advanced analytics',
        'Custom workflows',
      ],
    },
    {
      'id': 'enterprise',
      'name': 'Enterprise',
      'price': 'Custom',
      'period': '',
      'badge': null,
      'features': [
        'Unlimited everything',
        'SSO & SAML',
        'Dedicated support',
        'SLA guarantee',
        'On-prem option',
      ],
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.darkBg : TColors.lightBg,
      body: Stack(
        children: [
          // Background orbs
          Positioned.fill(
            child: CustomPaint(
              painter: TOrbFieldPainter(
                colors: [TColors.primary, TColors.blue700],
                orbCount: 5,
                isDark: isDark,
                seed: 77,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: TDotGridPainter(
                dotColor: (isDark ? TColors.darkBorder : TColors.lightBorder)
                    .withValues(alpha: 0.4),
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
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: TSizes.xl,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Logo
                          TWidgetAnimations.fadeIn(
                            child: Center(
                              child: Image.asset(
                                isDark
                                    ? TImages.darkEmblem
                                    : TImages.lightEmblem,
                                height: 44,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: TSizes.lg),

                          // Headline
                          TWidgetAnimations.slideUp(
                            child: Text(
                              'Choose Your Plan',
                              textAlign: TextAlign.center,
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
                            delay: const Duration(milliseconds: 100),
                            child: Text(
                              'Start free and upgrade anytime. No credit card required.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? TColors.textSecondaryDark
                                    : TColors.textSecondaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(height: TSizes.xl),

                          // Plan cards
                          ..._plans.asMap().entries.map((entry) {
                            final delay =
                                Duration(milliseconds: 140 + entry.key * 80);
                            return TWidgetAnimations.fadeIn(
                              delay: delay,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: TSizes.md),
                                child: _PlanCard(
                                  plan: entry.value,
                                  isDark: isDark,
                                  onSelect: () => _onSelectPlan(
                                    context,
                                    ref,
                                    entry.value['id'] as String,
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: TSizes.sm),

                          // Skip / free tier shortcut
                          TWidgetAnimations.fadeIn(
                            delay: const Duration(milliseconds: 500),
                            child: Center(
                              child: TextButton(
                                onPressed: () => context.go('/home'),
                                child: Text(
                                  'Continue with Free',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? TColors.textSecondaryDark
                                        : TColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: TSizes.lg),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSelectPlan(
    BuildContext context,
    WidgetRef ref,
    String planId,
  ) async {
    if (planId == 'free') {
      // Free plan — no backend call needed, just proceed.
      if (context.mounted) context.go('/home');
      return;
    }
    // For paid plans delegate to BillingUseCase (handles checkout + navigation).
    await BillingUseCase.changePlan(
      context: context,
      ref: ref,
      planId: planId,
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, Object?> plan;
  final bool isDark;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isPopular = plan['badge'] != null;
    final features = plan['features'] as List;

    return TCard(
      hasBorder: true,
      hasShadow: isPopular,
      padding: EdgeInsets.all(TResponsive.sp(context, TSizes.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan name + badge
          Row(
            children: [
              Text(
                plan['name'] as String,
                style: TextStyle(
                  fontSize: TResponsive.sp(context, 17),
                  fontWeight: FontWeight.w700,
                  color: isDark ? TColors.textDark : TColors.textLight,
                ),
              ),
              if (isPopular) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: TColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(TSizes.radiusFull),
                  ),
                  child: Text(
                    plan['badge'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: TColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Price
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: plan['price'] as String,
                  style: TextStyle(
                    fontSize: TResponsive.sp(context, 26),
                    fontWeight: FontWeight.w800,
                    color: TColors.primary,
                  ),
                ),
                if ((plan['period'] as String).isNotEmpty)
                  TextSpan(
                    text: plan['period'] as String,
                    style: TextStyle(
                      fontSize: TResponsive.sp(context, 13),
                      color: isDark
                          ? TColors.textSecondaryDark
                          : TColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TSizes.md),

          // Features
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: TColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f as String,
                      style: TextStyle(
                        fontSize: TResponsive.sp(context, 13),
                        color: isDark
                            ? TColors.textSecondaryDark
                            : TColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TSizes.md),

          // CTA
          TButton(
            text: plan['id'] == 'free'
                ? 'Start Free'
                : 'Choose ${plan['name']}',
            variant:
                isPopular ? SButtonVariant.primary : SButtonVariant.outline,
            size: SButtonSize.sm,
            onPressed: onSelect,
          ),
        ],
      ),
    );
  }
}
