import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Panel showing available AI tools that the user can execute.
class AIToolsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> tools;
  final bool isDark;
  final void Function(String toolName) onExecute;

  const AIToolsPanel({
    super.key,
    required this.tools,
    required this.isDark,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : TColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TSizes.radiusLg),
        ),
        border: Border.all(
          color: isDark ? TColors.darkBorder : TColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: TSizes.sm),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? TColors.darkBorder : TColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(TSizes.paddingMD),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(TSizes.radiusSm),
                  ),
                  child: const Icon(
                    Icons.extension_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Tools',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? TColors.textPrimaryDark
                              : TColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        '${tools.length} tools available',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? TColors.darkMuted
                              : TColors.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tool list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                TSizes.paddingMD,
                0,
                TSizes.paddingMD,
                TSizes.paddingMD,
              ),
              itemCount: tools.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: TSizes.paddingXS),
              itemBuilder: (context, index) {
                final tool = tools[index];
                return _ToolCard(
                  name: tool['name'] as String? ?? 'unknown',
                  description:
                      tool['description'] as String? ?? 'No description',
                  isDark: isDark,
                  onExecute: () =>
                      onExecute(tool['name'] as String? ?? ''),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String name;
  final String description;
  final bool isDark;
  final VoidCallback onExecute;

  const _ToolCard({
    required this.name,
    required this.description,
    required this.isDark,
    required this.onExecute,
  });

  IconData get _icon {
    if (name.contains('search')) return Icons.search_rounded;
    if (name.contains('create') || name.contains('add')) return Icons.add_rounded;
    if (name.contains('summarize') || name.contains('summary')) {
      return Icons.summarize_rounded;
    }
    if (name.contains('analyze') || name.contains('report')) {
      return Icons.analytics_rounded;
    }
    if (name.contains('email') || name.contains('send')) return Icons.send_rounded;
    return Icons.build_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onExecute,
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(TSizes.paddingSM + 2),
          decoration: BoxDecoration(
            color: isDark ? TColors.darkSurface : TColors.lightElevated,
            borderRadius: BorderRadius.circular(TSizes.radiusMd),
            border: Border.all(
              color: isDark ? TColors.darkBorder : TColors.lightBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(TSizes.radiusSm),
                ),
                child: Icon(
                  _icon,
                  size: 16,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: TSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: isDark
                            ? TColors.textPrimaryDark
                            : TColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? TColors.darkMuted
                            : TColors.lightMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TSizes.sm),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 14,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
