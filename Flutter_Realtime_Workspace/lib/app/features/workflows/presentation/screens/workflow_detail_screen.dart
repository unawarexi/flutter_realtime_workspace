import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/workflows/usecases/workflow_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/workflow_provider.dart';

class WorkflowDetailScreen extends ConsumerWidget {
  const WorkflowDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final wfId = GoRouterState.of(context).pathParameters['workflowId'];
    final wfAsync = ref.watch(workflowsProvider);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Workflow', showBack: true),
      body: wfAsync.when(
        loading: () => Padding(padding: EdgeInsets.all(hPad), child: Column(children: List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: TSizes.sm), child: TSkeleton(height: 60))))),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (workflows) {
          final wf = workflows.where((w) => w.id == wfId).firstOrNull;
          if (wf == null) return const Center(child: Text('Workflow not found'));

          return ListView(padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.md), children: [
            // Header
            TCard(
              padding: EdgeInsets.all(TResponsive.sp(context, TSizes.lg)),
              child: Column(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: (wf.enabled ? TColors.success : TColors.neutralGray).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusLg)),
                  child: Icon(Icons.account_tree_rounded, size: 28, color: wf.enabled ? TColors.success : TColors.neutralGray),
                ),
                const SizedBox(height: TSizes.md),
                Text(wf.name, textAlign: TextAlign.center, style: TextStyle(fontSize: TResponsive.sp(context, 18), fontWeight: FontWeight.w700, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                if (wf.description != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(wf.description!, textAlign: TextAlign.center, style: TextStyle(fontSize: TResponsive.sp(context, 13), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight))),
                const SizedBox(height: TSizes.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (wf.enabled ? TColors.success : TColors.neutralGray).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusFull)),
                  child: Text(wf.enabled ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: wf.enabled ? TColors.success : TColors.neutralGray, letterSpacing: 0.8)),
                ),
              ]),
            ),
            const SizedBox(height: TSizes.lg),

            // Details
            TCard(hasBorder: true, child: Column(children: [
              _row(context, 'Trigger', wf.trigger != null ? WorkflowUseCase.triggerLabel(wf.trigger!.type) : '–', isDark),
              Divider(height: 1, color: isDark ? TColors.darkBorder : TColors.lightBorder),
              _row(context, 'Executions', '${wf.executionCount}', isDark),
              Divider(height: 1, color: isDark ? TColors.darkBorder : TColors.lightBorder),
              _row(context, 'Last Run', wf.lastExecutedAt != null ? '${wf.lastExecutedAt!.day}/${wf.lastExecutedAt!.month}/${wf.lastExecutedAt!.year}' : 'Never', isDark),
              Divider(height: 1, color: isDark ? TColors.darkBorder : TColors.lightBorder),
              _row(context, 'Conditions', '${wf.conditions.length}', isDark),
              Divider(height: 1, color: isDark ? TColors.darkBorder : TColors.lightBorder),
              _row(context, 'Actions', '${wf.actions.length}', isDark),
            ])),
            const SizedBox(height: TSizes.lg),

            // Actions
            Row(children: [
              Expanded(child: TButton(
                text: wf.enabled ? 'Disable' : 'Enable',
                variant: wf.enabled ? SButtonVariant.outline : SButtonVariant.primary,
                size: SButtonSize.sm,
                prefixIcon: wf.enabled ? Icons.pause_rounded : Icons.play_arrow_rounded,
                onPressed: WorkflowUseCase.canEditWorkflow(ref) ? () => WorkflowUseCase.toggleWorkflow(context: context, ref: ref, id: wf.id) : null,
              )),
              const SizedBox(width: TSizes.sm),
              Expanded(child: TButton(
                text: 'Test Run',
                variant: SButtonVariant.secondary,
                size: SButtonSize.sm,
                prefixIcon: Icons.science_outlined,
                onPressed: () => WorkflowUseCase.testWorkflow(context: context, ref: ref, id: wf.id),
              )),
            ]),
            const SizedBox(height: TSizes.xxl),
          ]);
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: TResponsive.sp(context, 13), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
      Text(value, style: TextStyle(fontSize: TResponsive.sp(context, 13), fontWeight: FontWeight.w500, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
    ]),
  );
}
