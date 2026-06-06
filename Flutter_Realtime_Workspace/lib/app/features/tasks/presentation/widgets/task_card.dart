import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/utils/formatters.dart';
import 'package:flutter_realtime_workspace/app/domain/models/task_model.dart';

// ─── Color / Icon Helpers ────────────────────────────────────────────────────

Color taskStatusColor(String status) => switch (status) {
      'in_progress' => const Color(0xFF3B82F6),
      'in_review' => const Color(0xFF8B5CF6),
      'done' => const Color(0xFF10B981),
      'blocked' => const Color(0xFFEF4444),
      'cancelled' => const Color(0xFF6B7280),
      'todo' => const Color(0xFFF59E0B),
      _ => const Color(0xFF94A3B8),
    };

Color taskPriorityColor(String p) => switch (p) {
      'critical' => const Color(0xFFEF4444),
      'high' => const Color(0xFFF97316),
      'medium' => const Color(0xFFF59E0B),
      'low' => const Color(0xFF6B7280),
      _ => const Color(0xFF94A3B8),
    };

IconData taskPriorityIcon(String p) => switch (p) {
      'critical' => Iconsax.arrow_circle_up,
      'high' => Iconsax.arrow_up_2,
      'medium' => Iconsax.minus,
      'low' => Iconsax.arrow_down_2,
      _ => Iconsax.arrow_down_2,
    };

const List<String> kanbanStatusOrder = [
  'backlog', 'todo', 'in_progress', 'in_review', 'done', 'blocked',
];

const Map<String, String> kanbanStatusLabels = {
  'backlog': 'Backlog',
  'todo': 'To Do',
  'in_progress': 'In Progress',
  'in_review': 'In Review',
  'done': 'Done',
  'blocked': 'Blocked',
};

// ─── Task Card (List View) ────────────────────────────────────────────────────

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = taskStatusColor(task.status);
    final priorityColor = taskPriorityColor(task.priority);
    final bg = isDark ? TColors.darkElevated : Colors.white;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec =
        isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;
    final textTert =
        isDark ? TColors.textDarkTertiary : TColors.textLightTertiary;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;

    final titleSize = TResponsive.sp(context, 15);
    final descSize = TResponsive.sp(context, 13);
    final metaSize = TResponsive.sp(context, 12);
    final badgeSize = TResponsive.sp(context, 10);
    final iconSize = TResponsive.sp(context, 13);
    final priorityIconSize = TResponsive.sp(context, 16);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/tasks/${task.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(TResponsive.sp(context, 14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (task.key != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: TResponsive.sp(context, 7),
                        vertical: TResponsive.sp(context, 3),
                      ),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.key!,
                        style: TextStyle(
                          fontSize: badgeSize,
                          fontWeight: FontWeight.w700,
                          color: TColors.primary,
                        ),
                      ),
                    ),
                  SizedBox(width: TResponsive.sp(context, 8)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: TResponsive.sp(context, 8),
                      vertical: TResponsive.sp(context, 3),
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: badgeSize,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(taskPriorityIcon(task.priority),
                      size: priorityIconSize, color: priorityColor),
                ],
              ),
              SizedBox(height: TResponsive.sp(context, 8)),
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  height: 1.3,
                ),
              ),
              if (task.description != null &&
                  task.description!.isNotEmpty) ...[
                SizedBox(height: TResponsive.sp(context, 4)),
                Text(
                  task.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: descSize, color: textSec),
                ),
              ],
              SizedBox(height: TResponsive.sp(context, 10)),
              Row(
                children: [
                  if (task.dueDate != null) ...[
                    Icon(
                      Iconsax.calendar_1,
                      size: iconSize,
                      color: task.dueDate!.isBefore(DateTime.now())
                          ? TColors.error
                          : textTert,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      TFormatter.formatDate(task.dueDate!),
                      style: TextStyle(
                        fontSize: metaSize,
                        color: task.dueDate!.isBefore(DateTime.now())
                            ? TColors.error
                            : textTert,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (task.checklist.isNotEmpty) ...[
                    Icon(Iconsax.task_square, size: iconSize, color: textTert),
                    const SizedBox(width: 4),
                    Text(
                      '${task.checklist.where((c) => c.completed).length}/${task.checklist.length}',
                      style: TextStyle(fontSize: metaSize, color: textTert),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (task.comments.isNotEmpty) ...[
                    Icon(Iconsax.message, size: iconSize, color: textTert),
                    const SizedBox(width: 4),
                    Text(
                      '${task.comments.length}',
                      style: TextStyle(fontSize: metaSize, color: textTert),
                    ),
                  ],
                  const Spacer(),
                  if (task.checklist.isNotEmpty)
                    SizedBox(
                      width: 60,
                      child: LinearProgressIndicator(
                        value: task.checklist
                                .where((c) => c.completed)
                                .length /
                            task.checklist.length,
                        backgroundColor: border,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(TColors.success),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Kanban Task Card ─────────────────────────────────────────────────────────

class KanbanTaskCard extends StatelessWidget {
  final TaskModel task;

  const KanbanTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priorityColor = taskPriorityColor(task.priority);
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec =
        isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;
    final titleSize = TResponsive.sp(context, 13);
    final metaSize = TResponsive.sp(context, 11);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/tasks/${task.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(TResponsive.sp(context, 12)),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: priorityColor, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.key != null)
              Text(
                task.key!,
                style: TextStyle(
                  fontSize: metaSize,
                  fontWeight: FontWeight.w600,
                  color: TColors.primary,
                ),
              ),
            SizedBox(height: TResponsive.sp(context, 4)),
            Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                height: 1.3,
              ),
            ),
            if (task.dueDate != null) ...[
              SizedBox(height: TResponsive.sp(context, 8)),
              Row(
                children: [
                  Icon(
                    Iconsax.calendar_1,
                    size: TResponsive.sp(context, 12),
                    color: task.dueDate!.isBefore(DateTime.now())
                        ? TColors.error
                        : textSec,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    TFormatter.formatDate(task.dueDate!),
                    style: TextStyle(
                      fontSize: metaSize,
                      color: task.dueDate!.isBefore(DateTime.now())
                          ? TColors.error
                          : textSec,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Kanban Column ────────────────────────────────────────────────────────────

class KanbanColumn extends StatelessWidget {
  final String status;
  final List<TaskModel> tasks;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = taskStatusColor(status);
    final bg = isDark ? TColors.darkElevated : TColors.lightElevated;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textTert =
        isDark ? TColors.textDarkTertiary : TColors.textLightTertiary;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              TResponsive.sp(context, 16),
              TResponsive.sp(context, 14),
              TResponsive.sp(context, 16),
              TResponsive.sp(context, 10),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  kanbanStatusLabels[status] ?? status,
                  style: TextStyle(
                    fontSize: TResponsive.sp(context, 13),
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: TResponsive.sp(context, 8),
                    vertical: TResponsive.sp(context, 3),
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: TResponsive.sp(context, 12),
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks',
                      style: TextStyle(
                        fontSize: TResponsive.sp(context, 13),
                        color: textTert,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => KanbanTaskCard(task: tasks[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
