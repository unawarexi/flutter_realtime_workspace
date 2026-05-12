// project_template.dart
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';

class ProjectTemplateDropdown extends StatefulWidget {
  final List<Map<String, String>> projectTemplates;
  final ValueChanged<String?> onTemplateSelected;

  const ProjectTemplateDropdown({
    super.key,
    required this.projectTemplates,
    required this.onTemplateSelected,
  });

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
    final isDarkMode = THelperFunctions.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Template',
          style: TextStyle(
            fontSize: 12, // reduced font size
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4), // reduced spacing
        InkWell(
          onTap: _toggleDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 8), // reduced padding
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(8), // reduced radius
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.08)
                      : Colors.grey.withOpacity(0.03),
                  spreadRadius: 1,
                  blurRadius: 3, // reduced blur
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTemplate ?? 'Choose a Template',
                  style: TextStyle(
                    fontSize: 10, // reduced font size
                    color: isDarkMode ? Colors.white70 : Colors.blueGrey,
                  ),
                ),
                Icon(
                  _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: isDarkMode ? Colors.white54 : Colors.blueGrey,
                  size: 16, // reduced icon size
                ),
              ],
            ),
          ),
        ),
        if (_isDropdownOpen) _buildTemplateDropdown(isDarkMode),
      ],
    );
  }

  Widget _buildTemplateDropdown(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 4), // reduced spacing
      padding: const EdgeInsets.all(8), // reduced padding
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E293B).withOpacity(0.95)
            : Colors.white,
        borderRadius: BorderRadius.circular(8), // reduced radius
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.10)
                : Colors.grey.withOpacity(0.06),
            spreadRadius: 1,
            blurRadius: 4, // reduced blur
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        height: 140, // reduced max height for the dropdown
        child: SingleChildScrollView(
          child: Column(
            children: widget.projectTemplates.map((template) {
              final isSelected = _selectedTemplate == template['name'];
              return InkWell(
                borderRadius: BorderRadius.circular(6), // reduced radius
                onTap: () {
                  setState(() {
                    _selectedTemplate = template['name'];
                    widget.onTemplateSelected(_selectedTemplate);
                    _isDropdownOpen = false;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 2), // reduced spacing
                  padding: const EdgeInsets.all(6), // reduced padding
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDarkMode
                            ? const Color(0xFF1E40AF).withOpacity(0.10)
                            : const Color(0xFF3B82F6).withOpacity(0.06))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6), // reduced radius
                    border: isSelected
                        ? Border.all(
                            color: isDarkMode
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF1E40AF),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24, // reduced size
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(4), // reduced radius
                          color: isDarkMode
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                        ),
                        child: Image.asset(
                          template['icon']!,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 8), // reduced spacing
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template['name']!,
                              style: TextStyle(
                                fontSize: 10, // reduced font size
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2), // reduced spacing
                            Text(
                              template['description']!,
                              style: TextStyle(
                                fontSize: 8.0, // reduced font size
                                color: isDarkMode
                                    ? Colors.white70
                                    : const Color(0xFF64748B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2), // reduced spacing
                            Text(
                              'Learn More',
                              style: TextStyle(
                                color: isDarkMode
                                    ? const Color(0xFF60A5FA)
                                    : Colors.blue,
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Padding(
                          padding:
                              EdgeInsets.only(left: 4.0), // reduced spacing
                          child: Icon(Icons.check_circle,
                              color: Color(0xFF3B82F6),
                              size: 14), // reduced icon size
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
