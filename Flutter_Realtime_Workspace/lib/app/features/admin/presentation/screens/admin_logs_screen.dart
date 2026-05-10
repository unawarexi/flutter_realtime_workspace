import 'package:flutter/material.dart';

class AdminLogsScreen extends StatelessWidget {
  const AdminLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Logs')),
      body: const Center(child: Text('System Logs')),
    );
  }
}
