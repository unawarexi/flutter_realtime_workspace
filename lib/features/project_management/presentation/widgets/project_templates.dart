// project_template.dart
import 'package:flutter/material.dart';

class ProjectTemplateDropdown extends StatefulWidget {
  final List<Map<String, String>> projectTemplates;
  final ValueChanged<String?> onTemplateSelected;

  const ProjectTemplateDropdown({
    Key? key,
    required this.projectTemplates,
    required this.onTemplateSelected,
  }) : super(key: key);

  @override
  _ProjectTemplateDropdownState createState() =>
      _ProjectTemplateDropdownState();
}

class _ProjectTemplateDropdownState extends State<ProjectTemplateDropdown> {
  String? _selectedTemplate;
  bool _isDropdownOpen = false;

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        children: widget.projectTemplates.map((template) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Image.asset(
                    template['icon']!,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 24),
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
                      const SizedBox(height: 5),
                      Text(
                        template['description']!,
                        style: const TextStyle(
                          fontSize: 12.0,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                widget.onTemplateSelected(_selectedTemplate);
                _isDropdownOpen = false;
              });
            },
          );
        }).toList(),
      ),
    );
  }
}
