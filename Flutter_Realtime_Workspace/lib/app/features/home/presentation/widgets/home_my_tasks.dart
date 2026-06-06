import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/domain/models/task_model.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class HomeMyTasks extends StatelessWidget {
  const HomeMyTasks({
    super.key,
    required this.isDark,
    required this.tasks,
    required this.isLoading,
  });

  final bool isDark;
  final List<TaskModel> tasks;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return TWidgetAnimations.slideUp(
      duration: const Duration(milliseconds: 480),
      offsetY: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Tasks',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? TColors.textDark : TColors.textLight,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/tasks/my'),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? TColors.blue400 : TColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.sm, vertical: TSizes.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('See all',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          SizedBox(
            height: 110,
            child: isLoading
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(right: TSizes.sm),
                      child: TSkeleton(width: 220, height: 110),
                    ),
                  )
                : tasks.isEmpty
                    ? SizedBox(
                        width: double.infinity,
                        child: TCard(
                          hasBorder: true,
                          padding: const EdgeInsets.symmetric(
                              vertical: TSizes.md, horizontal: TSizes.sm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_alt_outlined,
                                color: isDark
                                    ? TColors.darkMuted
                                    : TColors.lightMuted,
                                size: TSizes.iconMd,
                              ),
                              const SizedBox(width: TSizes.sm),
                              Text(
                                'No tasks assigned to you',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? TColors.darkMuted
                                      : TColors.lightMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                right:
                                    index == tasks.length - 1 ? 0 : TSizes.sm),
                            child: TWidgetAnimations.fadeIn(
                              delay: Duration(milliseconds: 50 * index),
                              child: _TaskCard(task: task, isDark: isDark),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.isDark});
  final TaskModel task;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (task.status.toLowerCase()) {
      case 'todo':
        statusColor = const Color(0xFF64748B);
        break;
      case 'in_progress':
        statusColor = const Color(0xFF3B82F6);
        break;
      case 'review':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'done':
        statusColor = const Color(0xFF10B981);
        break;
      default:
        statusColor = const Color(0xFF64748B);
    }

    return GestureDetector(
      onTap: () => context.push('/tasks'), // Ideally pushes to task details
      child: SizedBox(
        width: 220,
        child: TCard(
          hasBorder: true,
          hasShadow: true,
          padding: const EdgeInsets.all(TSizes.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (task.priority == 'high' || task.priority == 'critical')
                    Icon(
                      Icons.flag_rounded,
                      size: 14,
                      color: task.priority == 'critical'
                          ? TColors.error
                          : TColors.warning,
                    ),
                ],
              ),
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? TColors.textDark : TColors.textLight,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 12,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.projectId ?? 'No Project',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? TColors.darkMuted : TColors.lightMuted,
                      ),
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
