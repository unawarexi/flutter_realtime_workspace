import 'package:flutter/material.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController =
      TextEditingController();
  String? _selectedTemplate;
  bool _isDropdownOpen = false;

  final List<Map<String, String>> _projectTemplates = [
    {
      'name': 'Kanban',
      'description':
          'A Kanban board helps visualize tasks in different stages of completion.',
      'icon': 'assets/images/kanban.png'
    },
    {
      'name': 'Scrum',
      'description':
          'Scrum helps manage tasks efficiently by organizing work into sprints.',
      'icon': 'assets/images/scrum.png'
    },
    {
      'name': 'Blank Project',
      'description': 'Start from scratch with a clean project workspace.',
      'icon': 'assets/images/blank.png'
    },
    {
      'name': 'Project Management',
      'description':
          'Keep track of all your resources and deadlines effectively.',
      'icon': 'assets/images/manage.png'
    },
    {
      'name': 'Task Tracking',
      'description':
          'Track the progress of tasks and assignments in one place.',
      'icon': 'assets/images/track.png'
    },
  ];

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create New Project',
          style: TextStyle(fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/design.png', // Replace with actual asset image
                  height: 200,
                  width: 200,
                ),
              ),
              const SizedBox(height: 30),
              // Project Name
              TextFormField(
                controller: _projectNameController,
                decoration: InputDecoration(
                  labelText: 'Project Name',
                  labelStyle: const TextStyle(color: Colors.blueGrey),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Project Description
              TextFormField(
                controller: _projectDescriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Project Description',
                  labelStyle: const TextStyle(color: Colors.blueGrey),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Project Template Dropdown
              _buildTemplateSection(),
              const SizedBox(height: 20),
              // Project Key
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Project Key',
                  labelStyle: const TextStyle(color: Colors.blueGrey),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // File Upload Section
              _buildFileUploadSection(),
              const SizedBox(height: 30),
              // Create Project Button
              ElevatedButton(
                onPressed: () {
                  // Create project logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Create Project',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Template',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _toggleDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTemplate ?? 'Choose a Template',
                  style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
              ],
            ),
          ),
        ),
        if (_isDropdownOpen) _buildTemplateDropdown(),
      ],
    );
  }

  Widget _buildTemplateDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _projectTemplates.map((template) {
          return ListTile(
            contentPadding: EdgeInsets.zero, // Remove default padding
            title: Row(
              children: [
                // Image on the left, taking 30% of the width
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Image.asset(
                    template['icon']!, // Your icon assets
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(
                    width: 24), // Space between image and text (3rem)
                // Text on the right, taking 70% of the width
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template['name']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(
                          height: 5), // Space between name and description
                      Text(
                        template['description']!,
                        style: const TextStyle(
                          fontSize: 12.0,
                        ),
                      ),
                      const SizedBox(height: 10), // Space before 'Learn More'
                      // 'Learn More' text at the bottom
                      const Text(
                        'Learn More',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _selectedTemplate = template['name'];
                _isDropdownOpen = false;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Project Structure (PDF, Image, or Video)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            // File upload logic
          },
          icon: const Icon(Icons.upload_file, color: Colors.white),
          label: const Text('Choose File'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    );
  }
}
