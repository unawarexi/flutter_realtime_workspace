import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_realtime_workspace/router/app_router.dart';

class SupportSection extends StatelessWidget {
  final bool isDarkMode;
  const SupportSection({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    const cardDark = Color(0xFF1E293B);
    const cardLight = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const borderLight = Color(0xFFE2E8F0);
    const borderDark = Color(0xFF334155);

    final supportItems = [
      {
        'icon': Icons.feedback_rounded,
        'title': 'Send Feedback',
        'route': '/account/feedback',
      },
      {
        'icon': Icons.star_rate_rounded,
        'title': 'Rate App',
        'route': '/account/rate-us',
      },
      {
        'icon': Icons.new_releases_rounded,
        'title': "What's New",
        'route': '/whats-new',
      },
      {
        'icon': Icons.apps_rounded,
        'title': 'More Apps',
        'route': '/account/more-apps',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? cardDark : cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? borderDark : borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.04),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: supportItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == supportItems.length - 1;

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    leading: Icon(
                      item['icon'] as IconData,
                      color: isDarkMode ? Colors.white70 : textSecondary,
                      size: 15,
                    ),
                    title: Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : textPrimary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: isDarkMode ? Colors.white70 : textSecondary,
                    ),
                    onTap: () => context.push(item['route'] as String),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: isDarkMode ? borderDark : borderLight,
                      indent: 40,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
