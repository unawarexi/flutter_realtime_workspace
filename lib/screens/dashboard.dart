import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_realtime_workspace/features/dashboard_management/default_dashboard.dart';
import 'package:flutter_realtime_workspace/features/dashboard_management/financial_overview_dashboard.dart';
import 'package:flutter_realtime_workspace/features/dashboard_management/gnatt_charts_dasboard.dart';
import 'package:flutter_realtime_workspace/features/dashboard_management/milestone_dashboard.dart';
import 'package:flutter_realtime_workspace/features/dashboard_management/starred_dashboards.dart';
import 'package:flutter_realtime_workspace/features/dashboard_management/team_performance_dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isDropdownExpanded = false;
  String _selectedDashboard = "Default Dashboard";

  final Map<String, Widget> dashboardOptions = {
    "Starred Dashboards": const StarredDashboard(title: "Starred Dashboards"),
    "Default Dashboard":
        const DefaultDashboard("Some option", title: "Default Dashboard"),
    "Active Projects Dashboards": Container(),
    "Gantt Timeline Charts Dashboard":
        const GanttTimelineDashboard(title: "Gantt Timeline Charts"),
    "Team Performance Dashboard":
        const TeamPerformanceDashboard(title: "Team Performance"),
    "Milestones Dashboard":
        const MilestonesDashboard(title: "Milestones Dashboard"),
    "Financial Overview Dashboard":
        const FinancialOverviewDashboard(title: "Financial Overview"),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboards'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildDashboardDropdown(),
              const SizedBox(height: 20),
              if (_selectedDashboard == "Default Dashboard")
                _buildDefaultDashboard(),
              const SizedBox(height: 20),
              _buildAssignedToMeSection(),
              const SizedBox(height: 20),
              _buildActivityStreamSection(),
              const SizedBox(height: 30),
              _buildMissingFeaturesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardDropdown() {
    return Neumorphic(
      style: const NeumorphicStyle(
        depth: 8,
        intensity: 0.5,
        color: Colors.white,
      ),
      child: ExpansionTile(
        title: Text(
          _selectedDashboard,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent),
        ),
        trailing: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
        initiallyExpanded: _isDropdownExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isDropdownExpanded = expanded;
          });
        },
        children: dashboardOptions.keys.map((option) {
          return ListTile(
            title: Text(option, style: const TextStyle(color: Colors.black)),
            onTap: () {
              setState(() {
                _selectedDashboard = option;
                _isDropdownExpanded = false;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => dashboardOptions[option]!,
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDefaultDashboard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: Colors.blueAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/manage.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 10),
            const Text(
              "Click to explore charts and performance",
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedToMeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Assigned to Me",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 10),
        _buildCardItem("Project Alpha", "Fix login issue"),
        _buildCardItem("Project Beta", "Update project timeline"),
        _buildCardItem("Project Gamma", "Resolve API integration bug"),
      ],
    );
  }

  Widget _buildActivityStreamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Activity Streams",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.autorenew,
                color: Colors.blueAccent,
              ),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              "No issues found",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMissingFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Looks like you're missing some features",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "We're shipping more features for mobile dashboards. Let us know which tools you'd like to see.",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {},
          child: const Text(
            "Send Feedback",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(String title, String subtitle) {
    return Neumorphic(
      style: const NeumorphicStyle(
        depth: 4,
        intensity: 0.4,
        color: Colors.white,
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
        onTap: () {},
      ),
    );
  }
}
