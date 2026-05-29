import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/task_provider.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/task_usecase.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/features/tasks/presentation/widgets/task_card.dart';
import 'package:flutter_realtime_workspace/app/features/tasks/presentation/widgets/task_filter_sheet.dart';


class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _priorityFilter = 'all';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _workspaceId =>
      ref.read(activeWorkspaceProvider)?.id ?? '';

  String get _userId =>
      ref.read(currentUserProvider).valueOrNull?.id ?? '';

  String get _role =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final bg = isDark ? TColors.backgroundDark : TColors.backgroundLight;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, textPrimary),
            _buildSearchBar(isDark),
            _buildTabBar(isDark),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AllTasksTab(
                    workspaceId: _workspaceId,
                    searchQuery: _searchQuery,
                    statusFilter: _statusFilter,
                    priorityFilter: _priorityFilter,
                    role: _role,
                  ),
                  _MyTasksTab(userId: _userId, searchQuery: _searchQuery, role: _role),
                  _KanbanTab(workspaceId: _workspaceId, role: _role),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: TaskUseCase.canCreateTask(ref)
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/tasks/create');
              },
              backgroundColor: TColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Task',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: TColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.task_square, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tasks',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.5)),
                Text('Track your work',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? TColors.textDarkSecondary
                            : TColors.textLightSecondary)),
              ],
            ),
          ),
          _buildFilterButton(context, isDark),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/tasks/my'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? TColors.darkElevated : TColors.lightElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Iconsax.profile_circle, color: TColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? TColors.darkElevated : TColors.lightElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(fontSize: 14, color: isDark ? TColors.textDark : TColors.textLight),
          decoration: InputDecoration(
            hintText: 'Search tasks...',
            hintStyle: TextStyle(
                fontSize: 14,
                color: isDark ? TColors.textDarkTertiary : TColors.textLightTertiary),
            prefixIcon: Icon(Iconsax.search_normal,
                size: 18,
                color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(Icons.close,
                        size: 16,
                        color: isDark
                            ? TColors.textDarkSecondary
                            : TColors.textLightSecondary),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, bool isDark) {
    final hasFilter = _statusFilter != 'all' || _priorityFilter != 'all';
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TaskFilterSheet(
          statusFilter: _statusFilter,
          priorityFilter: _priorityFilter,
          onApply: (s, p) => setState(() {
            _statusFilter = s;
            _priorityFilter = p;
          }),
        ),
      ),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: hasFilter
              ? TColors.primary.withOpacity(0.15)
              : isDark
                  ? TColors.darkElevated
                  : TColors.lightElevated,
          borderRadius: BorderRadius.circular(12),
          border: hasFilter
              ? Border.all(color: TColors.primary.withOpacity(0.5))
              : null,
        ),
        child: Icon(
          Iconsax.filter,
          color: hasFilter
              ? TColors.primary
              : isDark
                  ? TColors.textDarkSecondary
                  : TColors.textLightSecondary,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? TColors.darkElevated : TColors.lightElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: TColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor:
              isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'All'), Tab(text: 'Mine'), Tab(text: 'Board')],
        ),
      ),
    );
  }
}

// ─── All Tasks Tab ─────────────────────────────────────────────────────────
class _AllTasksTab extends ConsumerWidget {
  final String workspaceId;
  final String searchQuery;
  final String statusFilter;
  final String priorityFilter;
  final String role;

  const _AllTasksTab({
    required this.workspaceId,
    required this.searchQuery,
    required this.statusFilter,
    required this.priorityFilter,
    required this.role,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = THelperFunctions.isDarkMode(context);
    final filters = <String, String?>{
      'workspaceId': workspaceId.isEmpty ? null : workspaceId,
      'status': statusFilter == 'all' ? null : statusFilter,
    };
    final tasksAsync = ref.watch(tasksProvider(filters));

    return tasksAsync.when(
      loading: () => _buildSkeletonList(isDark),
      error: (e, _) => _buildError(context, isDark, e.toString(),
          () => ref.invalidate(tasksProvider(filters))),
      data: (tasks) {
        var filtered = tasks;
        if (searchQuery.isNotEmpty) {
          filtered = TaskUseCase.searchTasks(tasks, searchQuery);
        }
        if (priorityFilter != 'all') {
          filtered = filtered.where((t) => t.priority == priorityFilter).toList();
        }
        if (filtered.isEmpty) {
          return _buildEmpty(isDark, context, 'No tasks found',
              'Create your first task to get started');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(tasksProvider(filters)),
          color: TColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: filtered.length,
            itemBuilder: (context, i) => TWidgetAnimations.slideUp(
              child: TaskCard(task: filtered[i]),
            ),
          ),
        );
      },
    );
  }
}

