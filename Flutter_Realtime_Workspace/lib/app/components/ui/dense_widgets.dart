import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

// ============================================================================
// DENSE SECTION HEADER — compact "title + action" row
// ============================================================================
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? TColors.textDark : TColors.textLight,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (actionLabel != null || actionIcon != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (actionLabel != null)
                    Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: TColors.primary,
                      ),
                    ),
                  if (actionIcon != null) ...[
                    const SizedBox(width: 2),
                    Icon(actionIcon, size: 14, color: TColors.primary),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// DENSE LIST TILE — compact info row with icon, title, subtitle, trailing
// ============================================================================
class DenseTile extends StatefulWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool hasDivider;

  const DenseTile({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBgColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.showChevron = false,
    this.hasDivider = false,
  });

  @override
  State<DenseTile> createState() => _DenseTileState();
}

class _DenseTileState extends State<DenseTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        GestureDetector(
          onTapDown: widget.onTap != null
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.onTap != null
              ? (_) {
                  setState(() => _pressed = false);
                  HapticFeedback.selectionClick();
                  widget.onTap?.call();
                }
              : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            decoration: BoxDecoration(
              color: _pressed
                  ? (isDark ? TColors.darkHover : TColors.lightHover)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(TSizes.radiusSm),
            ),
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 12),
                ] else if (widget.icon != null) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.iconBgColor ??
                          (isDark
                              ? TColors.darkElevated
                              : TColors.lightElevated),
                      borderRadius: BorderRadius.circular(TSizes.radiusSm),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 17,
                      color: widget.iconColor ??
                          (isDark
                              ? TColors.textDarkSecondary
                              : TColors.textLightSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark ? TColors.textDark : TColors.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? TColors.textDarkTertiary
                                : TColors.textLightTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 8),
                  widget.trailing!,
                ],
                if (widget.showChevron) ...[
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: isDark
                        ? TColors.textDarkTertiary
                        : TColors.textLightTertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.hasDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: widget.icon != null ? 50 : 0,
            color: isDark ? TColors.darkBorder : TColors.lightBorder,
          ),
      ],
    );
  }
}

// ============================================================================
// STAT CARD — compact metric display
// ============================================================================
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? change;
  final bool isPositive;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = TColors.primary,
    this.change,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : TColors.lightCard,
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        border: Border.all(
          color: isDark ? TColors.darkBorder : TColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const Spacer(),
              if (change != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive ? TColors.success : TColors.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(TSizes.radiusFull),
                  ),
                  child: Text(
                    change!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? TColors.success : TColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? TColors.textDark : TColors.textLight,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? TColors.textDarkTertiary
                  : TColors.textLightTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CHIP — compact tag / filter chip
// ============================================================================
class TChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  const TChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = color ?? TColors.primary;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.15)
              : (isDark ? TColors.darkElevated : TColors.lightElevated),
          borderRadius: BorderRadius.circular(TSizes.radiusFull),
          border: Border.all(
            color: isSelected
                ? chipColor.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? chipColor : (isDark ? TColors.textDarkSecondary : TColors.textLightSecondary)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? chipColor
                    : (isDark
                        ? TColors.textDarkSecondary
                        : TColors.textLightSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// AVATAR — compact user avatar with online indicator
// ============================================================================
class TAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool showOnline;
  final bool isOnline;

  const TAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 36,
    this.showOnline = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = name.isNotEmpty
        ? name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase()
        : '?';
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor:
                isDark ? TColors.darkElevated : TColors.lightElevated,
            backgroundImage:
                imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? Text(
                    initials,
                    style: TextStyle(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w600,
                      color: TColors.primary,
                    ),
                  )
                : null,
          ),
          if (showOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: isOnline ? TColors.success : TColors.darkMuted,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? TColors.darkBg : TColors.lightBg,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATUS BADGE — live / scheduled / ended
// ============================================================================
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool pulse;

  const StatusBadge({
    super.key,
    required this.label,
    this.color = TColors.success,
    this.pulse = false,
  });

  factory StatusBadge.live() =>
      const StatusBadge(label: 'LIVE', color: TColors.error, pulse: true);
  factory StatusBadge.scheduled() =>
      const StatusBadge(label: 'Scheduled', color: TColors.primary);
  factory StatusBadge.ended() =>
      const StatusBadge(label: 'Ended', color: TColors.darkMuted);
  factory StatusBadge.recording() =>
      const StatusBadge(label: 'REC', color: TColors.error, pulse: true);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE — placeholder with icon and message
// ============================================================================
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subMessage;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subMessage,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? TColors.darkElevated : TColors.lightElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: isDark
                    ? TColors.textDarkTertiary
                    : TColors.textLightTertiary,
              ),
            ),
            const SizedBox(height: TSizes.md),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.textDark : TColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                subMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? TColors.textDarkTertiary
                      : TColors.textLightTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: TSizes.md),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SEARCH BAR — compact iOS-style search
// ============================================================================
class TSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;

  const TSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? TColors.darkElevated : TColors.lightElevated,
          borderRadius: BorderRadius.circular(TSizes.radiusSm),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          readOnly: readOnly,
          autofocus: autofocus,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? TColors.textDark : TColors.textLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark
                  ? TColors.textDarkTertiary
                  : TColors.textLightTertiary,
            ),
            prefixIcon: Icon(
              CupertinoIcons.search,
              size: 17,
              color: isDark
                  ? TColors.textDarkTertiary
                  : TColors.textLightTertiary,
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 38, minHeight: 38),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 9),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TOGGLE ROW — settings toggle with label
// ============================================================================
class ToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const ToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? TColors.darkElevated : TColors.lightElevated,
                borderRadius: BorderRadius.circular(TSizes.radiusSm),
              ),
              child: Icon(
                icon,
                size: 17,
                color: isDark
                    ? TColors.textDarkSecondary
                    : TColors.textLightSecondary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? TColors.textDark : TColors.textLight,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? TColors.textDarkTertiary
                          : TColors.textLightTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: TColors.primary,
          ),
        ],
      ),
    );
  }
}
