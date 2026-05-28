import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/organizations/usecases/organization_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/organization_provider.dart';

/// Organization overview screen — shows org info, quotas, and quick actions.
class OrganizationScreen extends ConsumerWidget {
  const OrganizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final orgAsync = ref.watch(activeOrganizationProvider);

    return Scaffold(
      backgroundColor:
          isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: SAppBar(
        title: 'Organization',
        showBack: true,
        actions: [
          if (OrganizationUseCase.canEditOrganization(ref))
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit',
            ),
        ],
      ),
      body: orgAsync.when(
        loading: () => Padding(
          padding: EdgeInsets.all(hPad),
          child: Column(
            children: List.generate(
                3,
                (_) => const Padding(
                    padding: EdgeInsets.only(bottom: TSizes.sm),
                    child: TSkeleton(height: 80))),
          ),
        ),
        error: (_, __) => Center(
          child: Text(
            'Unable to load organization',
            style: TextStyle(
                color: isDark
                    ? TColors.textSecondaryDark
                    : TColors.textSecondaryLight),
          ),
        ),
        data: (org) {
          if (org == null) {
            return Center(
              child: Text(
                'No organization found',
                style: TextStyle(
                    color: isDark
                        ? TColors.textSecondaryDark
                        : TColors.textSecondaryLight),
              ),
            );
          }

          Color brandColor;
          try {
            brandColor = Color(
                int.parse(org.primaryColor.replaceFirst('#', '0xFF')));
          } catch (_) {
            brandColor = TColors.primary;
          }

          return ListView(
            padding: EdgeInsets.symmetric(
                horizontal: hPad, vertical: TSizes.md),
            children: [
              // ── Brand header ──
              TCard(
                padding: EdgeInsets.all(TResponsive.sp(context, TSizes.lg)),
                child: Column(
                  children: [
                    Container(
                      width: TResponsive.sp(context, 64),
                      height: TResponsive.sp(context, 64),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            brandColor,
                            brandColor.withValues(alpha: 0.6)
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(TSizes.radiusLg),
                      ),
                      child: Center(
                        child: org.logo != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    TSizes.radiusMd),
                                child: Image.network(
                                  org.logo!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Text(
                                    org.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                org.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: TSizes.md),
                    Text(
                      org.name,
                      style: TextStyle(
                        fontSize: TResponsive.sp(context, 20),
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? TColors.textPrimaryDark
                            : TColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      org.slug,
                      style: TextStyle(
                        fontSize: TResponsive.sp(context, 13),
                        color: isDark
                            ? TColors.textSecondaryDark
                            : TColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: TSizes.sm),
                    _PlanBadge(plan: org.plan, status: org.status),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.lg),

              // ── Quota usage ──
              _SectionLabel(label: 'QUOTAS'),
              const SizedBox(height: TSizes.sm),
              _QuotaGrid(org: org),
              const SizedBox(height: TSizes.lg),

              // ── Org details ──
              _SectionLabel(label: 'DETAILS'),
              const SizedBox(height: TSizes.sm),
              _DetailCard(org: org),
              const SizedBox(height: TSizes.lg),

              // ── Quick actions ──
              Row(
                children: [
                  Expanded(
                    child: TButton(
                      text: 'Members',
                      variant: SButtonVariant.outline,
                      size: SButtonSize.sm,
                      prefixIcon: Icons.people_outlined,
                      onPressed: () => context.go('/organization/members'),
                    ),
                  ),
                  const SizedBox(width: TSizes.sm),
                  Expanded(
                    child: TButton(
                      text: 'Invite',
                      variant: SButtonVariant.primary,
                      size: SButtonSize.sm,
                      prefixIcon: Icons.person_add_alt_1_outlined,
                      onPressed: OrganizationUseCase.canManageMembers(ref)
                          ? () => context.go('/organization/invite')
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.xxl),
            ],
          );
        },
      ),
    );
  }
}

// ── Extracted widgets ──────────────────────────────────────────────────────

class _PlanBadge extends StatelessWidget {
  final String plan;
  final String status;
  const _PlanBadge({required this.plan, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (plan) {
      'enterprise' => TColors.quickActionPurple,
      'professional' => TColors.quickActionBlue,
      'starter' => TColors.quickActionGreen,
      _ => TColors.neutralGray,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(TSizes.radiusFull),
          ),
          child: Text(
            plan.toUpperCase(),
            style: TextStyle(
              fontSize: TResponsive.sp(context, 10),
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: status == 'active' ? TColors.success : TColors.warning,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          status,
          style: TextStyle(
            fontSize: TResponsive.sp(context, 11),
            color: Theme.of(context).brightness == Brightness.dark
                ? TColors.textSecondaryDark
                : TColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _QuotaGrid extends StatelessWidget {
  final dynamic org;
  const _QuotaGrid({required this.org});

  @override
  Widget build(BuildContext context) {
    final q = org.quotas;
    return Wrap(
      spacing: TSizes.sm,
      runSpacing: TSizes.sm,
      children: [
        _QuotaChip(
            label: 'Members',
            value: '${org.memberCount}/${q.maxMembers}',
            icon: Icons.people_outlined,
            ratio: org.memberCount / q.maxMembers),
        _QuotaChip(
            label: 'Workspaces',
            value: '–/${q.maxWorkspaces}',
            icon: Icons.workspaces_outlined,
            ratio: 0),
        _QuotaChip(
            label: 'Storage',
            value: '${q.maxStorageGB} GB',
            icon: Icons.cloud_outlined,
            ratio: 0),
        _QuotaChip(
            label: 'AI Credits',
            value: '${q.aiCredits}',
            icon: Icons.auto_awesome_outlined,
            ratio: 0),
      ],
    );
  }
}

class _QuotaChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double ratio;
  const _QuotaChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.ratio});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeRatio = ratio.clamp(0.0, 1.0);

    return SizedBox(
      width: (TResponsive.width(context) - TResponsive.pagePadding(context) * 2 - TSizes.sm) / 2,
      child: TCard(
        hasBorder: true,
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: TResponsive.sp(context, 16),
                    color: isDark
                        ? TColors.textSecondaryDark
                        : TColors.textSecondaryLight),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                      fontSize: TResponsive.sp(context, 12),
                      color: isDark
                          ? TColors.textSecondaryDark
                          : TColors.textSecondaryLight,
                    )),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                  fontSize: TResponsive.sp(context, 16),
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? TColors.textPrimaryDark
                      : TColors.textPrimaryLight,
                )),
            if (safeRatio > 0) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: safeRatio,
                  minHeight: 4,
                  backgroundColor:
                      isDark ? TColors.darkBorder : TColors.lightBorder,
                  valueColor: AlwaysStoppedAnimation(
                      safeRatio > 0.8 ? TColors.warning : TColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final dynamic org;
  const _DetailCard({required this.org});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight;
    final valueColor =
        isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight;

    return TCard(
      hasBorder: true,
      child: Column(
        children: [
          _row(context, 'Industry', org.industry ?? '–', labelColor,
              valueColor),
          _divider(isDark),
          _row(context, 'Size', org.size ?? '–', labelColor, valueColor),
          _divider(isDark),
          _row(context, 'Timezone', org.timezone, labelColor, valueColor),
          _divider(isDark),
          _row(context, 'Country', org.country ?? '–', labelColor,
              valueColor),
          if (org.website != null) ...[
            _divider(isDark),
            _row(context, 'Website', org.website!, labelColor, valueColor),
          ],
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
      height: 1,
      color: isDark ? TColors.darkBorder : TColors.lightBorder);

  Widget _row(BuildContext context, String label, String value,
      Color labelColor, Color valueColor) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: TResponsive.sp(context, 13),
                  color: labelColor)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: TResponsive.sp(context, 13),
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                )),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: TextStyle(
        fontSize: TResponsive.sp(context, 11),
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: isDark
            ? TColors.textSecondaryDark
            : TColors.textSecondaryLight,
      ),
    );
  }
}
