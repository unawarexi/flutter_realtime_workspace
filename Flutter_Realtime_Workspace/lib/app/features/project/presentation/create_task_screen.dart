import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realtime_workspace/app/features/project/presentation/project_more.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';


class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen>
    with TickerProviderStateMixin {
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _summaryFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedTaskType = 'Task';
  bool _isRecording = false;
  String _selectedProject = 'Project 1';
  final List<String> _projects = [
    'Project 1',
    'Project 2',
    'Project 3',
    'Project 4',
    'Project 5',
  ];
  
  final List<String> _taskTypes = ['Task', 'Bug', 'Story', 'Epic'];
  
  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }
  
  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _summaryFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight;
    final cardColor = isDarkMode ? TColors.cardColorDark : TColors.cardColorLight;
    final textPrimary = isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    final textSecondary = isDarkMode ? TColors.textSecondaryDark : TColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(isDarkMode),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProjectHeader(textSecondary, cardColor, isDarkMode),
                const SizedBox(height: 24),
                _buildTaskTypeSelector(isDarkMode, cardColor, textPrimary, textSecondary),
                const SizedBox(height: 28),
                _buildSummarySection(cardColor, textPrimary, textSecondary),
                const SizedBox(height: 20),
                _buildDescriptionSection(cardColor, textPrimary, textSecondary),
                const SizedBox(height: 28),
                _buildAttachmentOptions(cardColor, textSecondary, isDarkMode),
                const SizedBox(height: 28),
                _buildMoreSection(textPrimary),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDarkMode ? TColors.backgroundColorDark : TColors.backgroundColorLight,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'CREATE',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight,
          letterSpacing: 1.2,
        ),
      ),
      centerTitle: true,
    );
  }
  
  // Modern card-like project header
  Widget _buildProjectHeader(Color textSecondary, Color cardColor, bool isDarkMode) {
    final textPrimary = isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    return GestureDetector(
      onTap: _showProjectSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? TColors.borderDark : TColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight).withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: TColors.primaryBlue.withOpacity(isDarkMode ? 0.12 : 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_open, color: TColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  _selectedProject,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Icon(Icons.keyboard_arrow_down, color: textSecondary, size: 28),
          ],
        ),
      ),
    );
  }

  void _showProjectSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? TColors.cardColorDark : TColors.cardColorLight;
    final textPrimary = isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    final textSecondary = isDarkMode ? TColors.textSecondaryDark : TColors.textSecondaryLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight).withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TColors.neutralGray.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Select Project',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _projects.length,
                  separatorBuilder: (_, __) => Divider(
                    color: isDarkMode
                        ? TColors.borderDark.withOpacity(0.15)
                        : TColors.borderLight.withOpacity(0.15),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    final isSelected = project == _selectedProject;
                    return ListTile(
                      leading: Icon(Icons.folder_open,
                          color: isSelected ? TColors.primaryBlue : textSecondary),
                      title: Text(
                        project,
                        style: TextStyle(
                          color: isSelected ? TColors.primaryBlue : textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: TColors.primaryBlue)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedProject = project;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTaskTypeSelector(bool isDarkMode, Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? TColors.borderDark : TColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTaskType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: TColors.buttonPrimaryLight),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          dropdownColor: cardColor,
          items: _taskTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _getTaskTypeColor(type).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getTaskTypeIcon(type),
                      size: 14,
                      color: _getTaskTypeColor(type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(type,
                    style: TextStyle(
                      color: _getTaskTypeColor(type),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedTaskType = newValue;
              });
            }
          },
        ),
      ),
    );
  }
  
  Color _getTaskTypeColor(String type) {
    switch (type) {
      case 'Task':
        return TColors.quickActionBlue;
      case 'Bug':
        return TColors.error;
      case 'Story':
        return TColors.quickActionGreen;
      case 'Epic':
        return TColors.quickActionPurple;
      default:
        return TColors.quickActionBlue;
    }
  }
  
  IconData _getTaskTypeIcon(String type) {
    switch (type) {
      case 'Task':
        return Icons.check_box_outline_blank;
      case 'Bug':
        return Icons.bug_report;
      case 'Story':
        return Icons.book;
      case 'Epic':
        return Icons.flag;
      default:
        return Icons.check_box_outline_blank;
    }
  }
  
  Widget _buildSummarySection(Color cardColor, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark ? TColors.borderDark : TColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (Theme.of(context).brightness == Brightness.dark ? TColors.buttonPrimary : TColors.buttonPrimaryLight).withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _summaryController,
            focusNode: _summaryFocusNode,
            style: TextStyle(
              fontSize: 16,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter task summary...',
              hintStyle: TextStyle(
                color: textSecondary,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(18),
            ),
            maxLines: 1,
          ),
        ),
        Container(
          height: 2,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                TColors.primaryBlue.withOpacity(0.2),
                TColors.accentBlue.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDescriptionSection(Color cardColor, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark ? TColors.borderDark : TColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (Theme.of(context).brightness == Brightness.dark ? TColors.buttonPrimary : TColors.buttonPrimaryLight).withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            style: TextStyle(
              fontSize: 16,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Add a description...',
              hintStyle: TextStyle(
                color: textSecondary,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(18),
            ),
            maxLines: 4,
            minLines: 3,
          ),
        ),
        Container(
          height: 2,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                TColors.primaryBlue.withOpacity(0.2),
                TColors.accentBlue.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAttachmentOptions(Color cardColor, Color textSecondary, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? TColors.borderDark : TColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            icon: Icons.camera_alt_outlined,
            label: 'Take photo',
            onTap: () => _handleAttachmentAction('photo'),
            cardColor: TColors.quickActionBlue.withOpacity(0.12),
            textColor: TColors.quickActionBlue,
            iconBg: TColors.quickActionBlue.withOpacity(0.12),
          ),
          _buildAttachmentOption(
            icon: Icons.videocam_outlined,
            label: 'Record video',
            onTap: () => _handleAttachmentAction('video'),
           cardColor: TColors.quickActionBlue.withOpacity(0.12),
            textColor: TColors.quickActionBlue,
            iconBg: TColors.quickActionBlue.withOpacity(0.12),
          ),
          _buildAttachmentOption(
            icon: Icons.attach_file_outlined,
            label: 'Choose file',
            onTap: () => _handleAttachmentAction('file'),
            cardColor: TColors.quickActionBlue.withOpacity(0.12),
            textColor: TColors.quickActionBlue,
            iconBg: TColors.quickActionBlue.withOpacity(0.12),
          ),
          _buildAttachmentOption(
            icon: _isRecording ? Icons.stop_circle : Icons.radio_button_checked,
            label: 'Record screen',
            onTap: () => _handleScreenRecording(),
            cardColor: TColors.quickActionBlue.withOpacity(0.12),
            textColor: _isRecording ? TColors.error : TColors.quickActionBlue,
            iconBg: TColors.quickActionBlue.withOpacity(0.12),
            isActive: _isRecording,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    required Color iconBg,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? textColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: textColor.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 24,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMoreSection(Color textPrimary) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => ProjectMore(
              scrollController: scrollController,
            ),
          ),
        );
      },
      child: Text(
        'More',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
  
  void _handleAttachmentAction(String type) {
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    // Show snackbar for demo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type attachment selected'),
        duration: const Duration(seconds: 2),
        backgroundColor: TColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  void _handleScreenRecording() {
    HapticFeedback.lightImpact();
    
    setState(() {
      _isRecording = !_isRecording;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRecording ? 'Screen recording started' : 'Screen recording stopped'),
        duration: const Duration(seconds: 2),
        backgroundColor: _isRecording ? TColors.error : TColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}