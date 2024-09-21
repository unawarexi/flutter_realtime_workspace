import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/screens/todo_list.dart';

class ProjectTimelineScreen extends StatefulWidget {
  final String projectName;

  const ProjectTimelineScreen({super.key, required this.projectName});

  @override
  _ProjectTimelineScreenState createState() => _ProjectTimelineScreenState();
}

class _ProjectTimelineScreenState extends State<ProjectTimelineScreen> {
  bool _showFilters = false;
  int _activeTabIndex = 1; // Default tab to be Timeline

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: Text(
          widget.projectName,
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Handle more options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          if (_showFilters) _buildFilterSection(),
          // Tabs
          _buildTabs(),
          // Content Section Based on Active Tab
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  // Tab Section
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabOption("Board", 0),
          _buildTabOption("Timeline", 1),
          _buildTabOption("Settings", 2),
        ],
      ),
    );
  }

  // Method to Build Individual Tabs
  Widget _buildTabOption(String title, int index) {
    bool isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.blue : Colors.grey,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 5),
              height: 2,
              width: 50,
              color: Colors.blue,
            )
        ],
      ),
    );
  }

  // Display Content Based on the Active Tab
  Widget _buildTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return _buildBoardContent(); // Board Screen
      case 1:
        return _buildTimelineContent(); // Timeline Screen
      case 2:
        return _buildSettingsContent(); // Settings Screen
      default:
        return Container();
    }
  }

  // Board Screen Content with Sliding To Do, In Progress, Done
  Widget _buildBoardContent() {
    return PageView(
      children: [
        _buildBoardScreen("To Do", "No issues yet!",
            "Create issues to get started. Want sprints? Enable your backlog and sprints via settings."),
        _buildBoardScreen("In Progress", "No issues yet!",
            "Create issues to get started. Want sprints? Enable your backlog and sprints via settings."),
        _buildBoardScreen("Done", "No issues yet!",
            "Create issues to get started. Want sprints? Enable your backlog and sprints via settings."),
      ],
    );
  }

  Widget _buildBoardScreen(String title, String headerText, String subText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Options
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.more_vert),
            ],
          ),
        ),
        // Placeholder Image and Text
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.insert_drive_file,
                    size: 80, color: Colors.grey),
                const SizedBox(height: 10),
                Text(
                  headerText,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  subText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        // Create and Attachment Options
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.blue),
                onPressed: _showAttachmentOptions,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TodoList()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Create"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Function to Show Attachment Options Pop-Up
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAttachmentOption(Icons.camera_alt, "Take Photo"),
              _buildAttachmentOption(Icons.videocam, "Record Video"),
              _buildAttachmentOption(Icons.insert_drive_file, "Choose File"),
              _buildAttachmentOption(Icons.screen_share, "Record Screen"),
            ],
          ),
        );
      },
    );
  }

  // Single Option for Attachments
  Widget _buildAttachmentOption(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label),
      onTap: () {
        // Handle Attachment Option
        Navigator.pop(context);
      },
    );
  }

  // Timeline Screen Content
  Widget _buildTimelineContent() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timeline, size: 80, color: Colors.grey),
        SizedBox(height: 10),
        Text(
          'Plan high-level work',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'Tap + to create your first epic on the timeline',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  // Settings Screen Content
  Widget _buildSettingsContent() {
    return const Center(
      child: Text(
        "Settings Screen - Feature settings would be here",
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  // Filter Section
  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterOption(
              'Group by', ['None', 'Assignees', 'Epics', 'Subtasks']),
          const SizedBox(height: 10),
          _buildFilterOption(
              'Assignee', ['Me', 'Admin', 'Team Lead', 'HR', 'Project Lead']),
          const SizedBox(height: 10),
          const Text(
            'Clear all filters',
            style: TextStyle(
                color: Colors.redAccent, decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title, List<String> options) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            // Handle filter option selection
          },
        );
      }).toList(),
    );
  }
}
