import 'package:flutter/material.dart';

class ProjectHome extends StatefulWidget {
  const ProjectHome({super.key});

  @override
  State<ProjectHome> createState() => _ProjectHomeState();
}

class _ProjectHomeState extends State<ProjectHome> {
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CircleAvatar(
              radius: 20,
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
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey[200],
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
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
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
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
          children: [
            const SizedBox(height: 20),
            const Text(
              'Projects',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 20),
            _buildCategorySection('Recently Viewed'),
            const SizedBox(height: 10),
            _buildProjectList(),
            const SizedBox(height: 30),
            _buildCategorySection('All Projects'),
            const SizedBox(height: 10),
            _buildProjectList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProjectList() {
    // Example static project items for demonstration.
    List<Map<String, String>> projects = [
      {'name': 'Project Alpha', 'date': '14 Sep 2024'},
      {'name': 'Project Beta', 'date': '12 Sep 2024'},
      {'name': 'Project Gamma', 'date': '10 Sep 2024'},
    ];

    return Column(
      children: projects.map((project) {
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: const CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/50'),
            ),
            title: Text(
              project['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text('Last modified: ${project['date']}'),
            trailing: IconButton(
              icon: const Icon(Icons.star_border),
              onPressed: () {
                // Star project logic
              },
            ),
            onTap: () {
              // Open project details
            },
          ),
        );
      }).toList(),
    );
  }
}

class CreateProjectScreen extends StatelessWidget {
  const CreateProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Project'),
      ),
      body: const Center(
        child: Text('Create Project Form Goes Here'),
      ),
    );
  }
}
