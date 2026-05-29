import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/utils/formatters.dart';
import 'package:flutter_realtime_workspace/app/domain/models/issue_model.dart';

// ─── Color / Icon Helpers ────────────────────────────────────────────────────

Color issueTypeColor(String t) => switch (t) {
      'bug' => const Color(0xFFEF4444),
      'feature' => const Color(0xFF3B82F6),
      'improvement' => const Color(0xFF8B5CF6),
      'task' => const Color(0xFFF59E0B),
      'epic' => const Color(0xFFEC4899),
      'story' => const Color(0xFF10B981),
      _ => const Color(0xFF94A3B8),
    };

Color issueStatusColor(String s) => switch (s) {
      'open' => const Color(0xFF3B82F6),
      'in_progress' => const Color(0xFFF59E0B),
      'resolved' => const Color(0xFF10B981),
      'closed' => const Color(0xFF6B7280),
      'reopened' => const Color(0xFFF97316),
      'wont_fix' => const Color(0xFFEF4444),
      _ => const Color(0xFF94A3B8),
    };

Color issueSeverityColor(String s) => switch (s) {
      'blocker' => const Color(0xFFEF4444),
      'major' => const Color(0xFFF97316),
      'minor' => const Color(0xFFF59E0B),
      'trivial' => const Color(0xFF94A3B8),
      _ => const Color(0xFF94A3B8),
    };

IconData issueTypeIcon(String t) => switch (t) {
      'bug' => Iconsax.warning_2,
      'feature' => Iconsax.star,
      'improvement' => Iconsax.arrow_up_2,
      'task' => Iconsax.task_square,
      'epic' => Iconsax.flash,
      'story' => Iconsax.document_text,
      _ => Iconsax.info_circle,
    };

// ─── Issue Card ───────────────────────────────────────────────────────────────

class IssueCard extends StatelessWidget {
  final IssueModel issue;

  const IssueCard({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? TColors.darkElevated : Colors.white;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec =
        isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;

    final typeColor = issueTypeColor(issue.type);
    final statusColor = issueStatusColor(issue.status);
    final severityColor = issueSeverityColor(issue.severity);

    final titleSize = TResponsive.sp(context, 14);
    final descSize = TResponsive.sp(context, 12);
    final metaSize = TResponsive.sp(context, 11);
    final iconSize = TResponsive.sp(context, 16);
    final containerSize = TResponsive.sp(context, 30);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/issues/${issue.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(TResponsive.sp(context, 14)),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(TResponsive.sp(context, 8)),
                  ),
                  child: Icon(issueTypeIcon(issue.type),
                      size: iconSize, color: typeColor),
                ),
                SizedBox(width: TResponsive.sp(context, 10)),
                Expanded(
                  child: Text(
                    issue.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                if (issue.key != null)
                  Text(
                    issue.key!,
                    style: TextStyle(
                      fontSize: metaSize,
                      color: textSec,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
            if (issue.description != null &&
                issue.description!.isNotEmpty) ...[
              SizedBox(height: TResponsive.sp(context, 6)),
              Text(
                issue.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: descSize, color: textSec, height: 1.4),
              ),
            ],
            SizedBox(height: TResponsive.sp(context, 10)),
            Row(
              children: [
                _IssueSmallBadge(
                  label: issue.status.replaceAll('_', ' '),
                  color: statusColor,
                ),
                SizedBox(width: TResponsive.sp(context, 6)),
                _IssueSmallBadge(label: issue.severity, color: severityColor),
                const Spacer(),
                if (issue.comments.isNotEmpty) ...[
                  Icon(Iconsax.message, size: metaSize, color: textSec),
                  const SizedBox(width: 4),
                  Text(
                    '${issue.comments.length}',
                    style: TextStyle(fontSize: metaSize, color: textSec),
                  ),
                ],
                if (issue.dueDate != null) ...[
                  SizedBox(width: TResponsive.sp(context, 10)),
                  Icon(Iconsax.calendar_1,
                      size: metaSize, color: textSec),
                  const SizedBox(width: 4),
                  Text(
                    TFormatter.formatDate(issue.dueDate!),
                    style: TextStyle(
                      fontSize: metaSize,
                      color: issue.dueDate!.isBefore(DateTime.now()) &&
                              issue.status != 'resolved' &&
                              issue.status != 'closed'
                          ? TColors.error
                          : textSec,
                    ),
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

// ─── Small Badge ─────────────────────────────────────────────────────────────

class _IssueSmallBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _IssueSmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: TResponsive.sp(context, 8),
          vertical: TResponsive.sp(context, 3),
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius:
              BorderRadius.circular(TResponsive.sp(context, 5)),
        ),
        child: Text(
          label
              .split(' ')
              .map((w) => w.isNotEmpty
                  ? w[0].toUpperCase() + w.substring(1)
                  : w)
              .join(' '),
          style: TextStyle(
            fontSize: TResponsive.sp(context, 10),
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
}
