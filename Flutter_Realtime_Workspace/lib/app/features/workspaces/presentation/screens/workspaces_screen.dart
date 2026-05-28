import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/workspaces/presentation/widgets/workspace_card.dart';
import 'package:flutter_realtime_workspace/app/features/workspaces/usecases/workspace_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';

/// Lists all workspaces for the current user.
class WorkspacesScreen extends ConsumerStatefulWidget {
  const WorkspacesScreen({super.key});

  @override
  ConsumerState<WorkspacesScreen> createState() => _WorkspacesScreenState();
}

class _WorkspacesScreenState extends ConsumerState<WorkspacesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspacesAsync = ref.watch(workspacesProvider);
    final activeWs = WorkspaceUseCase.activeWorkspace(ref);
    final canCreate = WorkspaceUseCase.canCreateWorkspace(ref);
    final hPad = TResponsive.pagePadding(context);

    return Scaffold(
      backgroundColor:
          isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: SAppBar(
        title: 'Workspaces',
        showBack: true,
        actions: [
          if (canCreate)
            IconButton(
              onPressed: () => context.go('/workspaces/create'),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Create Workspace',
            ),
        ],
      ),
      body: workspacesAsync.when(
        loading: () => _buildSkeleton(hPad),
        error: (e, _) => Center(
          child: Text(
            'Failed to load workspaces',
            style: TextStyle(
              color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
            ),
          ),
        ),
        data: (workspaces) {
          final filtered =
              WorkspaceUseCase.searchWorkspaces(workspaces, _query);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(workspacesProvider),
            child: CustomScrollView(
              slivers: [
                // Search bar
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.sm),
                  sliver: SliverToBoxAdapter(
                    child: TSearchBar(
                      hint: 'Search workspaces...',
                      onChanged: (q) => setState(() => _query = q),
                    ),
                  ),
                ),

                // Count header
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: TSizes.sm),
                      child: Text(
                        '${filtered.length} workspace${filtered.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: TResponsive.sp(context, 12),
                          color: isDark
                              ? TColors.textSecondaryDark
                              : TColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // Workspace list
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmpty(isDark),
                  )
                else
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.xs),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: TSizes.sm),
                      itemBuilder: (_, i) {
                        final ws = filtered[i];
                        return WorkspaceCard(
                          workspace: ws,
                          isActive: activeWs?.id == ws.id,
                          onTap: () {
                            WorkspaceUseCase.switchWorkspace(ref, ws);
                            context.go('/workspaces/${ws.id}');
                          },
                        );
                      },
                    ),
                  ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: TSizes.xxl)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(double hPad) {
    return Padding(
      padding: EdgeInsets.all(hPad),
      child: Column(
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: TSizes.sm),
            child: TSkeleton(height: 84),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.workspaces_outlined,
            size: 64,
            color: isDark ? TColors.darkMuted : TColors.lightMuted,
          ),
          const SizedBox(height: TSizes.md),
          Text(
            _query.isEmpty ? 'No workspaces yet' : 'No results found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
            ),
          ),
          if (_query.isEmpty) ...[
            const SizedBox(height: TSizes.xs),
            Text(
              'Create a workspace to get started',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? TColors.textTertiaryDark : TColors.textTertiaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
