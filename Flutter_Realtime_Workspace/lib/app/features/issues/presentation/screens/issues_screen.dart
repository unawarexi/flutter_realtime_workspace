import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/store/issue_provider.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';
import 'package:flutter_realtime_workspace/app/domain/models/issue_model.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/empty_state.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/issue_usecase.dart';
import 'package:flutter_realtime_workspace/app/features/issues/presentation/widgets/issue_card.dart';
import 'package:flutter_realtime_workspace/app/features/issues/presentation/widgets/issue_filter_sheet.dart';

class IssuesScreen extends ConsumerStatefulWidget {
  const IssuesScreen({super.key});

  @override
  ConsumerState<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends ConsumerState<IssuesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _search = '';
  String? _filterType;
  String? _filterSeverity;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  IssueFilterKey get _filters => (
        workspaceId: ref.read(activeWorkspaceProvider)?.id,
        projectId: null,
        assigneeId: null,
        status: null,
        priority: null,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final bg = isDark ? TColors.backgroundDark : TColors.backgroundLight;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    final canCreate = IssueUseCase.canCreateIssue(ref);
    final issuesAsync = ref.watch(issuesProvider(_filters));

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/issues/create'),
              backgroundColor: TColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Issue',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor:
                isDark ? TColors.darkSurface : Colors.white,
            title: Text('Issues',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
            actions: [
              IconButton(
                icon: Icon(Iconsax.filter,
                    color: (_filterType != null || _filterSeverity != null)
                        ? TColors.primary
                        : (isDark
                            ? TColors.textDarkSecondary
                            : TColors.textLightSecondary)),
                onPressed: () => _showFilterSheet(context, isDark),
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(104),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? TColors.darkElevated
                            : TColors.lightElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _search = v),
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search issues...',
                          hintStyle: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? TColors.textDarkTertiary
                                  : TColors.textLightTertiary),
                          prefixIcon: Icon(Iconsax.search_normal,
                              size: 18,
                              color: isDark
                                  ? TColors.textDarkSecondary
                                  : TColors.textLightSecondary),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _search = '');
                                  })
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabs,
                    labelColor: TColors.primary,
                    unselectedLabelColor: isDark
                        ? TColors.textDarkSecondary
                        : TColors.textLightSecondary,
                    indicatorColor: TColors.primary,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Open'),
                      Tab(text: 'Resolved'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: issuesAsync.when(
          loading: () => _buildLoading(isDark),
          error: (e, _) => _buildError(isDark),
          data: (issues) => _buildTabs(context, isDark, issues),
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark) => ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
            6,
            (i) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: TSkeleton(height: 90),
                )),
      );

  Widget _buildError(bool isDark) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2, size: 48, color: TColors.error),
            const SizedBox(height: 12),
            Text('Failed to load issues',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? TColors.textDark : TColors.textLight)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(issuesProvider(_filters)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary, elevation: 0),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _buildTabs(
      BuildContext context, bool isDark, List<IssueModel> issues) {
    var filtered = IssueUseCase.searchIssues(issues, _search);
    if (_filterType != null) {
      filtered = filtered.where((i) => i.type == _filterType).toList();
    }
    if (_filterSeverity != null) {
      filtered =
          filtered.where((i) => i.severity == _filterSeverity).toList();
    }
    final open = filtered
        .where((i) =>
            ['open', 'in_progress', 'reopened'].contains(i.status))
        .toList();
    final resolved = filtered
        .where((i) =>
            ['resolved', 'closed', 'wont_fix'].contains(i.status))
        .toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(issuesProvider(_filters)),
      color: TColors.primary,
      child: TabBarView(
        controller: _tabs,
        children: [
          _IssueList(issues: filtered),
          _IssueList(issues: open),
          _IssueList(issues: resolved),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => IssueFilterSheet(
        filterType: _filterType,
        filterSeverity: _filterSeverity,
        onApply: (type, severity) {
          setState(() {
            _filterType = type;
            _filterSeverity = severity;
          });
        },
      ),
    );
  }
}

// ─── Issue List ───────────────────────────────────────────────────────────

class _IssueList extends StatelessWidget {
  final List<IssueModel> issues;
  const _IssueList({required this.issues});

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return const EmptyState(
        icon: Iconsax.warning_2,
        title: 'No issues found',
        subtitle: 'Issues you create will appear here.',
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        TResponsive.pagePadding(context),
        12,
        TResponsive.pagePadding(context),
        100,
      ),
      itemCount: issues.length,
      itemBuilder: (context, i) => TWidgetAnimations.slideUp(
        child: IssueCard(issue: issues[i]),
      ),
    );
  }
}
