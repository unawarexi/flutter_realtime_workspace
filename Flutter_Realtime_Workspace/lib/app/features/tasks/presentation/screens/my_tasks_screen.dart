import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/task_provider.dart';
import 'package:flutter_realtime_workspace/app/domain/models/task_model.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/features/tasks/usecases/task_usecase.dart';

Color _statusColor(String s) => switch (s) {
      'in_progress' => const Color(0xFF3B82F6),
      'in_review' => const Color(0xFF8B5CF6),
      'done' => const Color(0xFF10B981),
      'blocked' => const Color(0xFFEF4444),
      'cancelled' => const Color(0xFF6B7280),
      'todo' => const Color(0xFFF59E0B),
      _ => const Color(0xFF94A3B8),
    };

Color _priorityColor(String p) => switch (p) {
      'critical' => const Color(0xFFEF4444),
      'high' => const Color(0xFFF97316),
      'medium' => const Color(0xFFF59E0B),
      'low' => const Color(0xFF6B7280),
      _ => const Color(0xFF94A3B8),
    };

class MyTasksScreen extends ConsumerStatefulWidget {
  const MyTasksScreen({super.key});

  @override
  ConsumerState<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends ConsumerState<MyTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final bg = isDark ? TColors.backgroundDark : TColors.backgroundLight;
    final userId = ref.watch(currentUserProvider).valueOrNull?.id ?? '';
    final tasksAsync = ref.watch(myTasksProvider(userId));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? TColors.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left,
              color: isDark ? TColors.textDark : TColors.textLight),
          onPressed: () => context.pop(),
        ),
        title: Text('My Tasks',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? TColors.textDark : TColors.textLight)),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: TColors.primary,
          unselectedLabelColor:
              isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
          indicatorColor: TColors.primary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'In Progress'),
            Tab(text: 'To Do'),
            Tab(text: 'Done'),
          ],
        ),
      ),
      body: tasksAsync.when(
        loading: () => _buildLoading(isDark),
        error: (e, _) => _buildError(isDark, e.toString(), userId),
        data: (tasks) => _buildTabs(context, isDark, tasks),
      ),
    );
  }

  Widget _buildLoading(bool isDark) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SSkeleton(height: 80, isDark: isDark, radius: 14),
            ),
          ),
        ),
      );

  Widget _buildError(bool isDark, String err, String userId) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.warning_2, size: 48, color: TColors.error),
            const SizedBox(height: 12),
            Text('Failed to load tasks',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? TColors.textDark : TColors.textLight)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(myTasksProvider(userId)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _buildTabs(
      BuildContext context, bool isDark, List<TaskModel> tasks) {
    final all = tasks;
    final inProgress =
        tasks.where((t) => t.status == 'in_progress').toList();
    final todo = tasks.where((t) => t.status == 'todo').toList();
    final done = tasks.where((t) => t.status == 'done').toList();

    return TabBarView(
      controller: _tabs,
      children: [
        _TaskList(tasks: all, isDark: isDark),
        _TaskList(tasks: inProgress, isDark: isDark),
        _TaskList(tasks: todo, isDark: isDark),
        _TaskList(tasks: done, isDark: isDark),
      ],
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final bool isDark;
  const _TaskList({required this.tasks, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.task_square,
                size: 56,
                color: isDark
                    ? TColors.textDarkTertiary
                    : TColors.textLightTertiary),
            const SizedBox(height: 16),
            Text('No tasks here',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? TColors.textDark : TColors.textLight)),
            const SizedBox(height: 6),
            Text('Tasks assigned to you will appear here.',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? TColors.textDarkSecondary
                        : TColors.textLightSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      color: TColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: tasks.length,
        itemBuilder: (context, i) => TWidgetAnimations.slideUp(
          delay: Duration(milliseconds: i * 40),
          child: _MyTaskCard(task: tasks[i], isDark: isDark),
        ),
      ),
    );
  }
}

class _MyTaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isDark;
  const _MyTaskCard({required this.task, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? TColors.darkElevated : Colors.white;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec =
        isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;
    final statusColor = _statusColor(task.status);
    final priorityColor = _priorityColor(task.priority);
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != 'done';

    return GestureDetector(
      onTap: () => context.push('/tasks/${task.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isOverdue ? TColors.error.withOpacity(0.4) : border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      color: statusColor, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Text(task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(task.priority.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: priorityColor)),
                ),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: textSec)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                      task.status.replaceAll('_', ' ').split(' ').map((w) =>
                          w[0].toUpperCase() + w.substring(1)).join(' '),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor)),
                ),
                const Spacer(),
                if (task.dueDate != null) ...[
                  Icon(
                    Iconsax.calendar_1,
                    size: 13,
                    color: isOverdue ? TColors.error : textSec,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    THelperFunctions.formatDate(task.dueDate!),
                    style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? TColors.error : textSec),
                  ),
                ],
                if (task.checklist.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(Iconsax.task_square, size: 13, color: textSec),
                  const SizedBox(width: 4),
                  Text(
                    '${task.checklist.where((c) => c.completed).length}/${task.checklist.length}',
                    style: TextStyle(fontSize: 11, color: textSec),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

