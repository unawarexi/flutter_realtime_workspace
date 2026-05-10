import 'package:flutter/material.dart';

class IssueDetailScreen extends StatelessWidget {
  const IssueDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issue Detail')),
      body: const Center(child: Text('Issue Detail')),
    );
  }
}
