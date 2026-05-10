import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';
import 'package:table_calendar/table_calendar.dart';

class ProjectMore extends StatefulWidget {
  final ScrollController? scrollController;
  const ProjectMore({super.key, this.scrollController});

  @override
  State<ProjectMore> createState() => _ProjectMoreState();
}

class _ProjectMoreState extends State<ProjectMore> with TickerProviderStateMixin {
  String _assignee = 'Unassigned';
  String _label = '';
  String _parent = '';
  DateTime? _dueDate;
  String _reporter = 'User 1';
  bool _flagged = false;
  bool _impediment = false;
  String _flagNote = '';
  String _priority = 'Medium';
  double _progress = 0.0;
  String _status = 'To Do';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _users = ['Unassigned', 'User 1', 'User 2', 'User 3', 'User 4'];
  final List<String> _parents = ['Work Item 1', 'Work Item 2', 'Work Item 3', 'Work Item 4'];
  final List<String> _reporters = ['User 1', 'User 2', 'User 3', 'User 4'];
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];
  final List<String> _statuses = ['To Do', 'In Progress', 'Review', 'Done'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final cardColor = isDarkMode ? TColors.cardColorDark : TColors.cardColorLight;
    final textPrimary = isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    final textSecondary = isDarkMode ? TColors.textSecondaryDark : TColors.textSecondaryLight;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Modern drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  
                  // Header with enhanced styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                TColors.quickActionBlue,
                                TColors.quickActionBlue.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: TColors.quickActionBlue.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Task Configuration',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manage task details and settings',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress indicator section
                  if (_status != 'To Do')
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            TColors.quickActionBlue.withOpacity(0.1),
                            TColors.quickActionPurple.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: TColors.quickActionBlue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '${(_progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: TColors.quickActionBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: textSecondary.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(TColors.quickActionBlue),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Slider(
                            value: _progress,
                            onChanged: (value) => setState(() => _progress = value),
                            activeColor: TColors.quickActionBlue,
                            inactiveColor: textSecondary.withOpacity(0.2),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: ListView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      children: [
                        // Core Information Section
                        _buildSectionHeader('Core Information', Icons.info_outline, textPrimary, textSecondary),
                        const SizedBox(height: 12),
                        _buildModernCard([
                          _buildEnhancedItem(
                            Icons.person_outline,
                            'Assignee',
                            textPrimary,
                            textSecondary,
                            value: _assignee,
                            onTap: () => _showAssigneeDropdown(context, textPrimary, textSecondary, cardColor, isDarkMode),
                            hasAvatar: true,
                          ),
                          _buildEnhancedItem(
                            Icons.flag_outlined,
                            'Priority',
                            textPrimary,
                            textSecondary,
                            value: _priority,
                            onTap: () => _showPriorityDropdown(context, textPrimary, textSecondary, cardColor, isDarkMode),
                            valueColor: _getPriorityColor(_priority),
                          ),
                          _buildEnhancedItem(
                            Icons.timeline_outlined,
                            'Status',
                            textPrimary,
                            textSecondary,
                            value: _status,
                            onTap: () => _showStatusDropdown(context, textPrimary, textSecondary, cardColor, isDarkMode),
                            valueColor: _getStatusColor(_status),
                          ),
                        ], cardColor, isDarkMode),

                        const SizedBox(height: 24),

                        // Metadata Section
                        _buildSectionHeader('Metadata', Icons.label_outline, textPrimary, textSecondary),
                        const SizedBox(height: 12),
                        _buildModernCard([
                          _buildEnhancedItem(
                            Icons.local_offer_outlined,
                            'Labels',
                            textPrimary,
                            textSecondary,
                            value: _label.isEmpty ? 'Add labels' : _label,
                            onTap: () => _showLabelInput(context, textPrimary, cardColor, isDarkMode),
                          ),
                          _buildEnhancedItem(
                            Icons.account_tree_outlined,
                            'Parent Item',
                            textPrimary,
                            textSecondary,
                            value: _parent.isEmpty ? 'No parent' : _parent,
                            onTap: () => _showParentDropdown(context, textPrimary, textSecondary, cardColor, isDarkMode),
                          ),
                          _buildEnhancedItem(
                            Icons.account_circle_outlined,
                            'Reporter',
                            textPrimary,
                            textSecondary,
                            value: _reporter,
                            onTap: () => _showReporterDropdown(context, textPrimary, textSecondary, cardColor, isDarkMode),
                            hasAvatar: true,
                          ),
                        ], cardColor, isDarkMode),

                        const SizedBox(height: 24),

                        // Timeline Section
                        _buildSectionHeader('Timeline & Team', Icons.schedule_outlined, textPrimary, textSecondary),
                        const SizedBox(height: 12),
                        _buildModernCard([
                          _buildEnhancedItem(
                            Icons.calendar_month_outlined,
                            'Due Date',
                            textPrimary,
                            textSecondary,
                            value: _dueDate == null ? 'Set due date' : _formatDate(_dueDate!),
                            onTap: () => _showDueDatePicker(context, cardColor, textPrimary, isDarkMode),
                            valueColor: _dueDate != null && _dueDate!.isBefore(DateTime.now()) 
                                ? TColors.error 
                                : null,
                          ),
                          _buildEnhancedItem(
                            Icons.groups_outlined,
                            'Team',
                            textPrimary,
                            textSecondary,
                            value: 'Configure team',
                            onTap: () => _goToTeamScreen(context, isDarkMode),
                          ),
                        ], cardColor, isDarkMode),

                        const SizedBox(height: 24),

                        // Alerts Section
                        if (_flagged || _impediment)
                          Column(
                            children: [
                              _buildSectionHeader('Alerts', Icons.warning_amber_outlined, textPrimary, textSecondary),
                              const SizedBox(height: 12),
                              _buildModernCard([
                                _buildEnhancedItem(
                                  Icons.outlined_flag,
                                  'Flagged Task',
                                  textPrimary,
                                  textSecondary,
                                  value: _flagged ? 'Task is flagged' : 'Not flagged',
                                  onTap: () => _showFlaggedModal(context, textPrimary, cardColor, isDarkMode),
                                  valueColor: _flagged ? TColors.error : null,
                                ),
                              ], cardColor, isDarkMode),
                              const SizedBox(height: 24),
                            ],
                          ),
                        
                        // Flag Action Button
                        if (!_flagged)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 32),
                            child: OutlinedButton.icon(
                              onPressed: () => _showFlaggedModal(context, textPrimary, cardColor, isDarkMode),
                              icon: const Icon(Icons.flag_outlined, size: 20),
                              label: const Text('Flag Task'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: TColors.error,
                                side: BorderSide(color: TColors.error.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: TColors.quickActionBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: TColors.quickActionBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildModernCard(List<Widget> children, Color cardColor, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? cardColor.withOpacity(0.7) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: children.map((child) => 
          children.indexOf(child) == children.length - 1 
              ? child 
              : Column(
                  children: [
                    child,
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDarkMode 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.black.withOpacity(0.05),
                      indent: 68,
                    ),
                  ],
                )
        ).toList(),
      ),
    );
  }

  Widget _buildEnhancedItem(
    IconData icon,
    String label,
    Color textPrimary,
    Color textSecondary, {
    String? value,
    VoidCallback? onTap,
    Color? valueColor,
    bool hasAvatar = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: TColors.quickActionBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: TColors.quickActionBlue, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (hasAvatar) ...[
                          CircleAvatar(
                            radius: 8,
                            backgroundColor: TColors.quickActionBlue.withOpacity(0.2),
                            child: Text(
                              value.isNotEmpty ? value[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: TColors.quickActionBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 14,
                              color: valueColor ?? textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textSecondary.withOpacity(0.7),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return TColors.error;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return TColors.quickActionBlue;
      case 'Low':
        return Colors.green;
      default:
        return TColors.quickActionBlue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Done':
        return Colors.green;
      case 'In Progress':
        return TColors.quickActionBlue;
      case 'Review':
        return TColors.quickActionPurple;
      case 'To Do':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference < -1) return '${difference.abs()} days ago';
    if (difference > 1) return 'In $difference days';
    
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _showPriorityDropdown(BuildContext context, Color textPrimary, Color textSecondary, Color cardColor, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _buildScrollableDropdown(
          title: 'Select Priority',
          items: _priorities,
          selected: _priority,
          onSelected: (val) {
            setState(() => _priority = val);
            Navigator.pop(context);
          },
          cardColor: cardColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDarkMode: isDarkMode,
          searchable: false,
          showColors: true,
          getItemColor: _getPriorityColor,
        );
      },
    );
  }

  void _showStatusDropdown(BuildContext context, Color textPrimary, Color textSecondary, Color cardColor, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _buildScrollableDropdown(
          title: 'Select Status',
          items: _statuses,
          selected: _status,
          onSelected: (val) {
            setState(() => _status = val);
            Navigator.pop(context);
          },
          cardColor: cardColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDarkMode: isDarkMode,
          searchable: false,
          showColors: true,
          getItemColor: _getStatusColor,
        );
      },
    );
  }

  void _showAssigneeDropdown(BuildContext context, Color textPrimary, Color textSecondary, Color cardColor, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _buildScrollableDropdown(
          title: 'Assign To',
          items: _users,
          selected: _assignee,
          onSelected: (val) {
            setState(() => _assignee = val);
            Navigator.pop(context);
          },
          cardColor: cardColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDarkMode: isDarkMode,
          searchable: true,
          showAvatars: true,
        );
      },
    );
  }

  void _showLabelInput(BuildContext context, Color textPrimary, Color cardColor, bool isDarkMode) {
    final controller = TextEditingController(text: _label);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: TColors.quickActionBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.label_outline, color: TColors.quickActionBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Labels',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter labels (comma separated)...',
                    filled: true,
                    fillColor: isDarkMode 
                        ? Colors.white.withOpacity(0.05) 
                        : Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: TColors.quickActionBlue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.quickActionBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() => _label = controller.text);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Save Labels',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showParentDropdown(BuildContext context, Color textPrimary, Color textSecondary, Color cardColor, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _buildScrollableDropdown(
          title: 'Select Parent Item',
          items: _parents,
          selected: _parent,
          onSelected: (val) {
            setState(() => _parent = val);
            Navigator.pop(context);
          },
          cardColor: cardColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDarkMode: isDarkMode,
          searchable: true,
        );
      },
    );
  }

  void _showDueDatePicker(BuildContext context, Color cardColor, Color textPrimary, bool isDarkMode) async {
    DateTime now = DateTime.now();
    DateTime selected = _dueDate ?? now;
    DateTime focusedDay = selected;
    int selectedYear = selected.year;
    final List<int> years = List.generate(201, (index) => 1900 + index); // Generate years from 1900 to 2100

    DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: TColors.quickActionBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_month_outlined, color: TColors.quickActionBlue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Select Due Date",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Year Dropdown with enhanced styling
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? Colors.white.withOpacity(0.05) 
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: Container(
                                  width: 280,
                                  height: 300,
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'Select Year',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: years.length,
                                          itemBuilder: (context, index) {
                                            final year = years[index];
                                            final isSelected = year == selectedYear;
                                            return InkWell(
                                              onTap: () {
                                                setStateDialog(() {
                                                  selectedYear = year;
                                                  focusedDay = DateTime(
                                                    selectedYear,
                                                    focusedDay.month,
                                                    focusedDay.day,
                                                  );
                                                });
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? TColors.quickActionBlue.withOpacity(0.1)
                                                      : Colors.transparent,
                                                  border: isSelected
                                                      ? Border.all(
                                                          color: TColors.quickActionBlue.withOpacity(0.3),
                                                          width: 1,
                                                        )
                                                      : null,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                margin: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 4,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      year.toString(),
                                                      style: TextStyle(
                                                        color: isSelected
                                                            ? TColors.quickActionBlue
                                                            : textPrimary,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      const Icon(
                                                        Icons.check_circle,
                                                        color: TColors.quickActionBlue,
                                                        size: 20,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Year: $selectedYear",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: TColors.quickActionBlue,
                                  fontSize: 16,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today_outlined,
                                color: textPrimary.withOpacity(0.7),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Enhanced Calendar
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode 
                                ? Colors.white.withOpacity(0.1) 
                                : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: TableCalendar(
                          firstDay: DateTime(now.year - 5),
                          lastDay: DateTime(now.year + 5),
                          focusedDay: focusedDay,
                          selectedDayPredicate: (day) => isSameDay(day, selected),
                          onDaySelected: (day, _) {
                            setStateDialog(() {
                              selected = day;
                              focusedDay = day;
                              selectedYear = day.year;
                            });
                          },
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: TColors.quickActionBlue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  TColors.quickActionBlue,
                                  TColors.quickActionBlue.withOpacity(0.8),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: TColors.quickActionBlue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            weekendTextStyle: const TextStyle(
                              color: TColors.quickActionPurple,
                              fontWeight: FontWeight.w600,
                            ),
                            defaultTextStyle: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            outsideTextStyle: TextStyle(
                              color: isDarkMode 
                                  ? TColors.textSecondaryDark.withOpacity(0.5)
                                  : TColors.textSecondaryLight.withOpacity(0.5),
                            ),
                            cellMargin: const EdgeInsets.all(4),
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: const TextStyle(
                              color: TColors.quickActionBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                            leftChevronIcon: Container(
                              decoration: BoxDecoration(
                                color: TColors.quickActionBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.chevron_left,
                                color: TColors.quickActionBlue,
                              ),
                            ),
                            rightChevronIcon: Container(
                              decoration: BoxDecoration(
                                color: TColors.quickActionBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.chevron_right,
                                color: TColors.quickActionBlue,
                              ),
                            ),
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              color: TColors.quickActionBlue,
                              fontWeight: FontWeight.w600,
                            ),
                            weekendStyle: TextStyle(
                              color: TColors.quickActionPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(
                                  color: isDarkMode 
                                      ? Colors.white.withOpacity(0.2) 
                                      : Colors.black.withOpacity(0.2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                setState(() => _dueDate = null);
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColors.quickActionBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                              ),
                              onPressed: () {
                                setState(() => _dueDate = selected);
                                Navigator.of(context).pop(selected);
                              },
                              child: const Text(
                                'Set Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _goToTeamScreen(BuildContext context, bool isDarkMode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Team Configuration'),
            backgroundColor: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: const Center(
            child: Text(
              'Team selection and configuration screen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  void _showReporterDropdown(BuildContext context, Color textPrimary, Color textSecondary, Color cardColor, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _buildScrollableDropdown(
          title: 'Select Reporter',
          items: _reporters,
          selected: _reporter,
          onSelected: (val) {
            setState(() => _reporter = val);
            Navigator.pop(context);
          },
          cardColor: cardColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDarkMode: isDarkMode,
          searchable: true,
          showAvatars: true,
        );
      },
    );
  }

  void _showFlaggedModal(BuildContext context, Color textPrimary, Color cardColor, bool isDarkMode) {
    final controller = TextEditingController(text: _flagNote);
    bool tempImpediment = _impediment;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: TColors.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.flag_outlined,
                              color: TColors.error,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Flag Task',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mark this task for attention',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textPrimary.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      TextField(
                        controller: controller,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Reason for flagging (optional)...',
                          filled: true,
                          fillColor: isDarkMode 
                              ? Colors.white.withOpacity(0.05) 
                              : Colors.grey.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: TColors.error, width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Enhanced checkbox
                      InkWell(
                        onTap: () => setDialogState(() => tempImpediment = !tempImpediment),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: tempImpediment 
                                ? TColors.error.withOpacity(0.1) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tempImpediment 
                                  ? TColors.error.withOpacity(0.3) 
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: tempImpediment ? TColors.error : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: tempImpediment 
                                        ? TColors.error 
                                        : textPrimary.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: tempImpediment
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mark as Impediment',
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'This task is blocked or preventing progress',
                                      style: TextStyle(
                                        color: textPrimary.withOpacity(0.7),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        children: [
                          if (_flagged) ...[
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(
                                    color: isDarkMode 
                                        ? Colors.white.withOpacity(0.2) 
                                        : Colors.black.withOpacity(0.2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _flagged = false;
                                    _impediment = false;
                                    _flagNote = '';
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Remove Flag',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            flex: _flagged ? 2 : 1,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColors.error,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                              ),
                              onPressed: () {
                                setState(() {
                                  _flagged = true;
                                  _impediment = tempImpediment;
                                  _flagNote = controller.text;
                                });
                                Navigator.pop(context);
                              },
                              child: Text(
                                _flagged ? 'Update Flag' : 'Flag Task',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScrollableDropdown({
    required String title,
    required List<String> items,
    required String selected,
    required void Function(String) onSelected,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDarkMode,
    bool searchable = false,
    bool showColors = false,
    bool showAvatars = false,
    Color Function(String)? getItemColor,
  }) {
    TextEditingController searchController = TextEditingController();
    List<String> filteredItems = List.from(items);

    return StatefulBuilder(
      builder: (context, setModalState) {
        void filter(String query) {
          setModalState(() {
            filteredItems = items
                .where((item) => item.toLowerCase().contains(query.toLowerCase()))
                .toList();
          });
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle and title section (not scrollable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        // Handle bar
                        Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: textSecondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (searchable) ...[
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: searchController,
                                    onChanged: filter,
                                    decoration: InputDecoration(
                                      hintText: 'Search...',
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: textSecondary.withOpacity(0.7),
                                      ),
                                      filled: true,
                                      fillColor: isDarkMode 
                                          ? Colors.white.withOpacity(0.05) 
                                          : Colors.grey.withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: TColors.quickActionBlue,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, idx) {
                                final item = filteredItems[idx];
                                final isSelected = item == selected;
                                final itemColor = showColors && getItemColor != null 
                                    ? getItemColor(item) 
                                    : null;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: _buildDropdownItem(
                                    item,
                                    isSelected,
                                    itemColor,
                                    showAvatars,
                                    onSelected,
                                    textPrimary,
                                  ),
                                );
                              },
                              childCount: filteredItems.length,
                            ),
                          ),
                        ),
                        const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownItem(
    String item,
    bool isSelected,
    Color? itemColor,
    bool showAvatars,
    void Function(String) onSelected,
    Color textPrimary,
  ) {
    return InkWell(
      onTap: () => onSelected(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? TColors.quickActionBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: TColors.quickActionBlue.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            if (showAvatars) ...[
              CircleAvatar(
                radius: 18,
                backgroundColor: TColors.quickActionBlue.withOpacity(0.2),
                child: Text(
                  item.isNotEmpty ? item[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TColors.quickActionBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (itemColor != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: itemColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  color: isSelected ? TColors.quickActionBlue : textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: TColors.quickActionBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}