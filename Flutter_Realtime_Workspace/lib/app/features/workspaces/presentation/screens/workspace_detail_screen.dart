import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/workspace_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';

/// Detail screen showing workspace info, members, and settings.
class WorkspaceDetailScreen extends ConsumerWidget {
  const WorkspaceDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ws = WorkspaceUseCase.activeWorkspace(ref);
    final hPad = TResponsive.pagePadding(context);

    if (ws == null) {
      return Scaffold(
        appBar: const SAppBar(title: 'Workspace', showBack: true),
        body: const Center(child: Text('No workspace selected')),
      );
    }

    final membersAsync = ref.watch(workspaceMembersProvider(ws.id));
    final canEdit = WorkspaceUseCase.canEditWorkspace(ref);

    return Scaffold(
      backgroundColor:
          isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: SAppBar(
        title: ws.name,
        showBack: true,
        actions: [
          if (canEdit)
            IconButton(
              onPressed: () {
                // TODO: Edit workspace
              },
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            WorkspaceUseCase.refreshWorkspace(context: context, ref: ref, id: ws.id),
        child: ListView(
          padding:
              EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.md),
          children: [
            // ── Header card ──
            _HeaderCard(workspace: ws),
            const SizedBox(height: TSizes.lg),

            // ── Stats row ──
            _StatsGrid(workspace: ws),
            const SizedBox(height: TSizes.lg),

            // ── Members section ──
            _SectionTitle(title: 'Members', count: ws.memberCount),
            const SizedBox(height: TSizes.sm),
            membersAsync.when(
              loading: () => Column(
                children: List.generate(3, (_) =>
                    const Padding(
                      padding: EdgeInsets.only(bottom: TSizes.sm),
                      child: TSkeleton(height: 56),
                    )),
              ),
              error: (_, __) => Text(
                'Unable to load members',
                style: TextStyle(
                    color: isDark
                        ? TColors.textSecondaryDark
                        : TColors.textSecondaryLight),
              ),
              data: (members) => Column(
                children: members.map((m) => _MemberTile(member: m)).toList(),
              ),
            ),
            const SizedBox(height: TSizes.lg),

            // ── Settings ──
            _SectionTitle(title: 'Settings'),
            const SizedBox(height: TSizes.sm),
            _SettingsCard(workspace: ws),
            const SizedBox(height: TSizes.lg),

            // ── Quick actions ──
            Row(
              children: [
                Expanded(
                  child: TButton(
                    text: 'Projects',
                    variant: SButtonVariant.outline,
                    size: SButtonSize.sm,
                    prefixIcon: Icons.folder_outlined,
                    onPressed: () => context.go('/projects'),
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: TButton(
                    text: 'Channels',
                    variant: SButtonVariant.outline,
                    size: SButtonSize.sm,
                    prefixIcon: Icons.chat_bubble_outline,
                    onPressed: () => context.go('/chat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.xxl),
          ],
        ),
      ),
    );
  }
}

// ── Extracted widgets ──────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final dynamic workspace;
  const _HeaderCard({required this.workspace});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color color;
    try {
      color = Color(int.parse(
          (workspace.color as String).replaceFirst('#', '0xFF')));
    } catch (_) {
      color = TColors.primary;
    }

    return TCard(
      padding: EdgeInsets.all(TResponsive.sp(context, TSizes.lg)),
      child: Column(
        children: [
          Container(
            width: TResponsive.sp(context, 64),
            height: TResponsive.sp(context, 64),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(TSizes.radiusLg),
            ),
            child: Center(
              child: Text(
                workspace.icon ?? workspace.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: TResponsive.sp(context, 28),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: TSizes.md),
          Text(
            workspace.name,
            style: TextStyle(
              fontSize: TResponsive.sp(context, 18),
              fontWeight: FontWeight.w700,
              color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight,
            ),
          ),
          if (workspace.description != null &&
              (workspace.description as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                workspace.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: TResponsive.sp(context, 13),
                  color: isDark
                      ? TColors.textSecondaryDark
                      : TColors.textSecondaryLight,
                ),
              ),
            ),
          const SizedBox(height: TSizes.sm),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(TSizes.radiusFull),
            ),
            child: Text(
              workspace.settings.visibility.toUpperCase(),
              style: TextStyle(
                fontSize: TResponsive.sp(context, 10),
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final dynamic workspace;
  const _StatsGrid({required this.workspace});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell(
            icon: Icons.folder_outlined,
            label: 'Projects',
            value: '${workspace.projectCount}',
            color: TColors.quickActionBlue),
        const SizedBox(width: TSizes.sm),
        _StatCell(
            icon: Icons.people_outlined,
            label: 'Members',
            value: '${workspace.memberCount}',
            color: TColors.quickActionGreen),
        const SizedBox(width: TSizes.sm),
        _StatCell(
            icon: Icons.chat_bubble_outline,
            label: 'Channels',
            value: '${workspace.channelCount}',
            color: TColors.quickActionPurple),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCell(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: TCard(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: TResponsive.sp(context, 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: TResponsive.sp(context, 18),
                fontWeight: FontWeight.w700,
                color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: TResponsive.sp(context, 11),
                color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Map<String, dynamic> member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = member['role'] ?? 'member';

    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.xs),
      child: TCard(
        hasBorder: true,
        padding: const EdgeInsets.symmetric(
            horizontal: TSizes.md, vertical: TSizes.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: TColors.primary.withValues(alpha: 0.15),
              child: Text(
                (member['name'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: TColors.primary),
              ),
            ),
            const SizedBox(width: TSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member['name'] ?? member['email'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: TResponsive.sp(context, 14),
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? TColors.textPrimaryDark
                          : TColors.textPrimaryLight,
                    ),
                  ),
                  if (member['email'] != null)
                    Text(
                      member['email'],
                      style: TextStyle(
                        fontSize: TResponsive.sp(context, 11),
                        color: isDark
                            ? TColors.textSecondaryDark
                            : TColors.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor(role).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(TSizes.radiusFull),
              ),
              child: Text(
                role.replaceAll('_', ' '),
                style: TextStyle(
                  fontSize: TResponsive.sp(context, 10),
                  fontWeight: FontWeight.w600,
                  color: _roleColor(role),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'workspace_admin':
        return TColors.quickActionPurple;
      case 'manager':
        return TColors.quickActionBlue;
      case 'member':
        return TColors.quickActionGreen;
      default:
        return TColors.neutralGray;
    }
  }
}

class _SettingsCard extends StatelessWidget {
  final dynamic workspace;
  const _SettingsCard({required this.workspace});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = workspace.settings;
    final textColor =
        isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight;

    return TCard(
      hasBorder: true,
      child: Column(
        children: [
          _row(context, 'Visibility', settings.visibility, textColor),
          Divider(
              height: 1,
              color: isDark ? TColors.darkBorder : TColors.lightBorder),
          _row(context, 'Default Template',
              settings.defaultProjectTemplate, textColor),
          Divider(
              height: 1,
              color: isDark ? TColors.darkBorder : TColors.lightBorder),
          _row(context, 'Allow Guests',
              settings.allowGuests ? 'Yes' : 'No', textColor),
          Divider(
              height: 1,
              color: isDark ? TColors.darkBorder : TColors.lightBorder),
          _row(context, 'Notifications',
              settings.notificationsEnabled ? 'Enabled' : 'Disabled',
              textColor),
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, String label, String value, Color color) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: TResponsive.sp(context, 13), color: color)),
          Text(value,
              style: TextStyle(
                fontSize: TResponsive.sp(context, 13),
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? TColors.textPrimaryDark
                    : TColors.textPrimaryLight,
              )),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int? count;
  const _SectionTitle({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: TResponsive.sp(context, 11),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: isDark
                ? TColors.textSecondaryDark
                : TColors.textSecondaryLight,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: TColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(TSizes.radiusFull),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: TResponsive.sp(context, 10),
                fontWeight: FontWeight.w600,
                color: TColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
