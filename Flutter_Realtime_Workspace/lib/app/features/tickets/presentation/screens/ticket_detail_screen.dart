import 'package:flutter/material.dart';

class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Detail')),
      body: const Center(child: Text('Ticket Detail')),
    );
  }
}
