import 'package:flutter/material.dart';

class OrgMembersScreen extends StatelessWidget {
  const OrgMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: const Center(child: Text('Members')),
    );
  }
}
