import 'package:flutter/material.dart';

class NotAvailableScreenWidget extends StatelessWidget {
  const NotAvailableScreenWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('This feature is not available yet.')),
    );
  }
}
