import 'package:flutter/material.dart';

class CreateWorkspaceScreen extends StatelessWidget {
  const CreateWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Workspace')),
      body: const Center(child: Text('Create Workspace')),
    );
  }
}
