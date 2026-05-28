import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/billing/usecases/billing_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/billing_provider.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Billing', showBack: true),
      body: subAsync.when(
        loading: () => Padding(padding: EdgeInsets.all(hPad), child: Column(children: List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: TSizes.sm), child: TSkeleton(height: 80))))),
        error: (_, __) => const Center(child: Text('Failed to load billing info')),
        data: (sub) {
          return ListView(padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.md), children: [
            // Plan card
            TCard(
              padding: EdgeInsets.all(TResponsive.sp(context, TSizes.lg)),
              child: Column(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusLg)),
                  child: const Icon(Icons.credit_card_rounded, size: 28, color: TColors.primary),
                ),
                const SizedBox(height: TSizes.md),
                Text(sub != null ? BillingUseCase.planLabel(sub.plan) : 'Free', style: TextStyle(fontSize: TResponsive.sp(context, 22), fontWeight: FontWeight.w700, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                const SizedBox(height: 4),
                if (sub != null) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _statusColor(sub.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusFull)),
                  child: Text(BillingUseCase.statusLabel(sub.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(sub.status))),
                ),
              ]),
            ),
            const SizedBox(height: TSizes.lg),

            TButton(
              text: 'Manage Subscription',
              variant: SButtonVariant.outline,
              prefixIcon: Icons.settings_outlined,
              onPressed: () => context.go('/billing/subscription'),
            ),
            const SizedBox(height: TSizes.lg),

            // Invoice list placeholder
            Text('INVOICES', style: TextStyle(fontSize: TResponsive.sp(context, 11), fontWeight: FontWeight.w600, letterSpacing: 1.2, color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
            const SizedBox(height: TSizes.sm),
            TCard(hasBorder: true, child: Center(child: Padding(
              padding: const EdgeInsets.all(TSizes.lg),
              child: Column(children: [
                Icon(Icons.receipt_long_outlined, size: 36, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                const SizedBox(height: TSizes.sm),
                Text('No invoices yet', style: TextStyle(color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
              ]),
            ))),
            const SizedBox(height: TSizes.xxl),
          ]);
        },
      ),
    );
  }

  Color _statusColor(String s) => switch (s) { 'active' => TColors.success, 'trialing' => TColors.info, 'cancelled' => TColors.error, 'past_due' => TColors.warning, _ => TColors.neutralGray };
}
