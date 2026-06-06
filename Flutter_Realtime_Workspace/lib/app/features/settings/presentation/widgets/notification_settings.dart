import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/settings_usecase.dart';
import 'package:flutter_realtime_workspace/store/settings_provider.dart';

class NotificationSettings extends ConsumerWidget {
  const NotificationSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme colors (same as account.dart)
    const primaryBlue = Color(0xFF1E40AF);
    const lightBlue = Color(0xFF3B82F6);
    const backgroundLight = Color(0xFFFAFBFC);
    const backgroundDark = Color(0xFF0F172A);
    const textPrimary = Color(0xFF0F172A);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? backgroundDark : backgroundLight,
      appBar: AppBar(
        backgroundColor: isDarkMode ? backgroundDark : backgroundLight,
        elevation: 0,
        title: Text(
          "Notification Settings",
          style: TextStyle(
            color: isDarkMode ? lightBlue : primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : textPrimary,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _sectionTitle("General", isDarkMode, textPrimary),
          _settingTile(
            icon: Icons.notifications_active_rounded,
            title: "Push Notifications",
            subtitle: "Receive notifications on your device",
            value: settings.pushNotifications,
            onChanged: (v) => SettingsUseCase.toggleNotificationChannel(
              ref: ref,
              channel: 'push',
              enabled: v,
            ),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          _settingTile(
            icon: Icons.email_rounded,
            title: "Email Notifications",
            subtitle: "Get updates via email",
            value: settings.emailNotifications,
            onChanged: (v) => SettingsUseCase.toggleNotificationChannel(
              ref: ref,
              channel: 'email',
              enabled: v,
            ),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          const SizedBox(height: 18),
          _sectionTitle("Activity", isDarkMode, textPrimary),
          _settingTile(
            icon: Icons.alternate_email_rounded,
            title: "Mentions",
            subtitle: "Notify when you are mentioned",
            value: settings.mentionNotifications,
            onChanged: (v) => SettingsUseCase.toggleNotificationChannel(
              ref: ref,
              channel: 'mentions',
              enabled: v,
            ),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          _settingTile(
            icon: Icons.task_rounded,
            title: "Task Updates",
            subtitle: "Updates on assigned tasks",
            value: settings.taskUpdates,
            onChanged: (v) => SettingsUseCase.toggleNotificationChannel(
              ref: ref,
              channel: 'tasks',
              enabled: v,
            ),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          const SizedBox(height: 18),
          _sectionTitle("Sound & Vibration", isDarkMode, textPrimary),
          _settingTile(
            icon: Icons.volume_up_rounded,
            title: "Sound",
            subtitle: "Play sound for notifications",
            value: settings.sound,
            onChanged: (v) => SettingsUseCase.toggleNotificationChannel(
              ref: ref,
              channel: 'sound',
              enabled: v,
            ),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          _settingTile(
            icon: Icons.vibration_rounded,
            title: "Vibrate",
            subtitle: "Vibrate on notification",
            value: settings.vibrate,
            onChanged: (v) => SettingsUseCase.toggleNotificationChannel(
              ref: ref,
              channel: 'vibrate',
              enabled: v,
            ),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDarkMode, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2, top: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? Colors.white : textPrimary,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
    required Color primaryBlue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryBlue, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDarkMode ? Colors.white60 : Colors.grey[600],
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: primaryBlue,
        ),
      ),
    );
  }
}
