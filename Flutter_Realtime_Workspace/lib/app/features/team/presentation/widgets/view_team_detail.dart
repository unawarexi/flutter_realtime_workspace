import 'package:flutter/material.dart';

class ViewTeamDetail extends StatelessWidget {
  final Map<String, dynamic> team;
  const ViewTeamDetail({super.key, required this.team});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(team['name'] ?? 'Team Detail')),
      body: const Center(child: Text('Team Detail — coming soon')),
    );
  }
}
