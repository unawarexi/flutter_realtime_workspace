import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/app/domain/models/task_model.dart';

/// Single checklist item tile used in the task detail screen.
class TaskChecklistTile extends StatelessWidget {
  final TaskChecklistItem item;
  final bool canEdit;
  final VoidCallback? onToggle;
  final bool isLast;

  const TaskChecklistTile({
    super.key,
    required this.item,
    this.canEdit = false,
    this.onToggle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textTert =
        isDark ? TColors.textDarkTertiary : TColors.textLightTertiary;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: TResponsive.sp(context, 12),
              vertical: 0,
            ),
            leading: canEdit
                ? GestureDetector(
                    onTap: onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: TResponsive.sp(context, 20),
                      height: TResponsive.sp(context, 20),
                      decoration: BoxDecoration(
                        color: item.completed
                            ? TColors.success
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color:
                              item.completed ? TColors.success : border,
                          width: 2,
                        ),
                      ),
                      child: item.completed
                          ? Icon(
                              Icons.check,
                              size: TResponsive.sp(context, 14),
                              color: Colors.white,
                            )
                          : null,
                    ),
                  )
                : Icon(
                    item.completed
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: TResponsive.sp(context, 20),
                    color: item.completed ? TColors.success : border,
                  ),
            title: Text(
              item.title,
              style: TextStyle(
                fontSize: TResponsive.sp(context, 14),
                color: item.completed ? textTert : textPrimary,
                decoration:
                    item.completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: border,
            indent: TResponsive.sp(context, 12),
            endIndent: TResponsive.sp(context, 12),
          ),
      ],
    );
  }
}
