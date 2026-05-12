import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/features/settings/presentation/widgets/notification_settings.dart';
import 'package:flutter_realtime_workspace/app/features/settings/presentation/widgets/preferences.dart';
import 'package:flutter_realtime_workspace/app/features/settings/presentation/widgets/privacy_security.dart';

class SettingsSection extends StatelessWidget {
  final bool isDarkMode;
  const SettingsSection({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1E40AF);
    const cardDark = Color(0xFF1E293B);
    const cardLight = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const borderLight = Color(0xFFE2E8F0);
    const borderDark = Color(0xFF334155);

    final settingsItems = [
      {
        'icon': Icons.notifications_none_rounded,
        'title': 'Notifications',
        'subtitle': 'Manage your alerts',
        'widget': const NotificationSettings(),
      },
      {
        'icon': Icons.settings_rounded,
        'title': 'Preferences',
        'subtitle': 'App settings',
        'widget': const Preferences(),
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Privacy & Security',
        'subtitle': 'Account protection',
        'widget': const PrivacySecurity(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
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
                    ? Colors.black.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.04),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: settingsItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == settingsItems.length - 1;

              return Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: primaryBlue,
                        size: 15,
                      ),
                    ),
                    title: Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      item['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.white60 : textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: isDarkMode ? Colors.white70 : textSecondary,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => item['widget'] as Widget,
                      ),
                    ),
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
