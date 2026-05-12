import 'package:flutter/material.dart';

class Preferences extends StatefulWidget {
  const Preferences({super.key});

  @override
  State<Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  bool darkMode = false;
  bool compactMode = false;
  bool autoSync = true;
  bool enableAnimations = true;
  bool showAvatars = true;

  @override
  Widget build(BuildContext context) {
    // Theme colors (same as account.dart)
    const primaryBlue = Color(0xFF1E40AF);
    const lightBlue = Color(0xFF3B82F6);
    const backgroundLight = Color(0xFFFAFBFC);
    const backgroundDark = Color(0xFF0F172A);
    const cardLight = Color(0xFFFFFFFF);
    const cardDark = Color(0xFF1E293B);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const borderLight = Color(0xFFE2E8F0);
    const borderDark = Color(0xFF334155);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? backgroundDark : backgroundLight,
      appBar: AppBar(
        backgroundColor: isDarkMode ? backgroundDark : backgroundLight,
        elevation: 0,
        title: Text(
          "Preferences",
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
          _sectionTitle("Appearance", isDarkMode, textPrimary),
          _settingTile(
            icon: Icons.dark_mode_rounded,
            title: "Dark Mode",
            subtitle: "Reduce eye strain in low light",
            value: darkMode,
            onChanged: (v) => setState(() => darkMode = v),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          _settingTile(
            icon: Icons.view_compact_rounded,
            title: "Compact Mode",
            subtitle: "Smaller UI elements",
            value: compactMode,
            onChanged: (v) => setState(() => compactMode = v),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          const SizedBox(height: 18),
          _sectionTitle("General", isDarkMode, textPrimary),
          _settingTile(
            icon: Icons.sync_rounded,
            title: "Auto Sync",
            subtitle: "Sync data automatically",
            value: autoSync,
            onChanged: (v) => setState(() => autoSync = v),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          _settingTile(
            icon: Icons.animation_rounded,
            title: "Enable Animations",
            subtitle: "Smooth transitions and effects",
            value: enableAnimations,
            onChanged: (v) => setState(() => enableAnimations = v),
            isDarkMode: isDarkMode,
            primaryBlue: primaryBlue,
          ),
          _settingTile(
            icon: Icons.account_circle_rounded,
            title: "Show Avatars",
            subtitle: "Display user avatars in lists",
            value: showAvatars,
            onChanged: (v) => setState(() => showAvatars = v),
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
          activeColor: primaryBlue,
        ),
      ),
    );
  }
}
