import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/integration_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/integration_provider.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';

class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});
  @override
  ConsumerState<IntegrationsScreen> createState() => _State();
}

class _State extends ConsumerState<IntegrationsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final workspaceId = ref.watch(activeWorkspaceProvider)?.id ?? '';
    final intAsync = ref.watch(integrationsProvider(workspaceId));

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Integrations', showBack: true),
      body: intAsync.when(
        loading: () => Padding(padding: EdgeInsets.all(hPad), child: Column(children: List.generate(4, (_) => const Padding(padding: EdgeInsets.only(bottom: TSizes.sm), child: TSkeleton(height: 72))))),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (integrations) {
          final filtered = IntegrationUseCase.searchIntegrations(integrations, _query);
          final installed = filtered.where((i) => i.enabled).toList();
          final available = filtered.where((i) => !i.enabled).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(integrationsProvider(workspaceId)),
            child: ListView(padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.md), children: [
              TSearchBar(hint: 'Search integrations...', onChanged: (q) => setState(() => _query = q)),
              const SizedBox(height: TSizes.lg),

              if (installed.isNotEmpty) ...[
                _label(context, 'INSTALLED', isDark, installed.length),
                const SizedBox(height: TSizes.sm),
                ...installed.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: TSizes.sm),
                  child: TCard(
                    hasBorder: true,
                    onTap: () => context.go('/integrations/${i.id}'),
                    padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: TColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusMd)),
                        child: const Icon(Icons.extension_outlined, size: 20, color: TColors.success),
                      ),
                      const SizedBox(width: TSizes.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(i.name, style: TextStyle(fontSize: TResponsive.sp(context, 14), fontWeight: FontWeight.w600, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                        Text(IntegrationUseCase.typeLabel(i.type), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: TResponsive.sp(context, 12), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                      ])),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: TColors.success)),
                    ]),
                  ),
                )),
                const SizedBox(height: TSizes.md),
              ],

              if (available.isNotEmpty) ...[
                _label(context, 'AVAILABLE', isDark, available.length),
                const SizedBox(height: TSizes.sm),
                ...available.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: TSizes.sm),
                  child: TCard(
                    hasBorder: true,
                    onTap: IntegrationUseCase.canInstallIntegration(ref) ? () => context.go('/integrations/${i.id}') : null,
                    padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: TColors.neutralGray.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusMd)),
                        child: Icon(Icons.extension_outlined, size: 20, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                      ),
                      const SizedBox(width: TSizes.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(i.name, style: TextStyle(fontSize: TResponsive.sp(context, 14), fontWeight: FontWeight.w500, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                        Text(IntegrationUseCase.typeLabel(i.type), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: TResponsive.sp(context, 12), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                      ])),
                      const Icon(Icons.add_circle_outline, size: 20, color: TColors.primary),
                    ]),
                  ),
                )),
              ],
            ]),
          );
        },
      ),
    );
  }

  Widget _label(BuildContext context, String text, bool isDark, int count) => Row(children: [
    Text(text, style: TextStyle(fontSize: TResponsive.sp(context, 11), fontWeight: FontWeight.w600, letterSpacing: 1.2, color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
    const SizedBox(width: 6),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusFull)),
      child: Text('$count', style: TextStyle(fontSize: TResponsive.sp(context, 10), fontWeight: FontWeight.w600, color: TColors.primary)),
    ),
  ]);
}
