import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/app/features/issues/presentation/widgets/issue_card.dart';

/// Bottom-sheet filter for issue type and severity.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => IssueFilterSheet(
///     filterType: _filterType,
///     filterSeverity: _filterSeverity,
///     onApply: (type, severity) => setState(() { ... }),
///   ),
/// );
/// ```
class IssueFilterSheet extends StatefulWidget {
  final String? filterType;
  final String? filterSeverity;
  final void Function(String? type, String? severity) onApply;

  const IssueFilterSheet({
    super.key,
    this.filterType,
    this.filterSeverity,
    required this.onApply,
  });

  @override
  State<IssueFilterSheet> createState() => _IssueFilterSheetState();
}

class _IssueFilterSheetState extends State<IssueFilterSheet> {
  String? _type;
  String? _severity;

  @override
  void initState() {
    super.initState();
    _type = widget.filterType;
    _severity = widget.filterSeverity;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: TResponsive.sp(context, 18),
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() { _type = null; _severity = null; }),
                child: Text(
                  'Clear all',
                  style: TextStyle(color: TColors.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: TResponsive.sp(context, 16)),
          Text(
            'Type',
            style: TextStyle(
              fontSize: TResponsive.sp(context, 13),
              fontWeight: FontWeight.w600,
              color: textSec,
            ),
          ),
          SizedBox(height: TResponsive.sp(context, 8)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['bug', 'feature', 'improvement', 'task', 'epic', 'story']
                .map(
                  (t) => _FilterChip(
                    label: t,
                    selected: _type == t,
                    color: issueTypeColor(t),
                    isDark: isDark,
                    onTap: () =>
                        setState(() => _type = _type == t ? null : t),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: TResponsive.sp(context, 16)),
          Text(
            'Severity',
            style: TextStyle(
              fontSize: TResponsive.sp(context, 13),
              fontWeight: FontWeight.w600,
              color: textSec,
            ),
          ),
          SizedBox(height: TResponsive.sp(context, 8)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['trivial', 'minor', 'major', 'blocker']
                .map(
                  (s) => _FilterChip(
                    label: s,
                    selected: _severity == s,
                    color: issueSeverityColor(s),
                    isDark: isDark,
                    onTap: () => setState(
                        () => _severity = _severity == s ? null : s),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: TResponsive.sp(context, 24)),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(_type, _severity);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Selectable Filter Chip ───────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: TResponsive.sp(context, 12),
            vertical: TResponsive.sp(context, 7),
          ),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? color
                  : (isDark ? TColors.darkBorder : TColors.lightBorder),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label[0].toUpperCase() + label.substring(1),
            style: TextStyle(
              fontSize: TResponsive.sp(context, 12),
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? color
                  : (isDark
                      ? TColors.textDarkSecondary
                      : TColors.textLightSecondary),
            ),
          ),
        ),
      );
}
