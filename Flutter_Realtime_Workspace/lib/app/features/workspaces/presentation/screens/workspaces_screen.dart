import 'package:flutter/material.dart';

class WorkspacesScreen extends StatelessWidget {
  const WorkspacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workspaces')),
      body: const Center(child: Text('Workspaces')),
    );
  }
}
