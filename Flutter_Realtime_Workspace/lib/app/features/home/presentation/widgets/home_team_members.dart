import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class HomeTeamMembers extends StatelessWidget {
  const HomeTeamMembers({
    super.key,
    required this.isDark,
    required this.members,
    required this.isLoading,
  });

  final bool isDark;
  final List<Map<String, dynamic>> members; // Expecting basic user maps
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return TWidgetAnimations.slideUp(
      duration: const Duration(milliseconds: 520),
      offsetY: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team Members',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? TColors.textDark : TColors.textLight,
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.push('/teams'), // Navigate to team screen
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
            height: 90,
            child: isLoading
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(right: TSizes.sm),
                      child: TSkeleton(width: 80, height: 90),
                    ),
                  )
                : members.isEmpty
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
                                Icons.groups_outlined,
                                color: isDark
                                    ? TColors.darkMuted
                                    : TColors.lightMuted,
                                size: TSizes.iconMd,
                              ),
                              const SizedBox(width: TSizes.sm),
                              Text(
                                'No team members yet',
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
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                right: index == members.length - 1
                                    ? 0
                                    : TSizes.sm),
                            child: TWidgetAnimations.fadeIn(
                              delay: Duration(milliseconds: 50 * index),
                              child:
                                  _MemberCard(member: member, isDark: isDark),
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

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.isDark});
  final Map<String, dynamic> member;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final name = member['fullName'] ?? member['displayName'] ?? 'Unknown';
    final role = member['roleTitle'] ?? 'Member';
    final avatar = member['profilePicture'] ?? member['avatar'];

    return SizedBox(
      width: 90,
      child: TCard(
        hasBorder: true,
        hasShadow: true,
        padding: const EdgeInsets.all(TSizes.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: TColors.primary.withValues(alpha: 0.1),
              backgroundImage: avatar != null && avatar.isNotEmpty
                  ? NetworkImage(avatar)
                  : null,
              child: avatar == null || avatar.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: TColors.primary, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? TColors.textDark : TColors.textLight,
              ),
            ),
            Text(
              role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                color: isDark ? TColors.darkMuted : TColors.lightMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
