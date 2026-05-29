import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/workflow_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/workflow_provider.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';

class WorkflowsScreen extends ConsumerStatefulWidget {
  const WorkflowsScreen({super.key});
  @override
  ConsumerState<WorkflowsScreen> createState() => _State();
}

class _State extends ConsumerState<WorkflowsScreen> {
  String _query = '';
  bool _activeOnly = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final workspaceId = ref.watch(activeWorkspaceProvider)?.id;
    final wfAsync = ref.watch(workflowsProvider(workspaceId ?? ''));
    final canCreate = WorkflowUseCase.canCreateWorkflow(ref);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: SAppBar(title: 'Workflows', showBack: true, actions: [
        if (canCreate) IconButton(onPressed: () => context.go('/workflows/create'), icon: const Icon(Icons.add_rounded)),
      ]),
      body: wfAsync.when(
        loading: () => Padding(padding: EdgeInsets.all(hPad), child: Column(children: List.generate(4, (_) => const Padding(padding: EdgeInsets.only(bottom: TSizes.sm), child: TSkeleton(height: 72))))),
        error: (_, __) => const Center(child: Text('Failed to load workflows')),
        data: (workflows) {
          var list = WorkflowUseCase.searchWorkflows(workflows, _query);
          if (_activeOnly) list = WorkflowUseCase.filterActive(list);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(workflowsProvider(workspaceId ?? '')),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.sm),
                  sliver: SliverToBoxAdapter(child: TSearchBar(hint: 'Search workflows...', onChanged: (q) => setState(() => _query = q))),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text('${list.length} workflow${list.length == 1 ? '' : 's'}', style: TextStyle(fontSize: TResponsive.sp(context, 12), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                        const Spacer(),
                        FilterChip(
                          label: const Text('Active only'),
                          selected: _activeOnly,
                          onSelected: (v) => setState(() => _activeOnly = v),
                          selectedColor: TColors.primary.withValues(alpha: 0.12),
                          labelStyle: TextStyle(fontSize: TResponsive.sp(context, 11), color: _activeOnly ? TColors.primary : (isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                          side: BorderSide(color: _activeOnly ? TColors.primary : (isDark ? TColors.darkBorder : TColors.lightBorder)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
                if (list.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.account_tree_outlined, size: 48, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                      const SizedBox(height: TSizes.sm),
                      Text('No workflows', style: TextStyle(color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                    ])),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.sm),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: TSizes.sm),
                      itemBuilder: (_, i) {
                        final wf = list[i];
                        return TCard(
                          hasBorder: true,
                          onTap: () => context.go('/workflows/${wf.id}'),
                          padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: (wf.enabled ? TColors.success : TColors.neutralGray).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(TSizes.radiusMd),
                                ),
                                child: Icon(Icons.account_tree_outlined, size: 20, color: wf.enabled ? TColors.success : TColors.neutralGray),
                              ),
                              const SizedBox(width: TSizes.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(wf.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: TResponsive.sp(context, 14), fontWeight: FontWeight.w600, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                                    if (wf.description != null)
                                      Text(wf.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: TResponsive.sp(context, 12), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      if (wf.trigger != null) _chip(context, WorkflowUseCase.triggerLabel(wf.trigger!.type), TColors.info),
                                      const SizedBox(width: 6),
                                      Text('${wf.executionCount} runs', style: TextStyle(fontSize: TResponsive.sp(context, 10), color: isDark ? TColors.textTertiaryDark : TColors.textTertiaryLight)),
                                    ]),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: wf.enabled,
                                onChanged: WorkflowUseCase.canEditWorkflow(ref)
                                    ? (_) => WorkflowUseCase.toggleWorkflow(context: context, ref: ref, id: wf.id)
                                    : null,
                                activeColor: TColors.success,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: TSizes.xxl)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(TSizes.radiusFull)),
    child: Text(label, style: TextStyle(fontSize: TResponsive.sp(context, 9), fontWeight: FontWeight.w600, color: color)),
  );
}
