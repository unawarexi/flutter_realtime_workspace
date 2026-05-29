import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// A single chat message bubble for the AI assistant.
///
/// Supports user messages (right-aligned) and assistant messages (left-aligned)
/// with markdown-like content rendering, tool call indicators, and copy action.
class AIMessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final DateTime? timestamp;
  final bool isStreaming;
  final String? toolName;
  final String? toolStatus;

  const AIMessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.timestamp,
    this.isStreaming = false,
    this.toolName,
    this.toolStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TSizes.paddingMD,
        vertical: TSizes.paddingXS,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isDark),
          if (!isUser) const SizedBox(width: TSizes.sm),
          Flexible(child: _buildBubble(context, isDark)),
          if (isUser) const SizedBox(width: TSizes.sm),
          if (isUser) _buildUserAvatar(isDark),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.radiusSm),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildUserAvatar(bool isDark) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isDark ? TColors.darkElevated : TColors.lightElevated,
        borderRadius: BorderRadius.circular(TSizes.radiusSm),
        border: Border.all(
          color: isDark ? TColors.darkBorder : TColors.lightBorder,
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        color: isDark ? TColors.textDarkSecondary : TColors.textSecondaryLight,
        size: 16,
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Tool call indicator
        if (toolName != null) _buildToolIndicator(isDark),
        // Main bubble
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          padding: const EdgeInsets.all(TSizes.paddingSM + 4),
          decoration: BoxDecoration(
            color: isUser
                ? TColors.buttonPrimary
                : (isDark ? TColors.darkCard : TColors.lightSurface),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(TSizes.radiusMd),
              topRight: const Radius.circular(TSizes.radiusMd),
              bottomLeft: Radius.circular(isUser ? TSizes.radiusMd : 4),
              bottomRight: Radius.circular(isUser ? 4 : TSizes.radiusMd),
            ),
            border: isUser
                ? null
                : Border.all(
                    color: isDark ? TColors.darkBorder : TColors.lightBorder,
                    width: 0.8,
                  ),
            boxShadow: [
              BoxShadow(
                color: (isUser
                        ? TColors.buttonPrimary
                        : (isDark ? Colors.black : Colors.grey))
                    .withValues(alpha: isUser ? 0.2 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content
              _buildContent(isDark),
              // Streaming indicator
              if (isStreaming) _buildStreamingIndicator(isDark),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Timestamp + actions
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (timestamp != null)
              Text(
                _formatTime(timestamp!),
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? TColors.darkMuted : TColors.lightMuted,
                ),
              ),
            if (!isUser && !isStreaming) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied to clipboard'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TSizes.radiusSm),
                      ),
                    ),
                  );
                },
                child: Icon(
                  Icons.copy_rounded,
                  size: 12,
                  color: isDark ? TColors.darkMuted : TColors.lightMuted,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    // Render code blocks differently
    if (content.contains('```')) {
      return _buildCodeContent(isDark);
    }

    return SelectableText(
      content,
      style: TextStyle(
        fontSize: 13,
        height: 1.5,
        color: isUser
            ? Colors.white
            : (isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight),
      ),
    );
  }

  Widget _buildCodeContent(bool isDark) {
    final parts = content.split('```');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(parts.length, (i) {
        if (i.isOdd) {
          // Code block
          final code = parts[i].trimLeft();
          final firstNewline = code.indexOf('\n');
          final lang =
              firstNewline > 0 ? code.substring(0, firstNewline).trim() : '';
          final codeBody =
              firstNewline > 0 ? code.substring(firstNewline + 1) : code;

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: TSizes.xs),
            padding: const EdgeInsets.all(TSizes.paddingSM),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0D1117)
                  : const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(TSizes.radiusSm),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF30363D)
                    : const Color(0xFFD0D7DE),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lang.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      lang,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? TColors.darkMuted : TColors.lightMuted,
                      ),
                    ),
                  ),
                SelectableText(
                  codeBody.trim(),
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFFE6EDF3)
                        : const Color(0xFF24292F),
                  ),
                ),
              ],
            ),
          );
        }
        // Regular text
        if (parts[i].trim().isEmpty) return const SizedBox.shrink();
        return SelectableText(
          parts[i].trim(),
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: isUser
                ? Colors.white
                : (isDark
                    ? TColors.textPrimaryDark
                    : TColors.textPrimaryLight),
          ),
        );
      }),
    );
  }

  Widget _buildStreamingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1.0),
            duration: Duration(milliseconds: 600 + (i * 200)),
            builder: (_, value, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? TColors.blue400
                          : TColors.buttonPrimaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildToolIndicator(bool isDark) {
    final isExecuting = toolStatus == 'executing';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(TSizes.radiusSm),
        border: Border.all(
          color: isDark
              ? const Color(0xFF6366F1).withValues(alpha: 0.3)
              : const Color(0xFF6366F1).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExecuting)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF6366F1),
              ),
            )
          else
            const Icon(
              Icons.build_rounded,
              size: 12,
              color: Color(0xFF6366F1),
            ),
          const SizedBox(width: 6),
          Text(
            isExecuting ? 'Running $toolName...' : 'Used $toolName',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }
}
