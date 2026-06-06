import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/domain/models/project_model.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/project_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class HomeProjectsCarousel extends StatelessWidget {
  const HomeProjectsCarousel({
    super.key,
    required this.isDark,
    required this.projects,
    required this.isLoading,
  });

  final bool isDark;
  final List<ProjectModel> projects;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return TWidgetAnimations.slideUp(
      duration: const Duration(milliseconds: 500),
      offsetY: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Projects',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? TColors.textDark : TColors.textLight,
                ),
              ),
              TextButton(
                onPressed: () => context
                    .push('/projects'), // Should ideally switch to projects tab
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? TColors.blue400 : TColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.sm, vertical: TSizes.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('See all',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          SizedBox(
            height: 120,
            child: isLoading
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(right: TSizes.sm),
                      child: TSkeleton(width: 240, height: 120),
                    ),
                  )
                : projects.isEmpty
                    ? SizedBox(
                        width: double.infinity,
                        child: TCard(
                          hasBorder: true,
                          padding: const EdgeInsets.symmetric(
                              vertical: TSizes.md, horizontal: TSizes.sm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_off_outlined,
                                color: isDark
                                    ? TColors.darkMuted
                                    : TColors.lightMuted,
                                size: TSizes.iconMd,
                              ),
                              const SizedBox(width: TSizes.sm),
                              Text(
                                'No active projects',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? TColors.darkMuted
                                      : TColors.lightMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                right: index == projects.length - 1
                                    ? 0
                                    : TSizes.sm),
                            child: TWidgetAnimations.fadeIn(
                              delay: Duration(milliseconds: 50 * index),
                              child: _ProjectCard(
                                  project: project, isDark: isDark),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.isDark});
  final ProjectModel project;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final statusLabel = ProjectUseCase.statusLabel(project.status);
    final memberCount = project.members.length + project.collaborators.length;
    final progressPct = (project.progress * 100).toInt();

    Color badgeColor;
    switch (project.status.toLowerCase()) {
      case 'in_progress':
      case 'active':
        badgeColor = const Color(0xFF3B82F6);
        break;
      case 'review':
        badgeColor = const Color(0xFFF59E0B);
        break;
      case 'completed':
        badgeColor = const Color(0xFF10B981);
        break;
      default:
        badgeColor = const Color(0xFF64748B);
    }

    return GestureDetector(
        onTap: () {}, // Ideally navigates to project details timeline
        child: SizedBox(
          width: 240,
          child: TCard(
            hasBorder: true,
            hasShadow: true,
            padding: const EdgeInsets.all(TSizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(int.tryParse(
                                    project.color?.replaceFirst('#', '0xFF') ??
                                        '') ??
                                0xFF1E40AF)
                            .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.folder_open,
                        color: Color(int.tryParse(
                                project.color?.replaceFirst('#', '0xFF') ??
                                    '') ??
                            0xFF1E40AF),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : TColors.cardColorDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.people_outline,
                        size: 12,
                        color: isDark
                            ? Colors.white60
                            : TColors.textTertiaryLight),
                    const SizedBox(width: 2),
                    Text('$memberCount members',
                        style: TextStyle(
                            fontSize: 9,
                            color: isDark
                                ? Colors.white60
                                : TColors.textTertiaryLight)),
                    if (project.priority == 'high' ||
                        project.priority == 'critical') ...[
                      const SizedBox(width: 8),
                      Icon(Icons.flag_rounded,
                          size: 10,
                          color: project.priority == 'critical'
                              ? TColors.error
                              : TColors.warning),
                      const SizedBox(width: 2),
                      Text(ProjectUseCase.priorityLabel(project.priority),
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: project.priority == 'critical'
                                  ? TColors.error
                                  : TColors.warning)),
                    ],
                    const Spacer(),
                    Text('$progressPct% complete',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white70
                                : TColors.cardColorDark)),
                  ],
                ),
                LinearProgressIndicator(
                  value: project.progress,
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ));
  }
}
