import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/app/features/project/presentation/widgets/project_templates.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/store/project_provider.dart';
import 'package:flutter_realtime_workspace/core/utils/file_picker.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'dart:io';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen>
    with TickerProviderStateMixin {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController =
      TextEditingController();
  final TextEditingController _projectKeyController = TextEditingController();

  String? _selectedTemplate;
  File? _uploadedFile;
  String? _uploadedFileName;
  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _isGettingProjectKey = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

  @override
  void initState() {
    print('[CreateProjectScreen] initState');
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    print('[CreateProjectScreen] dispose');
    _animationController.dispose();
    _projectNameController.dispose();
    _projectDescriptionController.dispose();
    _projectKeyController.dispose();
    super.dispose();
  }

  void _handleTemplateSelected(String? template) {
    print('[CreateProjectScreen] _handleTemplateSelected: $template');
    setState(() {
      _selectedTemplate = template;
    });
  }

  Future<void> _handleFileUpload() async {
    print('[CreateProjectScreen] _handleFileUpload');
    setState(() {
      _isUploading = true;
    });

    try {
      // Show the bottom modal for file type selection
      print('[CreateProjectScreen] Showing file type modal...');
      final fileType = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: false,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: THelperFunctions.isDarkMode(context)
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFF3B82F6)),
                title: const Text('Pick Image',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () => Navigator.pop(context, 'image'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: Colors.grey.withOpacity(0.08),
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFF3B82F6)),
                title:  const Text('Pick Video',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () => Navigator.pop(context, 'video'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: Colors.grey.withOpacity(0.08),
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack, color: Color(0xFF3B82F6)),
                title: const Text('Pick Audio',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () => Navigator.pop(context, 'audio'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: Colors.grey.withOpacity(0.08),
              ),
              ListTile(
                leading:
                    const Icon(Icons.description, color: Color(0xFF3B82F6)),
                title: const Text('Pick Document',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () => Navigator.pop(context, 'document'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: Colors.grey.withOpacity(0.08),
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file,
                    color: Color(0xFF3B82F6)),
                title:  const Text('Pick Any File',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () => Navigator.pop(context, 'any'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: Colors.grey.withOpacity(0.08),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.cancel, color: Color(0xFF64748B)),
                title: const Text('Cancel',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () => Navigator.pop(context, null),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: Colors.grey.withOpacity(0.08),
              ),
            ],
          ),
        ),
      );

      print('[CreateProjectScreen] File type selected: $fileType');
      File? pickedFile;
      if (fileType == 'image') {
        pickedFile = await pickImageFromGallery();
      } else if (fileType == 'video') {
        pickedFile = await pickVideo();
      } else if (fileType == 'audio') {
        pickedFile = await pickAudio();
      } else if (fileType == 'document') {
        pickedFile = await pickDocument();
      } else if (fileType == 'any') {
        pickedFile = await pickAnyFile();
      }

      print('[CreateProjectScreen] Picked file: ${pickedFile?.path}');
      if (pickedFile != null) {
        setState(() {
          _uploadedFile = pickedFile;
          _uploadedFileName = pickedFile?.path.split('/').last;
        });
        context.showToast('File uploaded: $_uploadedFileName',
            type: ToastType.success);
      } else if (fileType != null) {
        context.showToast('No file selected.', type: ToastType.warning);
      }
    } catch (e) {
      print('[CreateProjectScreen] Error in _handleFileUpload: $e');
      context.showToast('Failed to upload file: $e', type: ToastType.error);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Map<String, dynamic> _collectProjectFormData() {
    print('[CreateProjectScreen] _collectProjectFormData');
    return {
      'name': _projectNameController.text.trim(),
      'description': _projectDescriptionController.text.trim(),
      'key': _projectKeyController.text.trim(),
      'template': _selectedTemplate,
    };
  }

  Future<void> _onCreateProjectPressed() async {
    print('[CreateProjectScreen] _onCreateProjectPressed');
    final formData = _collectProjectFormData();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(projectFormProvider.notifier).createProject(
            formData,
            filePaths: _uploadedFile != null ? [_uploadedFile!.path] : null,
          );
      setState(() => _isSubmitting = false);
      if (mounted) {
        context.showToast('Project created successfully!',
            type: ToastType.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('[CreateProjectScreen] Error in _onCreateProjectPressed: $e');
      setState(() => _isSubmitting = false);
      if (mounted) {
        context.showToast('Failed to create project: $e',
            type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[CreateProjectScreen] build');
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final projectState = ref.watch(projectFormProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor:
              isDarkMode ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
          appBar: _buildAppBar(isDarkMode),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0), // reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16), // reduced spacing
                      _buildProjectForm(isDarkMode),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isSubmitting || projectState.isLoading)
          Container(
            color: Colors.black.withOpacity(0.2),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(4), // reduced margin
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF1E293B).withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8), // reduced radius
          border: Border.all(
            color:
                isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            size: 14, // reduced icon size
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        'Create Project',
        style: TextStyle(
          fontSize: 16, // reduced font size
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
      centerTitle: false,
      toolbarHeight: 40, // reduced height
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10), // reduced padding
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12), // reduced radius
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), // reduced padding
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF),
                  borderRadius: BorderRadius.circular(8), // reduced radius
                ),
                child: const Icon(
                  Icons.folder_special,
                  color: Colors.white,
                  size: 18, // reduced icon size
                ),
              ),
              const SizedBox(width: 8), // reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Workspace',
                      style: TextStyle(
                        fontSize: 12, // reduced font size
                        fontWeight: FontWeight.bold,
                        color: THelperFunctions.isDarkMode(context)
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2), // reduced spacing
                    Text(
                      'Set up your project workspace with templates and resources',
                      style: TextStyle(
                        fontSize: 9, // reduced font size
                        color: THelperFunctions.isDarkMode(context)
                            ? Colors.white70
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectForm(bool isDarkMode) {
    final notifier = ref.read(projectFormProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Project Details', Icons.info_outline),
        const SizedBox(height: 8), // reduced spacing
        _buildModernTextField(
          controller: _projectNameController,
          label: 'Project Name',
          hint: 'Enter your project name',
          icon: Icons.edit_outlined,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 10), // reduced spacing
        _buildModernTextField(
          controller: _projectDescriptionController,
          label: 'Description',
          hint: 'Describe your project goals and objectives',
          icon: Icons.description_outlined,
          maxLines: 2, // reduced lines
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 10), // reduced spacing

        // Project Key (uneditable + button)
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _projectKeyController,
                label: 'Project Key',
                hint: 'e.g., PROJ-001',
                icon: Icons.key_outlined,
                isDarkMode: isDarkMode,
                enabled: false,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: _isGettingProjectKey
                    ? null
                    : () async {
                        setState(() => _isGettingProjectKey = true);
                        try {
                          final key = await notifier.fetchNewProjectKey();
                          setState(() {
                            _projectKeyController.text = key;
                          });
                        } catch (e) {
                          if (mounted) {
                            context.showToast('Failed to get project key: $e',
                                type: ToastType.error);
                          }
                        } finally {
                          setState(() => _isGettingProjectKey = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isGettingProjectKey
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Get Project Key',
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10), // reduced spacing

        _buildSectionTitle(
            'Template Selection', Icons.dashboard_customize_outlined),
        const SizedBox(height: 8), // reduced spacing
        _buildTemplateSection(isDarkMode),
        const SizedBox(height: 16), // reduced spacing

        _buildSectionTitle('Resources', Icons.upload_file_outlined),
        const SizedBox(height: 8), // reduced spacing
        _buildFileUploadSection(isDarkMode),
        const SizedBox(height: 20), // reduced spacing

        _buildCreateButton(isDarkMode),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF3B82F6),
          size: 14, // reduced icon size
        ),
        const SizedBox(width: 4), // reduced spacing
        Text(
          title,
          style: TextStyle(
            fontSize: 12, // reduced font size
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    int maxLines = 1,
    bool enabled = true,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8), // reduced radius
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.08)
                : Colors.grey.withOpacity(0.03),
            blurRadius: 4, // reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        style: TextStyle(
          fontSize: 12, // reduced font size
          color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF3B82F6),
            size: 14, // reduced icon size
          ),
          suffixIcon: suffix,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
            fontSize: 10, // reduced font size
          ),
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white38 : const Color(0xFF94A3B8),
            fontSize: 10, // reduced font size
          ),
          filled: true,
          fillColor: isDarkMode
              ? const Color(0xFF1E293B).withOpacity(0.8)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // reduced radius
            borderSide: BorderSide(
              color: isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // reduced radius
            borderSide: BorderSide(
              color: isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // reduced radius
            borderSide: const BorderSide(
              color: Color(0xFF3B82F6),
              width: 1.5, // reduced width
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10, // reduced padding
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(10), // reduced padding
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E293B).withOpacity(0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(12), // reduced radius
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.08)
                : Colors.grey.withOpacity(0.03),
            blurRadius: 4, // reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProjectTemplateDropdown(
            projectTemplates: _projectTemplates,
            onTemplateSelected: _handleTemplateSelected,
          ),
          if (_selectedTemplate != null) ...[
            const SizedBox(height: 8), // reduced spacing
            Container(
              padding: const EdgeInsets.all(8), // reduced padding
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8), // reduced radius
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF3B82F6),
                    size: 14, // reduced icon size
                  ),
                  const SizedBox(width: 6), // reduced spacing
                  Expanded(
                    child: Text(
                      'Selected: $_selectedTemplate',
                      style: TextStyle(
                        fontSize: 10, // reduced font size
                        fontWeight: FontWeight.w500,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileUploadSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(10), // reduced padding
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E293B).withOpacity(0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(12), // reduced radius
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.08)
                : Colors.grey.withOpacity(0.03),
            blurRadius: 4, // reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Project Structure',
            style: TextStyle(
              fontSize: 12, // reduced font size
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4), // reduced spacing
          Text(
            'PDF, Image, or Video files',
            style: TextStyle(
              fontSize: 9, // reduced font size
              color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8), // reduced spacing

          if (_uploadedFileName != null) ...[
            Container(
              padding: const EdgeInsets.all(8), // reduced padding
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8), // reduced radius
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 14, // reduced icon size
                  ),
                  const SizedBox(width: 6), // reduced spacing
                  Expanded(
                    child: Text(
                      _uploadedFileName!,
                      style: TextStyle(
                        fontSize: 10, // reduced font size
                        fontWeight: FontWeight.w500,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF64748B),
                      size: 12, // reduced icon size
                    ),
                    onPressed: () {
                      setState(() {
                        _uploadedFile = null;
                        _uploadedFileName = null;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6), // reduced spacing
          ],

          InkWell(
            onTap: _isUploading ? null : _handleFileUpload,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 10), // reduced padding
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8), // reduced radius
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: _isUploading
                  ? const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_upload_outlined,
                          color: Color(0xFF3B82F6),
                          size: 14, // reduced icon size
                        ),
                        const SizedBox(width: 4), // reduced spacing
                        Text(
                          'Choose File',
                          style: TextStyle(
                            fontSize: 10, // reduced font size
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(bool isDarkMode) {
    final projectState = ref.watch(projectFormProvider);
    return Container(
      width: double.infinity,
      height: 36, // reduced height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8), // reduced radius
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withOpacity(0.15),
            blurRadius: 6, // reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isSubmitting || projectState.isLoading)
            ? null
            : _onCreateProjectPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E40AF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // reduced radius
          ),
          padding: EdgeInsets.zero,
        ),
        child: (_isSubmitting || projectState.isLoading)
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rocket_launch_outlined,
                    color: Colors.white,
                    size: 14, // reduced icon size
                  ),
                  SizedBox(width: 4), // reduced spacing
                  Text(
                    'Create Project',
                    style: TextStyle(
                      fontSize: 12, // reduced font size
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}