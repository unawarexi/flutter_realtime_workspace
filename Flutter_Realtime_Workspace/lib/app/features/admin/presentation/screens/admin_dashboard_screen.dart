import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = THelperFunctions.isDarkMode(context);
    final role = ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

    if (!PermissionHelper.canAccessAdmin(role)) {
      return Scaffold(
        backgroundColor: isDark ? TColors.backgroundDarkAlt : TColors.backgroundLight,
        appBar: _appBar(context, isDark),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TColors.error.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.gpp_bad_outlined, size: 48, color: TColors.error),
          ),
          const SizedBox(height: TSizes.paddingMD),
          Text('Access Denied', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : TColors.textPrimaryLight)),
          const SizedBox(height: TSizes.sm),
          Text('This area is restricted to administrators.',
            style: TextStyle(fontSize: 12, color: isDark ? TColors.darkMuted : TColors.lightMuted)),
        ])),
      );
    }

    final statsAsync = ref.watch(adminStatsProvider);
    final tenantsAsync = ref.watch(adminTenantsProvider);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      appBar: _appBar(context, isDark),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(TSizes.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TWidgetAnimations.slideUp(
                    child: statsAsync.when(
                      loading: () => const Center(child: Padding(
                        padding: EdgeInsets.all(30), child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (e, _) => _errorCard(isDark, 'Stats failed', () => ref.invalidate(adminStatsProvider)),
                      data: (stats) => _buildStatsGrid(isDark, stats),
                    ),
                  ),
                  const SizedBox(height: TSizes.paddingLG),
                  TWidgetAnimations.fadeIn(
                    delay: const Duration(milliseconds: 100),
                    child: _buildQuickActions(context, isDark, role),
                  ),
                  const SizedBox(height: TSizes.paddingLG),
                  if (PermissionHelper.isSuperAdmin(role)) ...[
                    TWidgetAnimations.fadeIn(
                      delay: const Duration(milliseconds: 200),
                      child: Text('Tenants', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : TColors.textPrimaryLight)),
                    ),
                    const SizedBox(height: TSizes.sm),
                    tenantsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, _) => _errorCard(isDark, 'Tenants failed', () => ref.invalidate(adminTenantsProvider)),
                      data: (tenants) => Column(
                        children: tenants.take(5).map((t) => _buildTenantCard(isDark, ref, t)).toList(),
                      ),
                    ),
                    const SizedBox(height: TSizes.paddingLG),
                  ],
                  TWidgetAnimations.fadeIn(
                    delay: const Duration(milliseconds: 300),
                    child: _buildAuditCard(context, isDark),
                  ),
                  const SizedBox(height: TSizes.paddingXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0, backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18,
          color: isDark ? Colors.white : TColors.textPrimaryLight),
        onPressed: () => Navigator.pop(context)),
      title: Row(children: [
        Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: TColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(TSizes.radiusSm)),
          child: const Icon(Icons.admin_panel_settings_rounded, color: TColors.error, size: 14)),
        const SizedBox(width: 10),
        Text('Admin Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : TColors.textPrimaryLight)),
      ]),
    );
  }

  Widget _buildStatsGrid(bool isDark, Map<String, dynamic> s) {
    final items = [
      ('Users', '${s['totalUsers'] ?? s['userCount'] ?? 0}', Icons.people_rounded, TColors.quickActionBlue),
      ('Projects', '${s['totalProjects'] ?? s['projectCount'] ?? 0}', Icons.folder_rounded, TColors.quickActionPurple),
      ('Teams', '${s['totalTeams'] ?? s['teamCount'] ?? 0}', Icons.groups_rounded, TColors.quickActionGreen),
      ('Tenants', '${s['totalTenants'] ?? s['tenantCount'] ?? 0}', Icons.business_rounded, TColors.quickActionYellow),
    ];
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: TSizes.sm, crossAxisSpacing: TSizes.sm, childAspectRatio: 1.6,
      children: items.map((e) => Container(
        padding: const EdgeInsets.all(TSizes.paddingSM + 2),
        decoration: BoxDecoration(
          color: isDark ? TColors.darkCard : TColors.lightSurface,
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder, width: 0.8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: e.$4.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(TSizes.radiusSm)),
            child: Icon(e.$3, size: 14, color: e.$4)),
          const Spacer(),
          Text(e.$2, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : TColors.textPrimaryLight)),
          const SizedBox(height: 2),
          Text(e.$1, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
            color: isDark ? TColors.darkMuted : TColors.lightMuted)),
        ]),
      )).toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark, String role) {
    return Container(
      padding: const EdgeInsets.all(TSizes.paddingMD),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : TColors.lightSurface,
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder, width: 0.8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.flash_on_rounded, size: 16, color: isDark ? TColors.blue400 : TColors.primary),
          const SizedBox(width: 8),
          Text('Quick Actions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : TColors.textPrimaryLight)),
        ]),
        const SizedBox(height: TSizes.paddingSM),
        Wrap(spacing: TSizes.sm, runSpacing: TSizes.sm, children: [
          _chip(context, isDark, 'Manage Users', Icons.people_outline, '/admin/users'),
          _chip(context, isDark, 'View Logs', Icons.receipt_long_outlined, '/admin/logs'),
          _chip(context, isDark, 'Approvals', Icons.check_circle_outline, '/admin/approvals'),
          if (PermissionHelper.isSuperAdmin(role))
            _chip(context, isDark, 'Impersonate', Icons.swap_horiz_rounded, '/admin/impersonate'),
        ]),
      ]),
    );
  }

  Widget _chip(BuildContext context, bool isDark, String label, IconData icon, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? TColors.darkElevated : TColors.lightElevated,
          borderRadius: BorderRadius.circular(TSizes.radiusSm),
          border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder, width: 0.6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: isDark ? TColors.blue400 : TColors.primary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : TColors.textPrimaryLight)),
        ]),
      ),
    );
  }

  Widget _buildTenantCard(bool isDark, WidgetRef ref, Map<String, dynamic> t) {
    final name = t['name'] as String? ?? t['orgName'] as String? ?? 'Unknown';
    final status = t['status'] as String? ?? 'active';
    final users = t['userCount'] ?? t['memberCount'] ?? 0;
    final active = status == 'active';
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Container(
        padding: const EdgeInsets.all(TSizes.paddingSM + 2),
        decoration: BoxDecoration(
          color: isDark ? TColors.darkCard : TColors.lightSurface,
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder, width: 0.8)),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              color: (active ? TColors.success : TColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(TSizes.radiusSm)),
            child: Icon(Icons.business_rounded, size: 16, color: active ? TColors.success : TColors.error)),
          const SizedBox(width: TSizes.paddingSM),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : TColors.textPrimaryLight)),
            Text('$users users • $status', style: TextStyle(fontSize: 10,
              color: isDark ? TColors.darkMuted : TColors.lightMuted)),
          ])),
          GestureDetector(
            onTap: () async {
              final id = t['_id'] as String? ?? t['id'] as String? ?? '';
              if (id.isEmpty) return;
              await ref.read(adminActionsProvider.notifier).updateTenantStatus(id, active ? 'suspended' : 'active');
              ref.invalidate(adminTenantsProvider);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (active ? TColors.error : TColors.success).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4)),
              child: Text(active ? 'Suspend' : 'Activate',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                  color: active ? TColors.error : TColors.success)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAuditCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/admin/logs'),
      child: Container(
        padding: const EdgeInsets.all(TSizes.paddingMD),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            TColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
            TColors.quickActionPurple.withValues(alpha: isDark ? 0.1 : 0.05)]),
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          border: Border.all(color: TColors.primary.withValues(alpha: 0.15))),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(TSizes.radiusSm)),
            child: Icon(Icons.receipt_long_rounded, size: 18, color: isDark ? TColors.blue400 : TColors.primary)),
          const SizedBox(width: TSizes.paddingSM),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Audit Logs', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : TColors.textPrimaryLight)),
            Text('View system activity and security events', style: TextStyle(fontSize: 10,
              color: isDark ? TColors.darkMuted : TColors.lightMuted)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14,
            color: isDark ? TColors.darkMuted : TColors.lightMuted),
        ]),
      ),
    );
  }

  Widget _errorCard(bool isDark, String msg, VoidCallback retry) {
    return Container(
      padding: const EdgeInsets.all(TSizes.paddingMD),
      decoration: BoxDecoration(
        color: TColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(TSizes.radiusMd)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: TColors.error, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 12, color: TColors.error))),
        TextButton(onPressed: retry, child: const Text('Retry', style: TextStyle(fontSize: 11))),
      ]),
    );
  }
}
