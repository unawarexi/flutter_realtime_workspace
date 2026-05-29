import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/domain/models/workspace_model.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';

/// Single workspace card used in the workspace list.
class WorkspaceCard extends StatelessWidget {
  final WorkspaceModel workspace;
  final bool isActive;
  final VoidCallback? onTap;

  const WorkspaceCard({
    super.key,
    required this.workspace,
    this.isActive = false,
    this.onTap,
  });

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return TColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _parseColor(workspace.color);

    return TCard(
      onTap: onTap,
      hasBorder: true,
      padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
      child: Row(
        children: [
          // ── Color avatar ──
          Container(
            width: TResponsive.sp(context, 48),
            height: TResponsive.sp(context, 48),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(TSizes.radiusMd),
              border: isActive
                  ? Border.all(color: color, width: 2)
                  : null,
            ),
            child: Center(
              child: workspace.icon != null
                  ? Text(
                      workspace.icon!,
                      style: TextStyle(fontSize: TResponsive.sp(context, 22)),
                    )
                  : Text(
                      workspace.name.isNotEmpty
                          ? workspace.name[0].toUpperCase()
                          : 'W',
                      style: TextStyle(
                        fontSize: TResponsive.sp(context, 20),
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
            ),
          ),
          SizedBox(width: TResponsive.sp(context, TSizes.md)),

          // ── Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        workspace.name,
                        style: TextStyle(
                          fontSize: TResponsive.sp(context, 15),
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? TColors.textPrimaryDark
                              : TColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: TColors.success.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(TSizes.radiusFull),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: TResponsive.sp(context, 10),
                            fontWeight: FontWeight.w600,
                            color: TColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                if (workspace.description != null &&
                    workspace.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      workspace.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: TResponsive.sp(context, 12),
                        color: isDark
                            ? TColors.textSecondaryDark
                            : TColors.textSecondaryLight,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                // Stats row
                _StatsRow(workspace: workspace),
              ],
            ),
          ),

          // ── Chevron ──
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? TColors.darkMuted : TColors.lightMuted,
            size: TResponsive.sp(context, 20),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final WorkspaceModel workspace;
  const _StatsRow({required this.workspace});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statColor =
        isDark ? TColors.textTertiaryDark : TColors.textTertiaryLight;

    return Row(
      children: [
        _stat(context, Icons.folder_outlined, '${workspace.projectCount}',
            statColor),
        const SizedBox(width: 12),
        _stat(context, Icons.people_outline, '${workspace.memberCount}',
            statColor),
        const SizedBox(width: 12),
        _stat(context, Icons.chat_bubble_outline, '${workspace.channelCount}',
            statColor),
      ],
    );
  }

  Widget _stat(
      BuildContext context, IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: TResponsive.sp(context, 13), color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: TResponsive.sp(context, 11),
            color: color,
          ),
        ),
      ],
    );
  }
}
