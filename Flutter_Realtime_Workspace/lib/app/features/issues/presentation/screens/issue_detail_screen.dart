import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/core/utils/formatters.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/issue_provider.dart';
import 'package:flutter_realtime_workspace/app/domain/models/issue_model.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/features/issues/usecases/issue_usecase.dart';

Color _statusColor(String s) => switch (s) {
      'open' => const Color(0xFF3B82F6),
      'in_progress' => const Color(0xFFF59E0B),
      'resolved' => const Color(0xFF10B981),
      'closed' => const Color(0xFF6B7280),
      'reopened' => const Color(0xFFF97316),
      'wont_fix' => const Color(0xFFEF4444),
      _ => const Color(0xFF94A3B8),
    };

Color _typeColor(String t) => switch (t) {
      'bug' => const Color(0xFFEF4444),
      'feature' => const Color(0xFF3B82F6),
      'improvement' => const Color(0xFF8B5CF6),
      'task' => const Color(0xFFF59E0B),
      'epic' => const Color(0xFFEC4899),
      'story' => const Color(0xFF10B981),
      _ => const Color(0xFF94A3B8),
    };

Color _severityColor(String s) => switch (s) {
      'blocker' => const Color(0xFFEF4444),
      'major' => const Color(0xFFF97316),
      'minor' => const Color(0xFFF59E0B),
      'trivial' => const Color(0xFF94A3B8),
      _ => const Color(0xFF94A3B8),
    };

Color _priorityColor(String p) => switch (p) {
      'critical' => const Color(0xFFEF4444),
      'high' => const Color(0xFFF97316),
      'medium' => const Color(0xFFF59E0B),
      'low' => const Color(0xFF6B7280),
      _ => const Color(0xFF94A3B8),
    };

class IssueDetailScreen extends ConsumerStatefulWidget {
  final String issueId;
  const IssueDetailScreen({super.key, required this.issueId});

  @override
  ConsumerState<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends ConsumerState<IssueDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _submittingComment = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String get _userId =>
      ref.read(currentUserProvider).valueOrNull?.id ?? '';

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final bg = isDark ? TColors.backgroundDark : TColors.backgroundLight;
    final issueAsync = ref.watch(issueDetailProvider(widget.issueId));

