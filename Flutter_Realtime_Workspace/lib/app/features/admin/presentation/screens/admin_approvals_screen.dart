import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/admin_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/store/admin_provider.dart';

class AdminApprovalsScreen extends ConsumerWidget {
  const AdminApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = THelperFunctions.isDarkMode(context);
    final hPad = TResponsive.pagePadding(context);
    final tenantsAsync = ref.watch(adminTenantsProvider);
    final canApprove = AdminUseCase.canAccessAdmin(ref);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Pending Approvals', showBack: true),
      body: tenantsAsync.when(
        loading: () => Padding(
          padding: EdgeInsets.all(hPad),
          child: Column(children: List.generate(4, (_) => const Padding(
            padding: EdgeInsets.only(bottom: TSizes.md),
            child: TSkeleton(height: 100),
          ))),
        ),
        error: (_, __) => const Center(child: Text('Failed to load approvals')),
        data: (tenants) {
          final pending = tenants.where((t) => t['status'] == 'pending' || t['status'] == 'inactive').toList();

          if (pending.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: TColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.tick_circle, size: 32, color: TColors.success),
              ),
              const SizedBox(height: TSizes.md),
              Text('All caught up!', style: TextStyle(
                fontSize: TResponsive.sp(context, 18),
                fontWeight: FontWeight.w700,
                color: isDark ? TColors.textDark : TColors.textLight,
              )),
              const SizedBox(height: 6),
              Text('No pending approvals at this time.', style: TextStyle(
                fontSize: TResponsive.sp(context, 14),
                color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
              )),
            ]));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminTenantsProvider),
            child: ListView.separated(
              padding: EdgeInsets.all(hPad),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: TSizes.md),
              itemBuilder: (_, i) {
                final t = pending[i];
                return TCard(
                  hasBorder: true,
                  hasShadow: false,
                  padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: TColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(TSizes.radiusMd),
                        ),
                        child: const Icon(Iconsax.building, size: 22, color: TColors.primary),
                      ),
                      const SizedBox(width: TSizes.sm),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t['name'] as String? ?? 'Unnamed Tenant', style: TextStyle(
                          fontSize: TResponsive.sp(context, 15),
                          fontWeight: FontWeight.w700,
                          color: isDark ? TColors.textDark : TColors.textLight,
                        )),
                        Text(t['domain'] as String? ?? '', style: TextStyle(
                          fontSize: TResponsive.sp(context, 12),
                          color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
                        )),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: TColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(TSizes.radiusFull),
                        ),
                        child: Text('Pending', style: TextStyle(
                          fontSize: TResponsive.sp(context, 11),
                          fontWeight: FontWeight.w600,
                          color: TColors.warning,
                        )),
                      ),
                    ]),
                    if (t['email'] != null || t['plan'] != null) ...[
                      const SizedBox(height: TSizes.sm),
                      const Divider(height: 1),
                      const SizedBox(height: TSizes.sm),
                      Row(children: [
                        if (t['email'] != null) Expanded(child: _InfoItem(
                          icon: Iconsax.sms,
                          label: t['email'] as String,
                          isDark: isDark,
                        )),
                        if (t['plan'] != null) _InfoItem(
                          icon: Iconsax.crown,
                          label: t['plan'] as String,
                          isDark: isDark,
                        ),
                      ]),
                    ],
                    if (canApprove) ...[
                      const SizedBox(height: TSizes.md),
                      Row(children: [
                        Expanded(child: TButton(
                          text: 'Reject',
                          variant: SButtonVariant.outline,
                          onPressed: () => AdminUseCase.updateTenantStatus(
                            context: context, ref: ref,
                            tenantId: t['_id'] as String? ?? t['id'] as String? ?? '',
                            status: 'suspended',
                          ),
                        )),
                        const SizedBox(width: TSizes.sm),
                        Expanded(child: TButton(
                          text: 'Approve',
                          onPressed: () => AdminUseCase.updateTenantStatus(
                            context: context, ref: ref,
                            tenantId: t['_id'] as String? ?? t['id'] as String? ?? '',
                            status: 'active',
                          ),
                        )),
                      ]),
                    ],
                  ]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _InfoItem({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: isDark ? TColors.darkMuted : TColors.lightMuted),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(
        fontSize: TResponsive.sp(context, 12),
        color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
      )),
    ]);
  }
}
