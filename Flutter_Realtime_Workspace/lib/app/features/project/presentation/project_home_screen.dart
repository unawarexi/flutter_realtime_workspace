import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/app/features/project/presentation/create_project_screen.dart';
import 'package:flutter_realtime_workspace/app/features/project/presentation/project_timeline_screen.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';

class ProjectHome extends StatefulWidget {
  const ProjectHome({super.key});

  @override
  State<ProjectHome> createState() => _ProjectHomeState();
}

class _ProjectHomeState extends State<ProjectHome>
    with TickerProviderStateMixin {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _searchAnimation;

  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Recent', 'Starred', 'Archived'];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _searchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(isDarkMode),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(isDarkMode),
                      const SizedBox(height: 32),
                      _buildQuickStats(isDarkMode),
                      const SizedBox(height: 32),
                      _buildFilterSection(isDarkMode),
                      const SizedBox(height: 24),
                      _buildProjectsSection('Recently Viewed', isDarkMode),
                      const SizedBox(height: 32),
                      _buildProjectsSection('All Projects', isDarkMode),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildModernFAB(isDarkMode),
    );
  }

  Widget _buildModernAppBar(bool isDarkMode) {
    return SliverAppBar(
      automaticallyImplyLeading: false, 
      expandedHeight: 100, // reduced height
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
        
          decoration: BoxDecoration(
            color: isDarkMode 
                ? TColors.cardColorDark.withOpacity(0.95)
                : TColors.cardColorLight.withOpacity(0.95),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16), // reduced radius
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(
              color: isDarkMode 
                  ? TColors.borderDark
                  : TColors.borderLight,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top:40, bottom: 0), // reduced padding
            child: Row(
              children: [
                _buildUserAvatar(isDarkMode),
                const SizedBox(width: 8), // reduced spacing
                Expanded(
                  child: _isSearching
                      ? _buildSearchField(isDarkMode)
                      : _buildAppBarTitle(isDarkMode),
                ),
                _buildAppBarActions(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: TColors.buttonPrimaryLight,
          width: 1, // thinner border
        ),
        boxShadow: [
          BoxShadow(
            color: TColors.buttonPrimaryLight.withOpacity(0.15),
            blurRadius: 4, // reduced blur
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const CircleAvatar(
        radius: 18, // reduced size
        backgroundColor: TColors.buttonPrimary,
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 16, // reduced icon size
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Good Morning!',
          style: TextStyle(
            fontSize: 10, // reduced font size
            color: isDarkMode ? Colors.white70 : TColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: 1), // reduced spacing
        Text(
          'Your Workspace',
          style: TextStyle(
            fontSize: 14, // reduced font size
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : TColors.cardColorDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(bool isDarkMode) {
    return FadeTransition(
      opacity: _searchAnimation,
      child: Container(
        height: 32, // reduced height
        decoration: BoxDecoration(
          color: isDarkMode 
              ? TColors.borderDark.withOpacity(0.8)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16), // reduced radius
          border: Border.all(
            color: TColors.buttonPrimaryLight.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(
            color: isDarkMode ? Colors.white : TColors.cardColorDark,
            fontSize: 12, // reduced font size
          ),
          decoration: InputDecoration(
            hintText: 'Search projects...',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white54 : TColors.textTertiaryLight,
              fontSize: 12, // reduced font size
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: TColors.buttonPrimaryLight,
              size: 16, // reduced icon size
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8, // reduced padding
              vertical: 8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarActions(bool isDarkMode) {
    return Row(
      children: [
        _buildActionButton(
          icon: _isSearching ? Icons.close : Icons.search,
          onPressed: _toggleSearch,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(width: 4), // reduced spacing
        _buildActionButton(
          icon: Icons.notifications_none,
          onPressed: () {},
          isDarkMode: isDarkMode,
          badgeCount: 3,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDarkMode,
    int? badgeCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode 
            ? TColors.borderDark.withOpacity(0.8)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6), // even smaller radius
        border: Border.all(
          color: isDarkMode 
              ? TColors.textSecondaryDark
              : TColors.borderLight,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(
              icon,
              color: isDarkMode ? Colors.white : TColors.cardColorDark,
              size: 12, // much smaller icon size
            ),
            onPressed: onPressed,
            padding: const EdgeInsets.all(2), // even less padding
            constraints: const BoxConstraints(minWidth: 22, minHeight: 22), // much smaller button
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(0.5),
                decoration: const BoxDecoration(
                  color: TColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 8,
                  minHeight: 8,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 6, // even smaller font size
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12), // reduced padding
      decoration: BoxDecoration(
        color: TColors.buttonPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12), // reduced radius
        border: Border.all(
          color: TColors.buttonPrimaryLight.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8), // reduced padding
            decoration: BoxDecoration(
              color: TColors.buttonPrimary,
              borderRadius: BorderRadius.circular(8), // reduced radius
            ),
            child: const Icon(
              Icons.rocket_launch,
              color: Colors.white,
              size: 16, // reduced icon size
            ),
          ),
          const SizedBox(width: 8), // reduced spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to build something amazing?',
                  style: TextStyle(
                    fontSize: 12, // reduced font size
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : TColors.cardColorDark,
                  ),
                ),
                const SizedBox(height: 2), // reduced spacing
                Text(
                  'Start a new project or continue where you left off',
                  style: TextStyle(
                    fontSize: 10, // reduced font size
                    color: isDarkMode ? Colors.white70 : TColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Active Projects',
            value: '12',
            icon: Icons.folder_open,
            color: const Color(0xFF3B82F6),
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 8), // reduced spacing
        Expanded(
          child: _buildStatCard(
            title: 'Completed',
            value: '8',
            icon: Icons.check_circle,
            color: const Color(0xFF10B981),
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 8), // reduced spacing
        Expanded(
          child: _buildStatCard(
            title: 'Team Members',
            value: '24',
            icon: Icons.people,
            color: const Color(0xFF8B5CF6),
            isDarkMode: isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(10), // reduced padding
      decoration: BoxDecoration(
        color: isDarkMode 
            ? TColors.cardColorDark.withOpacity(0.8)
            : TColors.cardColorLight,
        borderRadius: BorderRadius.circular(10), // reduced radius
        border: Border.all(
          color: isDarkMode 
              ? TColors.borderDark
              : TColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.08)
                : Colors.grey.withOpacity(0.03),
            blurRadius: 5, // reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 16, // reduced icon size
          ),
          const SizedBox(height: 6), // reduced spacing
          Text(
            value,
            style: TextStyle(
              fontSize: 14, // reduced font size
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : TColors.cardColorDark,
            ),
          ),
          const SizedBox(height: 2), // reduced spacing
          Text(
            title,
            style: TextStyle(
              fontSize: 9, // reduced font size
              color: isDarkMode ? Colors.white70 : TColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isDarkMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filterOptions.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6), // reduced spacing
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // reduced padding
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF1E40AF)
                      : isDarkMode 
                          ? const Color(0xFF1E293B).withOpacity(0.8)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(8), // reduced radius
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF1E40AF)
                        : isDarkMode 
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFF1E40AF).withOpacity(0.2),
                      blurRadius: 4, // reduced blur
                      offset: const Offset(0, 1),
                    ),
                  ] : null,
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 10, // reduced font size
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? Colors.white
                        : isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProjectsSection(String title, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14, // reduced font size
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : TColors.cardColorDark,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.arrow_forward,
                size: 12, // reduced icon size
                color: Color(0xFF3B82F6),
              ),
              label: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w500,
                  fontSize: 10, // reduced font size
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // reduced spacing
        _buildProjectList(isDarkMode),
      ],
    );
  }

  Widget _buildProjectList(bool isDarkMode) {
    final projects = [
      {
        'name': 'Project Alpha',
        'date': '14 Sep 2024',
        'status': 'In Progress',
        'members': 5,
        'progress': 0.75,
      },
      {
        'name': 'Project Beta',
        'date': '12 Sep 2024',
        'status': 'Review',
        'members': 3,
        'progress': 0.90,
      },
      {
        'name': 'Project Gamma',
        'date': '10 Sep 2024',
        'status': 'Planning',
        'members': 8,
        'progress': 0.25,
      },
    ];

    return Column(
      children: projects.map((project) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8), // reduced spacing
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectTimelineScreen(
                    projectName: project['name']! as String,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10), // reduced padding
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? TColors.cardColorDark.withOpacity(0.8)
                    : TColors.cardColorLight,
                borderRadius: BorderRadius.circular(10), // reduced radius
                border: Border.all(
                  color: isDarkMode 
                      ? TColors.borderDark
                      : TColors.borderLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode 
                        ? Colors.black.withOpacity(0.08)
                        : Colors.grey.withOpacity(0.03),
                    blurRadius: 5, // reduced blur
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6), // reduced padding
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E40AF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6), // reduced radius
                        ),
                        child: const Icon(
                          Icons.folder_open,
                          color: Color(0xFF1E40AF),
                          size: 14, // reduced icon size
                        ),
                      ),
                      const SizedBox(width: 8), // reduced spacing
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project['name']! as String,
                              style: TextStyle(
                                fontSize: 12, // reduced font size
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : TColors.cardColorDark,
                              ),
                            ),
                            const SizedBox(height: 2), // reduced spacing
                            Text(
                              'Last modified: ${project['date']}',
                              style: TextStyle(
                                fontSize: 9, // reduced font size
                                color: isDarkMode ? Colors.white60 : TColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(project['status']! as String, isDarkMode),
                    ],
                  ),
                  const SizedBox(height: 6), // reduced spacing
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 12, // reduced icon size
                        color: isDarkMode ? Colors.white60 : TColors.textTertiaryLight,
                      ),
                      const SizedBox(width: 2), // reduced spacing
                      Text(
                        '${project['members']} members',
                        style: TextStyle(
                          fontSize: 9, // reduced font size
                          color: isDarkMode ? Colors.white60 : TColors.textTertiaryLight,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${((project['progress']! as double) * 100).toInt()}% complete',
                        style: TextStyle(
                          fontSize: 9, // reduced font size
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white70 : TColors.cardColorDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4), // reduced spacing
                  LinearProgressIndicator(
                    value: project['progress']! as double,
                    backgroundColor: isDarkMode 
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    minHeight: 2, // reduced height
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String status, bool isDarkMode) {
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'in progress':
        badgeColor = const Color(0xFF3B82F6);
        break;
      case 'review':
        badgeColor = const Color(0xFFF59E0B);
        break;
      case 'planning':
        badgeColor = const Color(0xFF8B5CF6);
        break;
      default:
        badgeColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // reduced padding
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4), // reduced radius
        border: Border.all(
          color: badgeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 8, // reduced font size
          fontWeight: FontWeight.w500,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildModernFAB(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10), // reduced radius
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withOpacity(0.18),
            blurRadius: 10, // reduced blur
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateProjectScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // reduced radius
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 18, // reduced icon size
        ),
      ),
    );
  }
}