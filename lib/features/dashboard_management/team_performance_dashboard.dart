import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class TeamPerformanceDashboard extends StatefulWidget {
  const TeamPerformanceDashboard({super.key, required String title});

  @override
  _TeamPerformanceDashboardState createState() =>
      _TeamPerformanceDashboardState();
}

class _TeamPerformanceDashboardState extends State<TeamPerformanceDashboard> {
  final List<Team> teams = [
    Team('Development', [
      EmployeePerformance('Alice', 85),
      EmployeePerformance('Bob', 92),
      EmployeePerformance('Charlie', 78),
    ]),
    Team('Marketing', [
      EmployeePerformance('Eve', 80),
      EmployeePerformance('Frank', 88),
      EmployeePerformance('Grace', 75),
    ]),
    Team('Sales', [
      EmployeePerformance('Henry', 90),
      EmployeePerformance('Ivy', 82),
      EmployeePerformance('Jack', 87),
    ]),
  ];

  Team? _selectedTeam;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Performance Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Title
              const Text(
                "Team Performance",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),

              // Team Cards Section
              Expanded(
                child: _buildTeamCards(),
              ),

              const SizedBox(height: 20),

              // Individual Employee Performance Section
              if (_selectedTeam != null) _buildEmployeePerformanceSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Build cards for teams
  Widget _buildTeamCards() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.2,
      ),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return Neumorphic(
          style: const NeumorphicStyle(
            depth: 8,
            intensity: 0.5,
            color: Colors.white,
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTeam = team;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.group,
                    size: 50,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    team.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build employee performance section
  Widget _buildEmployeePerformanceSection() {
    return Neumorphic(
      style: const NeumorphicStyle(
        depth: 8,
        intensity: 0.5,
        color: Colors.white,
      ),
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_selectedTeam?.name} - Employee Performance",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 10),

            // Employee performance chart
            Expanded(
              child: SfCartesianChart(
                primaryYAxis: NumericAxis(labelFormat: '{value}%'),
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  ColumnSeries<EmployeePerformance, String>(
                    dataSource: _selectedTeam!.employees,
                    xValueMapper: (EmployeePerformance data, _) => data.name,
                    yValueMapper: (EmployeePerformance data, _) =>
                        data.performance,
                    name: 'Performance',
                    color: Colors.blueAccent,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Models
class Team {
  final String name;
  final List<EmployeePerformance> employees;

  Team(this.name, this.employees);
}

class EmployeePerformance {
  final String name;
  final int performance;

  EmployeePerformance(this.name, this.performance);
}
