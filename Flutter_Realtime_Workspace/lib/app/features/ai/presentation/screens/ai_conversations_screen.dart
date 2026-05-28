import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/store/ai_provider.dart';

class AIConversationsScreen extends ConsumerWidget {
  const AIConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = THelperFunctions.isDarkMode(context);
    final conversationsAsync = ref.watch(aiConversationsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : TColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(TSizes.radiusSm),
              ),
              child: const Icon(Icons.history_rounded,
                  color: Color(0xFF6366F1), size: 14),
            ),
            const SizedBox(width: 10),
            Text(
              'Conversations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : TColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return _buildEmptyState(isDark);
          }
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(TSizes.paddingMD),
            itemCount: conversations.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: TSizes.paddingXS),
            itemBuilder: (context, index) {
              final convo = conversations[index];
              return TWidgetAnimations.fadeIn(
                delay: Duration(milliseconds: 40 * index),
                child: _ConversationCard(
                  conversation: convo,
                  isDark: isDark,
                  onTap: () {
                    // Navigate back to chat with this conversation loaded
                    Navigator.pop(context, convo['_id'] ?? convo['id']);
                  },
                  onDelete: () async {
                    final id =
                        convo['_id'] as String? ?? convo['id'] as String? ?? '';
                    if (id.isEmpty) return;
                    await ref
                        .read(aiRepositoryProvider)
                        .deleteConversation(id);
                    ref.invalidate(aiConversationsProvider);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(TSizes.paddingXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted),
                const SizedBox(height: TSizes.paddingMD),
                Text(
                  'Failed to load conversations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? TColors.textPrimaryDark
                        : TColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: TSizes.sm),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted,
                  ),
                ),
                const SizedBox(height: TSizes.paddingMD),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(aiConversationsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(TSizes.radiusMd),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 40, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: TSizes.paddingMD),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : TColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            'Start chatting with the AI assistant\nto see your history here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? TColors.darkMuted : TColors.lightMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationCard({
    required this.conversation,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = conversation['title'] as String? ??
        conversation['summary'] as String? ??
        'Untitled Conversation';
    final createdAt = conversation['createdAt'] as String?;
    final messageCount = conversation['messageCount'] as int? ??
        (conversation['messages'] as List?)?.length ??
        0;

    String timeAgo = '';
    if (createdAt != null) {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inDays > 0) {
          timeAgo = '${diff.inDays}d ago';
        } else if (diff.inHours > 0) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${diff.inMinutes}m ago';
        }
      }
    }

    return Dismissible(
      key: Key(conversation['_id'] as String? ?? conversation['id'] as String? ?? title),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: TColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: TColors.error, size: 20),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(TSizes.paddingSM + 4),
            decoration: BoxDecoration(
              color: isDark ? TColors.darkCard : TColors.lightSurface,
              borderRadius: BorderRadius.circular(TSizes.radiusMd),
              border: Border.all(
                color: isDark ? TColors.darkBorder : TColors.lightBorder,
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.12),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(TSizes.radiusSm),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      size: 16, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: TSizes.paddingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? TColors.textPrimaryDark
                              : TColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 10,
                              color: isDark
                                  ? TColors.darkMuted
                                  : TColors.lightMuted),
                          const SizedBox(width: 4),
                          Text(
                            '$messageCount messages',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? TColors.darkMuted
                                  : TColors.lightMuted,
                            ),
                          ),
                          if (timeAgo.isNotEmpty) ...[
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? TColors.darkMuted
                                    : TColors.lightMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? TColors.darkMuted
                                    : TColors.lightMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
