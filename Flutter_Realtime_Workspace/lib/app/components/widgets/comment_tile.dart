import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/utils/formatters.dart';

/// Generic comment display tile.
/// Used by both task and issue detail screens.
class CommentTile extends StatelessWidget {
  final String userId;
  final String content;
  final DateTime createdAt;

  const CommentTile({
    super.key,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? TColors.darkElevated : Colors.white;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec =
        isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;
    final nameSize = TResponsive.sp(context, 13);
    final bodySize = TResponsive.sp(context, 14);
    final dateSize = TResponsive.sp(context, 11);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(TResponsive.sp(context, 14)),
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
                radius: TResponsive.sp(context, 14),
                backgroundColor: TColors.primary.withOpacity(0.15),
                child: Text(
                  (userId.isNotEmpty ? userId[0] : '?').toUpperCase(),
                  style: TextStyle(
                    fontSize: TResponsive.sp(context, 12),
                    fontWeight: FontWeight.w700,
                    color: TColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  userId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: nameSize,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Text(
                TFormatter.formatDate(createdAt),
                style: TextStyle(fontSize: dateSize, color: textSec),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style:
                TextStyle(fontSize: bodySize, color: textPrimary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Shared comment input row (text field + send button).
class CommentInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String hint;

  const CommentInputField({
    super.key,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    this.hint = 'Add a comment...',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? TColors.darkElevated : TColors.lightElevated;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            constraints:
                BoxConstraints(minHeight: TResponsive.sp(context, 44)),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: TextField(
              controller: controller,
              maxLines: null,
              style: TextStyle(
                fontSize: TResponsive.sp(context, 14),
                color: isDark ? TColors.textDark : TColors.textLight,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark
                      ? TColors.textDarkTertiary
                      : TColors.textLightTertiary,
                ),
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
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : const Icon(Iconsax.send_1,
                    color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}
