import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/task_provider.dart';
import 'package:flutter_realtime_workspace/app/domain/models/task_model.dart';
import 'package:flutter_realtime_workspace/app/features/tasks/usecases/task_usecase.dart';
import 'package:flutter_realtime_workspace/core/utils/formatters.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';

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

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _userId =>
      ref.read(currentUserProvider).valueOrNull?.id ?? '';

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final bg = isDark ? TColors.backgroundDark : TColors.backgroundLight;
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));

    return Scaffold(
      backgroundColor: bg,
      body: taskAsync.when(
        loading: () => _buildLoading(isDark),
        error: (e, _) => _buildError(isDark, e.toString()),
        data: (task) => _buildContent(context, isDark, task),
      ),
    );
  }

  Widget _buildLoading(bool isDark) => Scaffold(
        backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: List.generate(
                5, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TSkeleton(height: 60),
                    )),
          ),
        ),
      );

  Widget _buildError(bool isDark, String err) => Scaffold(
        backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.warning_2, size: 48, color: TColors.error),
              const SizedBox(height: 12),
              Text('Failed to load task',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? TColors.textDark : TColors.textLight)),
              const SizedBox(height: 8),
              Text(err,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                      color: isDark
                          ? TColors.textDarkSecondary
                          : TColors.textLightSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(taskDetailProvider(widget.taskId)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
      );

  Widget _buildContent(BuildContext context, bool isDark, TaskModel task) {
    final statusColor = _statusColor(task.status);
    final priorityColor = _priorityColor(task.priority);
    final surface = isDark ? TColors.darkSurface : Colors.white;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec = isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    final isOwner = task.createdBy == _userId || task.assignedTo == _userId;
    final canEdit = TaskUseCase.canEditTask(ref, isOwner: isOwner);
    final canDelete = TaskUseCase.canDeleteTask(ref);
    final canComment = TaskUseCase.canEditTask(ref);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
          leading: IconButton(
            icon: Icon(Iconsax.arrow_left,
                color: isDark ? TColors.textDark : TColors.textLight),
            onPressed: () => context.pop(),
          ),
          title: task.key != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(task.key!,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: TColors.primary)),
                )
              : null,
          actions: [
            if (canEdit)
              IconButton(
                icon: Icon(Iconsax.edit, color: TColors.primary, size: 20),
                onPressed: () => _showEditSheet(context, isDark, task),
              ),
            if (canDelete)
              IconButton(
                icon: Icon(Iconsax.trash,
                    color: TColors.error.withOpacity(0.8), size: 20),
                onPressed: () => _confirmDelete(context, isDark, task),
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + Priority chips
                Row(
                  children: [
                    _Chip(
                      label: task.status.replaceAll('_', ' ').toUpperCase(),
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      label: task.priority.toUpperCase(),
                      color: priorityColor,
                    ),
                    const Spacer(),
                    if (canEdit)
                      GestureDetector(
                        onTap: () => _showStatusPicker(context, isDark, task),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.refresh,
                                  size: 14, color: textSec),
                              const SizedBox(width: 6),
                              Text('Status',
                                  style: TextStyle(
                                      fontSize: 12, color: textSec)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title
                Text(task.title,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        height: 1.3)),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(task.description!,
                      style: TextStyle(
                          fontSize: 15,
                          color: textSec,
                          height: 1.6)),
                ],
                const SizedBox(height: 20),
                // Meta grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      _MetaRow(
                        icon: Iconsax.calendar_1,
                        label: 'Due Date',
                        value: task.dueDate != null
                            ? TFormatter.formatDate(task.dueDate!)
                            : 'No due date',
                        isDark: isDark,
                        highlight: task.dueDate != null &&
                            task.dueDate!.isBefore(DateTime.now()),
                      ),
                      _MetaRow(
                        icon: Iconsax.clock,
                        label: 'Estimated',
                        value: task.estimatedHours != null
                            ? '${task.estimatedHours}h'
                            : 'Not set',
                        isDark: isDark,
                      ),
                      _MetaRow(
                        icon: Iconsax.clock_1,
                        label: 'Logged',
                        value: '${task.loggedHours}h',
                        isDark: isDark,
                      ),
                      _MetaRow(
                        icon: Iconsax.calendar_add,
                        label: 'Created',
                        value: TFormatter.formatDate(task.createdAt),
                        isDark: isDark,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                // Labels
                if (task.labels.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Labels',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: task.labels
                        .map((l) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: TColors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color:
                                        TColors.purple.withOpacity(0.3)),
                              ),
                              child: Text(l,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: TColors.purple,
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                ],
                // Checklist
                if (task.checklist.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Checklist',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary)),
                      Text(
                          '${task.checklist.where((c) => c.completed).length}/${task.checklist.length}',
                          style: TextStyle(
                              fontSize: 13, color: textSec)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: task.checklist
                            .where((c) => c.completed)
                            .length /
                        task.checklist.length,
                    backgroundColor: border,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(TColors.success),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: task.checklist.asMap().entries.map((e) {
                        final item = e.value;
                        return ListTile(
                          dense: true,
                          leading: canEdit
                              ? GestureDetector(
                                  onTap: () => _toggleChecklist(task, e.key),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: item.completed
                                          ? TColors.success
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      border: Border.all(
                                        color: item.completed
                                            ? TColors.success
                                            : border,
                                        width: 2,
                                      ),
                                    ),
                                    child: item.completed
                                        ? const Icon(Icons.check,
                                            size: 14,
                                            color: Colors.white)
                                        : null,
                                  ),
                                )
                              : Icon(
                                  item.completed
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 20,
                                  color: item.completed
                                      ? TColors.success
                                      : border,
                                ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              color: item.completed
                                  ? (isDark
                                      ? TColors.textDarkTertiary
                                      : TColors.textLightTertiary)
                                  : textPrimary,
                              decoration: item.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                // Attachments
                if (task.attachments.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Attachments',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                  const SizedBox(height: 10),
                  ...task.attachments.map(
                    (a) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: TColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Iconsax.document,
                                size: 18, color: TColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              a.filename ?? 'Attachment',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary),
                            ),
                          ),
                          if (a.bytes != null)
                            Text(
                              _formatBytes(a.bytes!),
                              style: TextStyle(
                                  fontSize: 12, color: textSec),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                // Comments
                const SizedBox(height: 20),
                Text('Comments (${task.comments.length})',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
                const SizedBox(height: 12),
                if (task.comments.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Center(
                      child: Text('No comments yet',
                          style: TextStyle(fontSize: 14, color: textSec)),
                    ),
                  )
                else
                  ...task.comments.map(
                    (c) => _CommentTile(comment: c, isDark: isDark),
                  ),
                // Add comment
                if (canComment) ...[
                  const SizedBox(height: 16),
                  _CommentInput(
                    controller: _commentController,
                    isSubmitting: _isSubmittingComment,
                    isDark: isDark,
                    onSubmit: () => _submitComment(task.id),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleChecklist(TaskModel task, int index) async {
    final updated = task.checklist.asMap().entries.map((e) {
      if (e.key == index) {
        return {'title': e.value.title, 'completed': !e.value.completed};
      }
      return {'title': e.value.title, 'completed': e.value.completed};
    }).toList();
    try {
      await ref.read(taskRepositoryProvider).updateChecklist(task.id, updated);
      ref.invalidate(taskDetailProvider(widget.taskId));
    } catch (_) {}
  }

  Future<void> _submitComment(String taskId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmittingComment) return;
    setState(() => _isSubmittingComment = true);
    try {
      await TaskUseCase.addComment(context: context, ref: ref, taskId: taskId, content: text);
      _commentController.clear();
      ref.invalidate(taskDetailProvider(widget.taskId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, bool isDark, TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? TColors.darkSurface : Colors.white,
        title: Text('Delete Task',
            style: TextStyle(
                color: isDark ? TColors.textDark : TColors.textLight)),
        content: Text('Are you sure you want to delete "${task.title}"?',
            style: TextStyle(
                color: isDark
                    ? TColors.textDarkSecondary
                    : TColors.textLightSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  Text('Delete', style: TextStyle(color: TColors.error))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await TaskUseCase.deleteTask(context: context, ref: ref, id: task.id);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  void _showStatusPicker(
      BuildContext context, bool isDark, TaskModel task) {
    final statuses = [
      'backlog', 'todo', 'in_progress', 'in_review', 'done', 'blocked', 'cancelled',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? TColors.darkSurface : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: isDark
                            ? TColors.darkBorder
                            : TColors.lightBorder,
                        borderRadius: BorderRadius.circular(2)))),
            Text('Change Status',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? TColors.textDark : TColors.textLight)),
            const SizedBox(height: 16),
            ...statuses.map((s) {
              final color = _statusColor(s);
              final isSelected = task.status == s;
              return ListTile(
                leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
                title: Text(
                    s.replaceAll('_', ' ').split(' ').map((w) =>
                        w[0].toUpperCase() + w.substring(1)).join(' '),
                    style: TextStyle(
                        color: isDark ? TColors.textDark : TColors.textLight,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500)),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: TColors.success)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await TaskUseCase.updateTask(
                        context: context, ref: ref, id: task.id, body: {'status': s});
                    ref.invalidate(taskDetailProvider(widget.taskId));
                  } catch (_) {}
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, bool isDark, TaskModel task) {
    context.push('/tasks/${task.id}/edit');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / 1048576).toStringAsFixed(1)}MB';
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5)),
      );
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;
  final bool isLast;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec = isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: textSec),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 13, color: textSec)),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: highlight ? TColors.error : textPrimary)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: border),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final TaskComment comment;
  final bool isDark;
  const _CommentTile({required this.comment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? TColors.darkElevated : Colors.white;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec = isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: TColors.primary.withOpacity(0.2),
                child: Text(
                  (comment.userId.isNotEmpty ? comment.userId[0] : '?')
                      .toUpperCase(),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: TColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(comment.userId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
              ),
              Text(TFormatter.formatDate(comment.createdAt),
                  style: TextStyle(fontSize: 11, color: textSec)),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.content,
              style: TextStyle(fontSize: 14, color: textPrimary, height: 1.5)),
        ],
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final bool isDark;
  final VoidCallback onSubmit;

  const _CommentInput({
    required this.controller,
    required this.isSubmitting,
    required this.isDark,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? TColors.darkElevated : TColors.lightElevated;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: TextField(
              controller: controller,
              maxLines: null,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? TColors.textDark : TColors.textLight),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: TextStyle(
                    color: isDark
                        ? TColors.textDarkTertiary
                        : TColors.textLightTertiary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isSubmitting ? null : onSubmit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSubmitting ? TColors.primary.withOpacity(0.5) : TColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isSubmitting
                ? const Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)))
                : const Icon(Iconsax.send_1, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}
