import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/integration_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/integration_provider.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';

class IntegrationSetupScreen extends ConsumerWidget {
  const IntegrationSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final intId = GoRouterState.of(context).pathParameters['integrationId'];
    final workspaceId = ref.watch(activeWorkspaceProvider)?.id ?? '';
    final intAsync = ref.watch(integrationsProvider(workspaceId));

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Integration Setup', showBack: true),
      body: intAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (integrations) {
          final intg = integrations.where((i) => i.id == intId).firstOrNull;
          if (intg == null) return const Center(child: Text('Not found'));

          return ListView(padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.md), children: [
            TCard(
              padding: EdgeInsets.all(TResponsive.sp(context, TSizes.lg)),
              child: Column(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: (intg.enabled ? TColors.success : TColors.primary).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusLg)),
                  child: Icon(Icons.extension_rounded, size: 28, color: intg.enabled ? TColors.success : TColors.primary),
                ),
                const SizedBox(height: TSizes.md),
                Text(intg.name, style: TextStyle(fontSize: TResponsive.sp(context, 20), fontWeight: FontWeight.w700, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                Padding(padding: const EdgeInsets.only(top: 4), child: Text(IntegrationUseCase.typeLabel(intg.type), textAlign: TextAlign.center, style: TextStyle(fontSize: TResponsive.sp(context, 13), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight))),
                const SizedBox(height: TSizes.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (intg.enabled ? TColors.success : TColors.neutralGray).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusFull)),
                  child: Text(intg.enabled ? 'INSTALLED' : 'NOT INSTALLED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: intg.enabled ? TColors.success : TColors.neutralGray)),
                ),
              ]),
            ),
            const SizedBox(height: TSizes.lg),

            if (intg.enabled) ...[
              TButton(
                text: 'Test Connection',
                variant: SButtonVariant.outline,
                size: SButtonSize.sm,
                prefixIcon: Icons.science_outlined,
                onPressed: () => IntegrationUseCase.testIntegration(context: context, ref: ref, id: intg.id),
              ),
              const SizedBox(height: TSizes.sm),
              TButton(
                text: 'Uninstall',
                variant: SButtonVariant.danger,
                size: SButtonSize.sm,
                prefixIcon: Icons.delete_outline,
                onPressed: IntegrationUseCase.canInstallIntegration(ref) ? () => IntegrationUseCase.uninstall(context: context, ref: ref, id: intg.id) : null,
              ),
            ] else
              TButton(
                text: 'Install',
                prefixIcon: Icons.download_rounded,
                onPressed: IntegrationUseCase.canInstallIntegration(ref) ? () => IntegrationUseCase.install(context: context, ref: ref, body: {'workspaceId': workspaceId, 'type': intg.type, 'name': intg.name}) : null,
              ),
          ]);
        },
      ),
    );
  }
}
