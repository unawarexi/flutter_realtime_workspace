import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final hPad = TResponsive.pagePadding(context);
    final roomsAsync = ref.watch(chatRoomsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: SAppBar(
        title: 'Messages',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, TSizes.sm, hPad, TSizes.sm),
          child: TSearchBar(hint: 'Search conversations...', onChanged: (v) => setState(() => _query = v)),
        ),
        Expanded(
          child: roomsAsync.when(
            loading: () => Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(children: List.generate(6, (_) => const Padding(
                padding: EdgeInsets.only(bottom: TSizes.sm),
                child: TSkeleton(height: 72),
              ))),
            ),
            error: (_, __) => const Center(child: Text('Failed to load messages')),
            data: (rooms) {
              final filtered = _query.isEmpty
                  ? rooms
                  : rooms.where((r) =>
                      (r.name ?? '').toLowerCase().contains(_query.toLowerCase()) ||
                      r.members.any((m) => (m.fullName ?? '').toLowerCase().contains(_query.toLowerCase()))).toList();

              if (filtered.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Iconsax.message, size: 56, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                  const SizedBox(height: TSizes.md),
                  Text('No conversations yet', style: TextStyle(
                    fontSize: TResponsive.sp(context, 16),
                    fontWeight: FontWeight.w600,
                    color: isDark ? TColors.textDark : TColors.textLight,
                  )),
                  const SizedBox(height: 6),
                  Text('Start a new message to connect with your team.', style: TextStyle(
                    fontSize: TResponsive.sp(context, 13),
                    color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
                  )),
                ]));
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(chatRoomsProvider),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? TColors.darkBorder : TColors.lightBorder,
                  ),
                  itemBuilder: (_, i) {
                    final room = filtered[i];
                    final displayName = room.isGroup
                        ? (room.name ?? 'Group Chat')
                        : room.members.where((m) => m.userId != currentUser?.id).firstOrNull?.fullName ?? 'Chat';
                    final avatar = room.isGroup ? null
                        : room.members.where((m) => m.userId != currentUser?.id).firstOrNull?.avatar;
                    final lastMsg = room.lastMessage;
                    final hasUnread = room.unreadCount > 0;

                    return InkWell(
                      onTap: () => context.go('/chat/${room.id}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(children: [
                          Stack(children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: TColors.primary.withValues(alpha: 0.12),
                              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                              child: avatar == null
                                  ? Icon(room.isGroup ? Iconsax.people : Iconsax.user, size: 22, color: TColors.primary)
                                  : null,
                            ),
                            if (!room.isGroup) Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(
                                  color: TColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? TColors.backgroundDark : TColors.backgroundLight, width: 2),
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(width: TSizes.sm),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Expanded(child: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                                fontSize: TResponsive.sp(context, 15),
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                                color: isDark ? TColors.textDark : TColors.textLight,
                              ))),
                              if (lastMsg != null) Text(
                                _timeAgo(lastMsg.createdAt),
                                style: TextStyle(
                                  fontSize: TResponsive.sp(context, 11),
                                  color: hasUnread ? TColors.primary : (isDark ? TColors.darkMuted : TColors.lightMuted),
                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 3),
                            Row(children: [
                              Expanded(child: Text(
                                lastMsg?.content ?? 'No messages yet',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: TResponsive.sp(context, 13),
                                  color: hasUnread ? (isDark ? TColors.textDark : TColors.textLight) : (isDark ? TColors.darkMuted : TColors.lightMuted),
                                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                                ),
                              )),
                              if (hasUnread) Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: TColors.primary, borderRadius: BorderRadius.circular(TSizes.radiusFull)),
                                child: Text('${room.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ]),
                          ])),
                        ]),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: TColors.primary,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day}/${dt.month}';
  }
}
