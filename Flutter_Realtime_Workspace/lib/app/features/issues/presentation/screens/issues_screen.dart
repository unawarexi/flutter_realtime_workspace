import 'package:flutter/material.dart';

class IssuesScreen extends StatelessWidget {
  const IssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issues')),
      body: const Center(child: Text('Issues')),
    );
  }
}