// ─── My Tasks Tab ──────────────────────────────────────────────────────────
class _MyTasksTab extends ConsumerWidget {
  final String userId;
  final String searchQuery;
  final String role;

  const _MyTasksTab(
      {required this.userId, required this.searchQuery, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = THelperFunctions.isDarkMode(context);
    final myAsync = ref.watch(myTasksProvider(userId));

    return myAsync.when(
      loading: () => _buildSkeletonList(isDark),
      error: (e, _) => _buildError(context, isDark, e.toString(),
          () => ref.invalidate(myTasksProvider(userId))),
      data: (tasks) {
        final filtered = searchQuery.isNotEmpty
            ? TaskUseCase.searchTasks(tasks, searchQuery)
            : tasks;
        if (filtered.isEmpty) {
          return _buildEmpty(isDark, context, 'No assigned tasks',
              'You have no tasks assigned to you');
        }
        final groups = TaskUseCase.groupByStatus(filtered);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myTasksProvider(userId)),
          color: TColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              for (final status in TaskUseCase.statusOrder)
                if (groups[status]?.isNotEmpty == true) ...[
                  _StatusGroupHeader(status: status),
                  ...groups[status]!.map((t) => TaskCard(task: t)),
                ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Kanban Board Tab ─────────────────────────────────────────────────────
class _KanbanTab extends ConsumerWidget {
  final String workspaceId;
  final String role;

  const _KanbanTab({required this.workspaceId, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = THelperFunctions.isDarkMode(context);
    final filters = <String, String?>{'workspaceId': workspaceId.isEmpty ? null : workspaceId};
    final tasksAsync = ref.watch(tasksProvider(filters));

    return tasksAsync.when(
      loading: () => _KanbanSkeleton(),
      error: (e, _) => _buildError(context, isDark, e.toString(),
          () => ref.invalidate(tasksProvider(filters))),
      data: (tasks) {
        final groups = TaskUseCase.groupByStatus(tasks);
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: kanbanStatusOrder.length,
          itemBuilder: (ctx, i) {
            final status = kanbanStatusOrder[i];
            return KanbanColumn(
              status: status,
              tasks: groups[status] ?? [],
            );
          },
        );
      },
    );
  }
}

class _KanbanSkeleton extends StatelessWidget {
  const _KanbanSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: List.generate(
          3,
          (i) => Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: TSkeleton(height: 400),
          ),
        ),
      );
}

// ─── Status Group Header ─────────────────────────────────────────────────
class _StatusGroupHeader extends StatelessWidget {
  final String status;
  const _StatusGroupHeader({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final color = taskStatusColor(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(kanbanStatusLabels[status] ?? status,
              style: TextStyle(
                  fontSize: TResponsive.sp(context, 13),
                  fontWeight: FontWeight.w700,
                  color: isDark ? TColors.textDark : TColors.textLight,
                  letterSpacing: 0.3)),
          const SizedBox(width: 8),
          Expanded(
              child: Divider(
                  color: isDark ? TColors.darkBorder : TColors.lightBorder)),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────
Widget _buildSkeletonList(bool isDark) => ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TSkeleton(height: 90),
      ),
    );

Widget _buildEmpty(
        bool isDark, BuildContext context, String title, String subtitle) =>
    Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Iconsax.task_square, size: 36, color: TColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? TColors.textDark : TColors.textLight)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? TColors.textDarkSecondary
                        : TColors.textLightSecondary)),
          ],
        ),
      ),
    );

Widget _buildError(
        BuildContext context, bool isDark, String err, VoidCallback retry) =>
    Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.warning_2, size: 40, color: TColors.error),
            const SizedBox(height: 12),
            Text('Something went wrong',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? TColors.textDark : TColors.textLight)),
            const SizedBox(height: 8),
            Text(err,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? TColors.textDarkSecondary
                        : TColors.textLightSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
