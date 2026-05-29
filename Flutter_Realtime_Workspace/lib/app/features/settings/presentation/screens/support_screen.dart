import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/features/settings/presentation/support.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SupportSection(isDarkMode: isDarkMode),
      ),
    );
  }
}
