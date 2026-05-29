import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/billing_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);

    final plans = [
      {'id': 'free', 'name': 'Free', 'price': '\$0', 'features': ['5 members', '3 projects', '1GB storage']},
      {'id': 'starter', 'name': 'Starter', 'price': '\$12/mo', 'features': ['25 members', '15 projects', '10GB storage']},
      {'id': 'professional', 'name': 'Professional', 'price': '\$29/mo', 'features': ['100 members', 'Unlimited projects', '50GB storage', 'AI features']},
      {'id': 'enterprise', 'name': 'Enterprise', 'price': 'Custom', 'features': ['Unlimited members', 'Unlimited projects', 'Unlimited storage', 'SSO & SAML', 'Priority support']},
    ];

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Plans', showBack: true),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.md),
        itemCount: plans.length,
        separatorBuilder: (_, __) => const SizedBox(height: TSizes.md),
        itemBuilder: (_, i) {
          final p = plans[i];
          final isPopular = p['id'] == 'professional';
          return TCard(
            hasBorder: true,
            hasShadow: isPopular,
            padding: EdgeInsets.all(TResponsive.sp(context, TSizes.lg)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(p['name'] as String, style: TextStyle(fontSize: TResponsive.sp(context, 18), fontWeight: FontWeight.w700, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                if (isPopular) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusFull)),
                    child: Text('Popular', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: TColors.primary)),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Text(p['price'] as String, style: TextStyle(fontSize: TResponsive.sp(context, 24), fontWeight: FontWeight.w800, color: TColors.primary)),
              const SizedBox(height: TSizes.md),
              ...(p['features'] as List).map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: TColors.success),
                  const SizedBox(width: 8),
                  Text(f as String, style: TextStyle(fontSize: TResponsive.sp(context, 13), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                ]),
              )),
              const SizedBox(height: TSizes.md),
              TButton(
                text: 'Choose ${p['name']}',
                variant: isPopular ? SButtonVariant.primary : SButtonVariant.outline,
                size: SButtonSize.sm,
                onPressed: () => BillingUseCase.changePlan(context: context, ref: ref, planId: p['id'] as String),
              ),
            ]),
          );
        },
      ),
    );
  }
}
