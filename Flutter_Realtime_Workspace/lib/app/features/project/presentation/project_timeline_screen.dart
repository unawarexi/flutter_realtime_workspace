import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/features/project/presentation/widgets/project_boards.dart';
import 'package:flutter_realtime_workspace/app/features/project/presentation/widgets/project_summary.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';

class ProjectTimelineScreen extends StatefulWidget {
  final String projectName;

  const ProjectTimelineScreen({super.key, required this.projectName});

  @override
  State<ProjectTimelineScreen> createState() => _ProjectTimelineScreenState();
}

class _ProjectTimelineScreenState extends State<ProjectTimelineScreen>
    with TickerProviderStateMixin {
  bool _showFilters = false;
  int _activeTabIndex = 0;
  late AnimationController _filterAnimationController;
  late AnimationController _tabAnimationController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
    _tabAnimationController.forward();
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? TColors.backgroundColorDark : TColors.backgroundColorLight;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildModernAppBar(isDarkMode),
      body: Column(
        children: [
          AnimatedBuilder(
            animation: _filterAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _filterAnimation,
                child: _showFilters ? _buildFilterSection(isDarkMode) : const SizedBox(),
              );
            },
          ),
          _buildModernTabs(isDarkMode),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildTabContent(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(bool isDarkMode) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDarkMode ? TColors.primaryBlue : TColors.primaryBlue,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.projectName,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: AnimatedRotation(
              turns: _showFilters ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.tune, color: Colors.white, size: 22),
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
                if (_showFilters) {
                  _filterAnimationController.forward();
                } else {
                  _filterAnimationController.reverse();
                }
              });
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            onPressed: () => _showProjectMenu(isDarkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTabs(bool isDarkMode) {
    final tabTitles = ["Summary", "Board", "Forms", "Timeline", "Settings"];
    final cardColor = isDarkMode ? TColors.cardColorDark : TColors.cardColorLight;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      color: cardColor,
      child: Row(
        children: List.generate(tabTitles.length, (index) {
          return Expanded(child: _buildModernTabOption(tabTitles[index], index, isDarkMode));
        }),
      ),
    );
  }

  Widget _buildModernTabOption(String title, int index, bool isDarkMode) {
    bool isActive = _activeTabIndex == index;
    final textSecondary = isDarkMode ? TColors.textSecondaryDark : TColors.textSecondaryLight;
    final activeColor = isDarkMode ? TColors.accentBlue : TColors.primaryBlue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? activeColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? activeColor : textSecondary,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDarkMode) {
    switch (_activeTabIndex) {
      case 0:
        return ProjectSummaryScreen(
          isDarkMode: isDarkMode,
          onFeedbackTap: () {},
        );
      case 1:
        return ProjectBoards(
          isDarkMode: isDarkMode,
          onShowAttachmentOptions: _showAttachmentOptions,
          onShowTaskCreationModal: _showTaskCreationModal,
        );
      case 2:
        return _buildFormsContent(isDarkMode);
      case 3:
        return _buildTimelineContent(isDarkMode);
      case 4:
        return _buildSettingsContent(isDarkMode);
      default:
        return Container();
    }
  }

  Widget _buildFormsContent(bool isDarkMode) {
    final textPrimary = isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    final textSecondary = isDarkMode ? TColors.textSecondaryDark : TColors.textSecondaryLight;
    return Container(
      key: const ValueKey('forms'),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: textSecondary),
            const SizedBox(height: 16),
            Text(
              'Forms & Templates',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create custom forms and templates for your team',
              style: TextStyle(fontSize: 14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineContent(bool isDarkMode) {
    final textPrimary = isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    final textSecondary = isDarkMode ? TColors.textSecondaryDark : TColors.textSecondaryLight;
    return Container(
      key: const ValueKey('timeline'),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline_outlined, size: 64, color: textSecondary),
            const SizedBox(height: 20),
            Text(
              'Project Timeline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Plan and track your project milestones',
              style: TextStyle(fontSize: 14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent(bool isDarkMode) {
    final textPrimary = isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    final textSecondary = isDarkMode ? TColors.textSecondaryDark : TColors.textSecondaryLight;
    return Container(
      key: const ValueKey('settings'),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_outlined, size: 64, color: textSecondary),
            const SizedBox(height: 20),
            Text(
              'Project Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Configure your project preferences and permissions',
              style: TextStyle(fontSize: 14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isDarkMode) {
    final cardColor = isDarkMode ? TColors.cardColorDark : TColors.cardColorLight;
    final textPrimary = isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildModernFilterOption('Group by', ['None', 'Assignees', 'Epics', 'Subtasks'], isDarkMode),
          const SizedBox(height: 12),
          _buildModernFilterOption('Assignee', ['Me', 'Admin', 'Team Lead', 'HR', 'Project Lead'], isDarkMode),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Clear all filters',
              style: TextStyle(
                color: TColors.lightBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterOption(String title, List<String> options, bool isDarkMode) {
    final textPrimary = isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    final textSecondary = isDarkMode ? TColors.textSecondaryDark : TColors.textSecondaryLight;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        children: options.map((option) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: ListTile(
              title: Text(
                option,
                style: TextStyle(color: textSecondary),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () {},
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showProjectMenu(bool isDarkMode) {
    final cardColor = isDarkMode ? TColors.cardColorDark : TColors.cardColorLight;
    final textPrimary = isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Project Menu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              _buildMenuOption(Icons.share_outlined, "Share Project", isDarkMode),
              _buildMenuOption(Icons.people_outline, "Manage Team", isDarkMode),
              _buildMenuOption(Icons.archive_outlined, "Archive Project", isDarkMode),
              _buildMenuOption(Icons.delete_outline, "Delete Project", isDarkMode),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(IconData icon, String label, bool isDarkMode) {
    final textPrimary = isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    final textSecondary = isDarkMode ? TColors.textSecondaryDark : TColors.textSecondaryLight;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: textSecondary),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: textPrimary,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => Navigator.pop(context),
      ),
    );
  }

  void _showAttachmentOptions() {
    // You can implement your attachment logic here or leave as a stub
    // Example: show a modal or call another service
  }

  void _showTaskCreationModal(bool isDarkMode) {
    // You can implement your task creation logic here or leave as a stub
    // Example: show a modal or call another service
  }
}