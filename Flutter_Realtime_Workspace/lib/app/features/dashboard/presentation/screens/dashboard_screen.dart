import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/app/features/dashboard/presentation/screens/default_dashboard.dart';
import 'package:flutter_realtime_workspace/app/features/dashboard/presentation/screens/financial_overview_dashboard.dart';
import 'package:flutter_realtime_workspace/app/features/dashboard/presentation/screens/gnatt_charts_dasboard.dart';
import 'package:flutter_realtime_workspace/app/features/dashboard/presentation/screens/milestone_dashboard.dart';
import 'package:flutter_realtime_workspace/app/features/dashboard/presentation/screens/starred_dashboards.dart';
import 'package:flutter_realtime_workspace/app/features/dashboard/presentation/screens/team_performance_dashboard.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  bool _isDropdownExpanded = false;
  String _selectedDashboard = "Default Dashboard";
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Modern color scheme with dark mode variants
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFFEFF6FF);
  static const Color darkBlue = Color(0xFF0F172A);
  
  Color get surfaceColor =>  isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight;
  Color get cardColor => isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get textPrimary => isDarkMode ? Colors.white : const Color(0xFF1F2937);
  Color get textSecondary => isDarkMode ? Colors.white70 : const Color(0xFF6B7280);
  bool get isDarkMode => THelperFunctions.isDarkMode(context);

  final Map<String, Widget> dashboardOptions = {
    "Starred Dashboards": const StarredDashboard(title: "Starred Dashboards"),
    "Default Dashboard":
        const DefaultDashboard("Some option", title: "Default Dashboard"),
    "Active Projects Dashboards": Container(),
    "Gantt Timeline Charts Dashboard":
        const GanttTimelineDashboard(title: "Gantt Timeline Charts"),
    "Team Performance Dashboard":
        const TeamPerformanceDashboard(title: "Team Performance"),
    "Milestones Dashboard":
        const MilestonesDashboard(title: "Milestones Dashboard"),
    "Financial Overview Dashboard":
        const FinancialOverviewDashboard(title: "Financial Overview"),
  };

  final Map<String, IconData> dashboardIcons = {
    "Starred Dashboards": Icons.star_rounded,
    "Default Dashboard": Icons.dashboard_rounded,
    "Active Projects Dashboards": Icons.work_rounded,
    "Gantt Timeline Charts Dashboard": Icons.timeline_rounded,
    "Team Performance Dashboard": Icons.people_rounded,
    "Milestones Dashboard": Icons.flag_rounded,
    "Financial Overview Dashboard": Icons.account_balance_wallet_rounded,
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                _buildModernAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(20.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildDashboardSelector(),
                      const SizedBox(height: 32),
                      if (!_isDropdownExpanded) _buildWelcomeSection(),
                      const SizedBox(height: 32),
                      _buildAssignedToMeSection(),
                      const SizedBox(height: 32),
                      _buildActivityStreamSection(),
                      const SizedBox(height: 32),
                      _buildFeedbackSection(),
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 70, // reduced height
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: Container(
        
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10), // reduced radius
              bottomRight: Radius.circular(10),
            ),
            border: Border.all(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.1)
                  : const Color(0xFFF1F5F9),
              width: 1,
            ),
          ),
          child: SafeArea(
            child: Padding(
               padding: const EdgeInsets.only(left: 10, right: 10, top: 16, bottom:0), // reduced padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workspace Dashboard',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 15, // reduced font size
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4), // reduced padding
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(6), // reduced radius
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: primaryBlue,
                      size: 12, // reduced icon size
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSelector() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8), // reduced radius
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.12)
                : primaryBlue.withOpacity(0.03),
            blurRadius: 8, // reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8), // reduced radius
          onTap: () {
            setState(() {
              _isDropdownExpanded = !_isDropdownExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(10), // reduced padding
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6), // reduced padding
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(6), // reduced radius
                      ),
                      child: Icon(
                        dashboardIcons[_selectedDashboard] ?? Icons.dashboard_rounded,
                        color: primaryBlue,
                        size: 14, // reduced icon size
                      ),
                    ),
                    const SizedBox(width: 6), // reduced spacing
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Dashboard',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 9, // reduced font size
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2), // reduced spacing
                          Text(
                            _selectedDashboard,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12, // reduced font size
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isDropdownExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: primaryBlue,
                        size: 18, // reduced icon size
                      ),
                    ),
                  ],
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: _isDropdownExpanded ? null : 0,
                  child: _isDropdownExpanded
                      ? Column(
                          children: [
                            const SizedBox(height: 8), // reduced spacing
                            Container(
                              height: 1,
                              color: lightBlue,
                            ),
                            const SizedBox(height: 6), // reduced spacing
                            ...dashboardOptions.keys.map((option) {
                              final isSelected = option == _selectedDashboard;
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 2), // reduced spacing
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6), // reduced radius
                                    onTap: () {
                                      setState(() {
                                        _selectedDashboard = option;
                                        _isDropdownExpanded = false;
                                      });
                                      if (dashboardOptions[option] != null) {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) =>
                                                dashboardOptions[option]!,
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              return SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(1.0, 0.0),
                                                  end: Offset.zero,
                                                ).animate(animation),
                                                child: child,
                                              );
                                            },
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6), // reduced padding
                                      decoration: BoxDecoration(
                                        color: isSelected ? lightBlue : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6), // reduced radius
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            dashboardIcons[option] ?? Icons.dashboard_rounded,
                                            color: isSelected ? primaryBlue : textSecondary,
                                            size: 12, // reduced icon size
                                          ),
                                          const SizedBox(width: 4), // reduced spacing
                                          Expanded(
                                            child: Text(
                                              option,
                                              style: TextStyle(
                                                color: isSelected ? primaryBlue : textPrimary,
                                                fontSize: 9, // reduced font size
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_rounded,
                                              color: primaryBlue,
                                              size: 12, // reduced icon size
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(10), // reduced padding
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(10), // reduced radius
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.15), // reduced opacity
            blurRadius: 8, // reduced blur
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8), // reduced padding
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08), // reduced opacity
              borderRadius: BorderRadius.circular(6), // reduced radius
            ),
            child: Image.asset(
              'assets/images/manage.png',
              width: 40, // reduced size
              height: 40, // reduced size
            ),
          ),
          const SizedBox(height: 8), // reduced spacing
          const Text(
            "Welcome to your workspace",
            style: TextStyle(
              fontSize: 12, // reduced font size
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4), // reduced spacing
          const Text(
            "Explore charts, performance metrics, and manage your projects efficiently",
            style: TextStyle(
              fontSize: 8, // reduced font size
              color: Colors.white70,
              height: 1.2, // reduced line height
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedToMeSection() {
    final tasks = [
      {'project': 'Project Alpha', 'task': 'Fix login issue', 'priority': 'High'},
      {'project': 'Project Beta', 'task': 'Update project timeline', 'priority': 'Medium'},
      {'project': 'Project Gamma', 'task': 'Resolve API integration bug', 'priority': 'Low'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Assigned to Me',
              style: TextStyle(
                fontSize: 12, // reduced font size
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: accentBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 9, // reduced font size
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6), // reduced spacing
        ...tasks.map((task) => _buildModernTaskCard(
              task['project']!,
              task['task']!,
              task['priority']!,
            )),
      ],
    );
  }

  Widget _buildModernTaskCard(String project, String task, String priority) {
    Color priorityColor = priority == 'High'
        ? const Color(0xFFEF4444)
        : priority == 'Medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 6), // reduced spacing
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8), // reduced radius
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.08)
                : Colors.black.withOpacity(0.01),
            blurRadius: 4, // reduced blur
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8), // reduced radius
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(8), // reduced padding
            child: Row(
              children: [
                Container(
                  width: 2, // reduced width
                  height: 24, // reduced height
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(1), // reduced radius
                  ),
                ),
                const SizedBox(width: 6), // reduced spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project,
                        style: TextStyle(
                          fontSize: 9, // reduced font size
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2), // reduced spacing
                      Text(
                        task,
                        style: TextStyle(
                          fontSize: 8, // reduced font size
                          color: textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // reduced padding
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8), // reduced radius
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      fontSize: 8, // reduced font size
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6), // reduced spacing
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textSecondary,
                  size: 10, // reduced icon size
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityStreamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activity Stream',
              style: TextStyle(
                fontSize: 12, // reduced font size
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(8), // reduced radius
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: primaryBlue,
                  size: 14, // reduced icon size
                ),
                padding: const EdgeInsets.all(4), // reduced padding
                constraints: const BoxConstraints(),
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 6), // reduced spacing
        Center(
          child: Container(
            padding: const EdgeInsets.all(12), // reduced padding
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8), // reduced radius
              border: Border.all(
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFF1F5F9),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // reduced padding
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(20), // reduced radius
                  ),
                  child: const Icon(
                    Icons.inbox_rounded,
                    color: primaryBlue,
                    size: 14, // reduced icon size
                  ),
                ),
                const SizedBox(height: 6), // reduced spacing
                Text(
                  'All caught up!',
                  style: TextStyle(
                    fontSize: 9, // reduced font size
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2), // reduced spacing
                Text(
                  'No new activity to show right now.',
                  style: TextStyle(
                    fontSize: 8, // reduced font size
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(10), // reduced padding
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10), // reduced radius
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // reduced padding
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6), // reduced radius
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFF59E0B),
                  size: 12, // reduced icon size
                ),
              ),
              const SizedBox(width: 6), // reduced spacing
              Expanded(
                child: Text(
                  'Help us improve',
                  style: TextStyle(
                    fontSize: 10, // reduced font size
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // reduced spacing
          Text(
            'We\'re continuously enhancing our mobile dashboard experience. Your feedback helps us prioritize the features that matter most to you.',
            style: TextStyle(
              fontSize: 8, // reduced font size
              color: textSecondary,
              height: 1.2, // reduced line height
            ),
          ),
          const SizedBox(height: 8), // reduced spacing
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8), // reduced padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6), // reduced radius
                ),
                elevation: 0,
              ),
              child: const Text(
                'Send Feedback',
                style: TextStyle(
                  fontSize: 9, // reduced font size
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}