import 'package:flutter/material.dart';

class WorkspaceDetailScreen extends StatelessWidget {
  const WorkspaceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workspace')),
      body: const Center(child: Text('Workspace')),
    );
  }
}