    return Scaffold(
      backgroundColor: bg,
      body: issueAsync.when(
        loading: () => _buildLoading(isDark),
        error: (e, _) => _buildError(isDark, e.toString()),
        data: (issue) => _buildContent(context, isDark, issue),
      ),
    );
  }

  Widget _buildLoading(bool isDark) => Scaffold(
        backgroundColor:
            isDark ? TColors.backgroundDark : TColors.backgroundLight,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: List.generate(
                5,
                (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TSkeleton(height: 60),
                    )),
          ),
        ),
      );

  Widget _buildError(bool isDark, String err) => Scaffold(
        backgroundColor:
            isDark ? TColors.backgroundDark : TColors.backgroundLight,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.warning_2, size: 48, color: TColors.error),
              const SizedBox(height: 12),
              Text('Failed to load issue',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? TColors.textDark : TColors.textLight)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(issueDetailProvider(widget.issueId)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary, elevation: 0),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );

  Widget _buildContent(
      BuildContext context, bool isDark, IssueModel issue) {
    final surface = isDark ? TColors.darkSurface : Colors.white;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec =
        isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    final isOwner = issue.createdBy == _userId;
    final canEdit = IssueUseCase.canEditIssue(ref, isOwner: isOwner);
    final canDelete = IssueUseCase.canDeleteIssue(ref);
    final canComment = IssueUseCase.canComment(ref);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor:
              isDark ? TColors.backgroundDark : TColors.backgroundLight,
          leading: IconButton(
            icon: Icon(Iconsax.arrow_left, color: textPrimary),
            onPressed: () => context.pop(),
          ),
          title: issue.key != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(issue.key!,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TColors.primary)),
                )
              : null,
          actions: [
            if (canEdit)
              IconButton(
                icon: Icon(Iconsax.edit, color: TColors.primary, size: 20),
                onPressed: () =>
                    context.push('/issues/${issue.id}/edit'),
              ),
            if (canDelete)
              IconButton(
                icon: Icon(Iconsax.trash,
                    color: TColors.error.withOpacity(0.8), size: 20),
                onPressed: () => _confirmDelete(context, isDark, issue),
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                        label: issue.status.replaceAll('_', ' '),
                        color: _statusColor(issue.status)),
                    _Badge(
                        label: issue.type, color: _typeColor(issue.type)),
                    _Badge(
                        label: issue.severity,
                        color: _severityColor(issue.severity)),
                    _Badge(
                        label: issue.priority,
                        color: _priorityColor(issue.priority)),
                    if (canEdit)
                      GestureDetector(
                        onTap: () =>
                            _showStatusPicker(context, isDark, issue),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.refresh,
                                  size: 13, color: textSec),
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
                Text(issue.title,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        height: 1.3)),
                if (issue.description != null &&
                    issue.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(issue.description!,
                      style: TextStyle(
                          fontSize: 15,
                          color: textSec,
                          height: 1.6)),
                ],
                const SizedBox(height: 20),
                // Meta
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
                          value: issue.dueDate != null
                              ? TFormatter.formatDate(issue.dueDate!)
                              : 'No due date',
                          isDark: isDark),
                      _MetaRow(
                          icon: Iconsax.calendar_tick,
                          label: 'Resolved',
                          value: issue.resolvedAt != null
                              ? TFormatter.formatDate(issue.resolvedAt!)
                              : 'Not resolved',
                          isDark: isDark),
                      _MetaRow(
                          icon: Iconsax.calendar_add,
                          label: 'Created',
                          value: TFormatter.formatDate(issue.createdAt),
                          isDark: isDark,
                          isLast: true),
                    ],
                  ),
                ),
                // Reproduction info
                if (issue.stepsToReproduce != null &&
                    issue.stepsToReproduce!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionHeader(
                      title: 'Steps to Reproduce', isDark: isDark),
                  const SizedBox(height: 8),
                  _InfoCard(
                      text: issue.stepsToReproduce!,
                      isDark: isDark,
                      color: TColors.warning),
                ],
                if (issue.expectedBehavior != null &&
                    issue.expectedBehavior!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SectionHeader(
                      title: 'Expected Behavior', isDark: isDark),
                  const SizedBox(height: 8),
                  _InfoCard(
                      text: issue.expectedBehavior!,
                      isDark: isDark,
                      color: TColors.success),
                ],
                if (issue.actualBehavior != null &&
                    issue.actualBehavior!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SectionHeader(
                      title: 'Actual Behavior', isDark: isDark),
                  const SizedBox(height: 8),
                  _InfoCard(
                      text: issue.actualBehavior!,
                      isDark: isDark,
                      color: TColors.error),
                ],
                if (issue.environment != null &&
                    issue.environment!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SectionHeader(title: 'Environment', isDark: isDark),
                  const SizedBox(height: 8),
                  _InfoCard(
                      text: issue.environment!,
                      isDark: isDark,
                      color: TColors.info),
                ],
                // Labels
                if (issue.labels.isNotEmpty || issue.tags.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionHeader(
                      title: 'Labels & Tags', isDark: isDark),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...issue.labels.map((l) => _TagChip(
                          label: l, color: TColors.purple)),
                      ...issue.tags.map(
                          (t) => _TagChip(label: t, color: TColors.info)),
                    ],
                  ),
                ],
                // Linked issues
                if (issue.linkedIssues.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionHeader(
                      title: 'Linked Issues (${issue.linkedIssues.length})',
                      isDark: isDark),
                  const SizedBox(height: 10),
                  ...issue.linkedIssues.map(
                    (li) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: TColors.warning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              li.relation.replaceAll('_', ' '),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: TColors.warning),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(li.issueId,
                              style: TextStyle(
                                  fontSize: 13, color: textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],
                // Comments
                const SizedBox(height: 20),
                _SectionHeader(
                    title: 'Comments (${issue.comments.length})',
                    isDark: isDark),
                const SizedBox(height: 12),
                if (issue.comments.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Center(
                      child: Text('No comments yet',
                          style: TextStyle(color: textSec)),
                    ),
                  )
                else
                  ...issue.comments.map(
                    (c) => _CommentTile(comment: c, isDark: isDark),
                  ),
                if (canComment) ...[
                  const SizedBox(height: 16),
                  _CommentInput(
                    controller: _commentCtrl,
                    isSubmitting: _submittingComment,
                    isDark: isDark,
                    onSubmit: () => _submitComment(issue.id),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitComment(String issueId) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _submittingComment) return;
    setState(() => _submittingComment = true);
    try {
      await IssueUseCase.addComment(ref, issueId, text);
      _commentCtrl.clear();
      ref.invalidate(issueDetailProvider(widget.issueId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, bool isDark, IssueModel issue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? TColors.darkSurface : Colors.white,
        title: Text('Delete Issue',
            style: TextStyle(
                color: isDark ? TColors.textDark : TColors.textLight)),
        content: Text('Delete "${issue.title}"?',
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
        await IssueUseCase.deleteIssue(ref, issue.id);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  void _showStatusPicker(
      BuildContext context, bool isDark, IssueModel issue) {
    final statuses = [
      'open',
      'in_progress',
      'resolved',
      'closed',
      'reopened',
      'wont_fix'
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
                  color:
                      isDark ? TColors.darkBorder : TColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Change Status',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark ? TColors.textDark : TColors.textLight)),
            const SizedBox(height: 16),
            ...statuses.map((s) {
              final color = _statusColor(s);
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
                      color: isDark
                          ? TColors.textDark
                          : TColors.textLight),
                ),
                trailing: issue.status == s
                    ? Icon(Icons.check_circle, color: TColors.success)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await IssueUseCase.updateIssue(
                        ref, issue.id, {'status': s});
                    ref.invalidate(issueDetailProvider(widget.issueId));
                  } catch (_) {}
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' '),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) => Text(title,
      style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDark ? TColors.textDark : TColors.textLight));
}

class _InfoCard extends StatelessWidget {
  final String text;
  final bool isDark;
  final Color color;
  const _InfoCard(
      {required this.text, required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? TColors.darkElevated : Colors.white;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: border),
          right: BorderSide(color: border),
          bottom: BorderSide(color: border),
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isDark ? TColors.textDark : TColors.textLight)),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600)),
      );
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool isLast;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec =
        isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: textSec),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 13, color: textSec)),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: border),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final IssueComment comment;
  final bool isDark;
  const _CommentTile({required this.comment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? TColors.darkElevated : Colors.white;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec =
        isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;

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
                  (comment.userId.isNotEmpty
                          ? comment.userId[0]
                          : '?')
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
              style: TextStyle(
                  fontSize: 14, color: textPrimary, height: 1.5)),
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
              color: isSubmitting
                  ? TColors.primary.withOpacity(0.5)
                  : TColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isSubmitting
                ? const Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)))
                : const Icon(Iconsax.send_1,
                    color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

