import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/app/domain/models/team_model.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/team_provider.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = THelperFunctions.isDarkMode(context);
    final role = ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';
    final workspaceId = ref.read(currentUserProvider).valueOrNull?.workspaceIds.isNotEmpty == true
        ? ref.read(currentUserProvider).valueOrNull!.workspaceIds.first
        : '';
    final teamsAsync = ref.watch(teamsProvider(workspaceId));

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18,
            color: isDark ? Colors.white : TColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: TColors.quickActionGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(TSizes.radiusSm),
            ),
            child: const Icon(Icons.groups_rounded, color: TColors.quickActionGreen, size: 14),
          ),
          const SizedBox(width: 10),
          Text('Teams', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : TColors.textPrimaryLight)),
        ]),
        actions: [
          if (PermissionHelper.canCreate(role, 'team'))
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: TColors.quickActionGreen,
                  borderRadius: BorderRadius.circular(TSizes.radiusSm),
                ),
                child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
              ),
              onPressed: () => _showCreateTeamSheet(context, ref, isDark),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: teamsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 40, color: TColors.error),
          const SizedBox(height: 12),
          Text('Failed to load teams', style: TextStyle(fontSize: 13,
            color: isDark ? Colors.white : TColors.textPrimaryLight)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.invalidate(teamsProvider(workspaceId)),
            child: const Text('Retry'),
          ),
        ])),
        data: (teams) {
          if (teams.isEmpty) return _buildEmptyState(isDark);
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(TSizes.paddingMD),
            itemCount: teams.length,
            separatorBuilder: (_, __) => const SizedBox(height: TSizes.sm),
            itemBuilder: (_, i) => TWidgetAnimations.fadeIn(
              delay: Duration(milliseconds: 50 * i),
              child: _TeamCard(team: teams[i], isDark: isDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TColors.quickActionGreen.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.groups_outlined, size: 40, color: TColors.quickActionGreen),
        ),
        const SizedBox(height: TSizes.paddingMD),
        Text('No teams yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : TColors.textPrimaryLight)),
        const SizedBox(height: TSizes.sm),
        Text('Create a team to start collaborating\nwith your colleagues.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: isDark ? TColors.darkMuted : TColors.lightMuted)),
      ]),
    );
  }

  void _showCreateTeamSheet(BuildContext context, WidgetRef ref, bool isDark) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? TColors.darkCard : TColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TSizes.radiusLg)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(TSizes.paddingMD, TSizes.paddingMD,
            TSizes.paddingMD, MediaQuery.of(context).viewInsets.bottom + TSizes.paddingMD),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(
              color: isDark ? TColors.darkBorder : TColors.lightBorder,
              borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: TSizes.paddingMD),
          Text('Create Team', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : TColors.textPrimaryLight)),
          const SizedBox(height: TSizes.paddingMD),
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: 'Team Name',
              hintText: 'e.g. Engineering',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
            ),
          ),
          const SizedBox(height: TSizes.paddingSM),
          TextField(
            controller: descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'What does this team do?',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
            ),
          ),
          const SizedBox(height: TSizes.paddingMD),
          SizedBox(
            width: double.infinity,
            height: TSizes.buttonHeightMd,
            child: ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  await ref.read(teamNotifierProvider.notifier).createTeam({
                    'name': nameCtrl.text.trim(),
                    if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                  });
                  if (context.mounted) Navigator.pop(context);
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.quickActionGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TSizes.radiusMd)),
              ),
              child: const Text('Create Team', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamModel team;
  final bool isDark;

  const _TeamCard({required this.team, required this.isDark});

  Color get _typeColor {
    switch (team.type) {
      case 'startup': return TColors.quickActionPurple;
      case 'agency': return TColors.quickActionYellow;
      case 'non-profit': return TColors.quickActionGreen;
      case 'educational': return TColors.quickActionBlue;
      default: return TColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to team detail
        },
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(TSizes.paddingSM + 4),
          decoration: BoxDecoration(
            color: isDark ? TColors.darkCard : TColors.lightSurface,
            borderRadius: BorderRadius.circular(TSizes.radiusMd),
            border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder, width: 0.8),
            boxShadow: [
              BoxShadow(color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.04),
                blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Row(children: [
            // Avatar
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_typeColor, _typeColor.withValues(alpha: 0.6)]),
                borderRadius: BorderRadius.circular(TSizes.radiusMd),
              ),
              child: Center(child: Text(
                team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              )),
            ),
            const SizedBox(width: TSizes.paddingSM),
            // Info
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(team.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : TColors.textPrimaryLight))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(team.type, style: TextStyle(fontSize: 9,
                      fontWeight: FontWeight.w600, color: _typeColor)),
                  ),
                ]),
                if (team.description != null && team.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(team.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10,
                      color: isDark ? TColors.darkMuted : TColors.lightMuted)),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.people_outline, size: 12,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted),
                  const SizedBox(width: 4),
                  Text('${team.members.length} members', style: TextStyle(fontSize: 10,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted)),
                  const SizedBox(width: 12),
                  Icon(Icons.folder_outlined, size: 12,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted),
                  const SizedBox(width: 4),
                  Text('${team.projects.length} projects', style: TextStyle(fontSize: 10,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted)),
                  const Spacer(),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: team.isActive ? TColors.success : TColors.neutralGray,
                      shape: BoxShape.circle,
                    ),
                  ),
                ]),
              ],
            )),
            const SizedBox(width: TSizes.sm),
            Icon(Icons.arrow_forward_ios_rounded, size: 12,
              color: isDark ? TColors.darkMuted : TColors.lightMuted),
          ]),
        ),
      ),
    );
  }
}
