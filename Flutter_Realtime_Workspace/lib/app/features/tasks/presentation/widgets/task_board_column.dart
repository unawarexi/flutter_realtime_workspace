import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/app/domain/models/task_model.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/task_usecase.dart';

/// A single Kanban column for a status group, used in task board views.
class TaskBoardColumn extends StatelessWidget {
  final String status;
  final List<TaskModel> tasks;
  final bool isDark;
  final void Function(TaskModel task)? onTap;

  const TaskBoardColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.isDark,
    this.onTap,
  });

  Color get _statusColor {
    switch (status) {
      case 'backlog': return TColors.neutralGray;
      case 'todo': return TColors.quickActionBlue;
      case 'in_progress': return TColors.quickActionYellow;
      case 'in_review': return TColors.quickActionPurple;
      case 'done': return TColors.success;
      case 'blocked': return TColors.error;
      case 'cancelled': return TColors.neutralGray;
      default: return TColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: TSizes.paddingSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: TSizes.paddingSM, vertical: TSizes.paddingXS + 2),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(TSizes.radiusMd)),
              border: Border(bottom: BorderSide(color: _statusColor.withValues(alpha: 0.3), width: 2)),
            ),
            child: Row(children: [
              Container(width: 8, height: 8,
                decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(TaskUseCase.statusLabel(status),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : TColors.textPrimaryLight)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(TSizes.radiusFull)),
                child: Text('${tasks.length}', style: TextStyle(fontSize: 9,
                  fontWeight: FontWeight.w700, color: _statusColor)),
              ),
            ]),
          ),
          // Cards
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? TColors.darkCard.withValues(alpha: 0.4) : TColors.lightElevated.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(TSizes.radiusMd)),
              ),
              child: tasks.isEmpty
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(TSizes.paddingMD),
                      child: Text('No tasks', style: TextStyle(fontSize: 10,
                        color: isDark ? TColors.darkMuted : TColors.lightMuted)),
                    ))
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(TSizes.paddingXS + 2),
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: TSizes.paddingXS),
                      itemBuilder: (_, i) => _TaskBoardCard(
                        task: tasks[i], isDark: isDark, onTap: () => onTap?.call(tasks[i])),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskBoardCard extends StatelessWidget {
  final TaskModel task;
  final bool isDark;
  final VoidCallback? onTap;

  const _TaskBoardCard({required this.task, required this.isDark, this.onTap});

  Color get _priorityColor {
    switch (task.priority) {
      case 'critical': return TColors.error;
      case 'high': return TColors.warning;
      case 'medium': return TColors.quickActionYellow;
      case 'low': return TColors.quickActionGreen;
      default: return TColors.neutralGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TSizes.paddingSM),
        decoration: BoxDecoration(
          color: isDark ? TColors.darkCard : TColors.lightSurface,
          borderRadius: BorderRadius.circular(TSizes.radiusSm),
          border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.06),
              blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key + priority
            Row(children: [
              if (task.key != null)
                Text(task.key!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                  color: isDark ? TColors.darkMuted : TColors.lightMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3)),
                child: Text(TaskUseCase.priorityLabel(task.priority),
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _priorityColor)),
              ),
            ]),
            const SizedBox(height: 4),
            // Title
            Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : TColors.textPrimaryLight)),
            // Labels
            if (task.labels.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 4, runSpacing: 2, children: task.labels.take(3).map((label) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: TColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(3)),
                  child: Text(label, style: TextStyle(fontSize: 8,
                    color: isDark ? TColors.blue400 : TColors.primary)),
                ),
              ).toList()),
            ],
            const SizedBox(height: 6),
            // Bottom row
            Row(children: [
              if (task.dueDate != null) ...[
                Icon(Icons.access_time_rounded, size: 10,
                  color: isDark ? TColors.darkMuted : TColors.lightMuted),
                const SizedBox(width: 3),
                Text(_formatDate(task.dueDate!), style: TextStyle(fontSize: 9,
                  color: isDark ? TColors.darkMuted : TColors.lightMuted)),
              ],
              const Spacer(),
              if (task.checklist.isNotEmpty) ...[
                Icon(Icons.check_box_outlined, size: 10,
                  color: isDark ? TColors.darkMuted : TColors.lightMuted),
                const SizedBox(width: 2),
                Text('${task.checklist.where((c) => c.completed).length}/${task.checklist.length}',
                  style: TextStyle(fontSize: 9, color: isDark ? TColors.darkMuted : TColors.lightMuted)),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
