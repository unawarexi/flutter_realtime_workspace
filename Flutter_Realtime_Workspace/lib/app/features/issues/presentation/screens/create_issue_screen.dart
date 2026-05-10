import 'package:flutter/material.dart';

class CreateIssueScreen extends StatelessWidget {
  const CreateIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Issue')),
      body: const Center(child: Text('Create Issue')),
    );
  }
}
