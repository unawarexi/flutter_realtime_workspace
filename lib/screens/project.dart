import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/features/project_management/presentation/screens/create_project_screen.dart';
import 'package:flutter_realtime_workspace/features/project_management/presentation/screens/project_timeline_screen.dart';

class ProjectHome extends StatefulWidget {
  const ProjectHome({super.key});

  @override
  State<ProjectHome> createState() => _ProjectHomeState();
}

class _ProjectHomeState extends State<ProjectHome> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150'), // Replace with actual user image URL
            ),
            _isSearching
                ? Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search Projects',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey[200],
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _isSearching = false;
                                _searchController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const CreateProjectScreen()),
                          );
                        },
                      )
                    ],
                  ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 20),
            const Text(
              'Projects',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 20),
            _buildCategorySection('Recently Viewed'),
            const SizedBox(height: 10),
            _buildProjectList(
                context), // Updated project list to make it clickable
            const SizedBox(height: 30),
            _buildCategorySection('All Projects'),
            const SizedBox(height: 10),
            _buildProjectList(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateProjectScreen()),
          );
        },
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategorySection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.blueGrey),
            onPressed: () {
              // Filter functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(BuildContext context) {
    List<Map<String, String>> projects = [
      {'name': 'Project Alpha', 'date': '14 Sep 2024'},
      {'name': 'Project Beta', 'date': '12 Sep 2024'},
      {'name': 'Project Gamma', 'date': '10 Sep 2024'},
    ];

    return Column(
      children: projects.map((project) {
        return Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage('https://via.placeholder.com/50'),
            ),
            title: Text(
              project['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(
              'Last modified: ${project['date']}',
              style: TextStyle(color: Colors.blueGrey[300]),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.star_border, color: Colors.blueGrey),
              onPressed: () {
                // Star project logic
              },
            ),
            onTap: () {
              // Navigate to the project timeline screen
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ProjectTimelineScreen(projectName: project['name']!)),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
