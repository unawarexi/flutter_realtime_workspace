import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/features/settings/presentation/settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SettingsSection(isDarkMode: isDarkMode),
      ),
    );
  }
}
