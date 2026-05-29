import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/app/features/tasks/presentation/widgets/task_card.dart';

/// Bottom-sheet filter for task status and priority.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => TaskFilterSheet(
///     statusFilter: _statusFilter,
///     priorityFilter: _priorityFilter,
///     onApply: (status, priority) => setState(() { ... }),
///   ),
/// );
/// ```
class TaskFilterSheet extends StatefulWidget {
  final String statusFilter;
  final String priorityFilter;
  final void Function(String status, String priority) onApply;

  const TaskFilterSheet({
    super.key,
    required this.statusFilter,
    required this.priorityFilter,
    required this.onApply,
  });

  @override
  State<TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<TaskFilterSheet> {
  late String _tempStatus;
  late String _tempPriority;

  @override
  void initState() {
    super.initState();
    _tempStatus = widget.statusFilter;
    _tempPriority = widget.priorityFilter;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? TColors.darkSurface : Colors.white;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec =
        isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;
    final borderColor = isDark ? TColors.darkBorder : TColors.lightBorder;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Filter Tasks',
            style: TextStyle(
              fontSize: TResponsive.sp(context, 18),
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          SizedBox(height: TResponsive.sp(context, 20)),
          _SectionLabel(text: 'Status', textSec: textSec),
          SizedBox(height: TResponsive.sp(context, 10)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['all', ...kanbanStatusOrder].map((s) {
              return _TaskFilterChip(
                label: s == 'all' ? 'All' : (kanbanStatusLabels[s] ?? s),
                selected: _tempStatus == s,
                color: s == 'all'
                    ? TColors.primary
                    : taskStatusColor(s),
                isDark: isDark,
                onTap: () => setState(() => _tempStatus = s),
              );
            }).toList(),
          ),
          SizedBox(height: TResponsive.sp(context, 20)),
          _SectionLabel(text: 'Priority', textSec: textSec),
          SizedBox(height: TResponsive.sp(context, 10)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                ['all', 'critical', 'high', 'medium', 'low', 'lowest']
                    .map((p) {
              return _TaskFilterChip(
                label: p == 'all'
                    ? 'All'
                    : p[0].toUpperCase() + p.substring(1),
                selected: _tempPriority == p,
                color:
                    p == 'all' ? TColors.primary : taskPriorityColor(p),
                isDark: isDark,
                onTap: () => setState(() => _tempPriority = p),
              );
            }).toList(),
          ),
          SizedBox(height: TResponsive.sp(context, 24)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply('all', 'all');
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Reset',
                    style: TextStyle(color: textSec),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_tempStatus, _tempPriority);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color textSec;
  const _SectionLabel({required this.text, required this.textSec});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: TResponsive.sp(context, 13),
          fontWeight: FontWeight.w600,
          color: textSec,
        ),
      );
}

class _TaskFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _TaskFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: TResponsive.sp(context, 14),
            vertical: TResponsive.sp(context, 8),
          ),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.15)
                : isDark
                    ? TColors.darkElevated
                    : TColors.lightElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? color
                  : isDark
                      ? TColors.darkBorder
                      : TColors.lightBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: TResponsive.sp(context, 13),
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? color
                  : isDark
                      ? TColors.textDarkSecondary
                      : TColors.textLightSecondary,
            ),
          ),
        ),
      );
}
