import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isDropdownExpanded = false; // For toggling dropdown
  String _selectedDashboard = "Default Dashboard"; // Default dashboard

  // Dashboard options
  final List<String> dashboardOptions = [
    "Starred Dashboards",
    "Default Dashboard",
    "Active Projects Dashboards",
    "Gantt Timeline Charts Dashboard",
    "Team Performance Dashboard",
    "Milestones Dashboard",
    "Financial Overview Dashboard",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboards'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Dropdown Section
              _buildDashboardDropdown(),

              const SizedBox(height: 20),

              // Assigned to me Section
              _buildAssignedToMeSection(),

              const SizedBox(height: 20),

              // Activity Streams Section
              _buildActivityStreamSection(),

              const SizedBox(height: 30),

              // Missing Features Section
              _buildMissingFeaturesSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Dashboard Dropdown
  Widget _buildDashboardDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          _selectedDashboard,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        initiallyExpanded: _isDropdownExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isDropdownExpanded = expanded;
          });
        },
        children: dashboardOptions.map((option) {
          return ListTile(
            title: Text(option),
            onTap: () {
              setState(() {
                _selectedDashboard = option;
                _isDropdownExpanded = false;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaceholderScreen(title: option),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  // Assigned to Me Section
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

  // Activity Streams Section
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
              onPressed: () {
                // Handle refresh action
              },
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

  // Missing Features Section
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
          onPressed: () {
            // Handle feedback action
          },
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

  // Reusable card item for 'Assigned to Me' section
  Widget _buildCardItem(String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
        onTap: () {
          // Handle navigation to the specific project/issue screen
        },
      ),
    );
  }
}

// Placeholder screen for dashboard options
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Text(
          "Screen for $title",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
