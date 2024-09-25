import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/errors/project_error.dart';
import 'package:flutter_realtime_workspace/core/services/apis/create_project_services.dart';
import 'package:flutter_realtime_workspace/core/utils/file_exception.dart';
import 'package:flutter_realtime_workspace/features/project_management/domain/models/create_project_model.dart';
import 'package:flutter_realtime_workspace/features/project_management/presentation/widgets/project_templates.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController =
      TextEditingController();

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

  String? selectedTemplate;
  final ProjectService _projectService = ProjectService();
  bool _isLoading = false; // State variable for loading

  void _handleTemplateSelected(String? template) {
    setState(() {
      selectedTemplate = template;
    });
  }

  Future<void> _createProject() async {
    setState(() {
      _isLoading = true; // Show loading spinner
    });

    try {
      // Generate a unique project ID
      String generatedId = FileException.generateUniqueId();

      // Upload file and get its URL
      String? fileUrl = await FileException.uploadFile();

      // Create the project
      final newProject = Project(
        id: generatedId,
        name: _projectNameController.text,
        description: _projectDescriptionController.text,
        template: selectedTemplate ??
            '', // Default to an empty string if no template is selected
        projectKey: '', // Populate as necessary
        fileUrl: fileUrl ?? '', // Use the file URL
        date: DateTime.now(),
      );

      // Call the service to create the project
      bool isSuccess = await _projectService.createProject(newProject);

      if (isSuccess) {
        ProjectError.showSuccessToast('Project created successfully!');
      } else {
        ProjectError.showErrorToast(
            'Project creation failed. Please try again.');
      }
    } catch (e) {
      ProjectError.showErrorToast('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading spinner
      });
    }
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
                  'assets/images/design.png',
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
              ProjectTemplateDropdown(
                projectTemplates: _projectTemplates,
                onTemplateSelected: _handleTemplateSelected,
              ),
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
                onPressed: _isLoading ? null : _createProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Center(
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
          label: const Text(
            'Upload File',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
          ),
        ),
      ],
    );
  }
}
