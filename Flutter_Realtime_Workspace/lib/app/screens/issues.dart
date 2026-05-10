import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen>
    with TickerProviderStateMixin {
  bool _isDropdownOpen = false;
  late AnimationController _animationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String selectedCategory = 'My Open Issues';

  final List<Map<String, dynamic>> _recentFilters = [
    {'title': 'My Open Work Items', 'icon': Iconsax.task_square, 'count': 12},
    {'title': 'Viewed Recently', 'icon': Iconsax.eye, 'count': 8},
  ];

  final List<Map<String, dynamic>> _defaultFilters = [
    {'title': 'My Open Work Items', 'icon': Iconsax.task_square, 'count': 12},
    {'title': 'Reported by Me', 'icon': Iconsax.profile_2user, 'count': 5},
    {'title': 'Viewed Recently', 'icon': Iconsax.eye, 'count': 8},
    {'title': 'All Work Items', 'icon': Iconsax.document, 'count': 45},
    {'title': 'Open Work Items', 'icon': Iconsax.box_1, 'count': 23},
    {'title': 'Created Recently', 'icon': Iconsax.add_square, 'count': 3},
    {'title': 'Resolved Recently', 'icon': Iconsax.tick_square, 'count': 7},
    {'title': 'Updated Recently', 'icon': Iconsax.refresh_square_2, 'count': 15},
    {'title': 'Done Work Items', 'icon': Iconsax.tick_circle, 'count': 28},
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.elasticOut,
    ));

    _contentAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
      if (_isDropdownOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _navigateToPage(String category) {
    _toggleDropdown();
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PlaceholderScreen(category: category),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    
    return 
      Scaffold(
        backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
        appBar: _buildModernAppBar(context, isDarkMode),
        body: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildBody(context, isDarkMode),
              ),
            );
          },
        ),
      );

  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context, bool isDarkMode) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.task_square,
              color: Color(0xFF1E3A8A),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Issues',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.search_normal,
                color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                size: 20,
              ),
            ),
            onPressed: () {},
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.add,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const CreateIssueScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        const SizedBox(height: 24,),
        _buildFilterHeader(isDarkMode),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildDropdownSection(isDarkMode),
                if (!_isDropdownOpen) _buildMainContent(isDarkMode),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.filter,
                size: 20,
                color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1E3A8A).withOpacity(0.2),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.add_circle,
                  size: 16,
                  color: Color(0xFF1E3A8A),
                ),
                SizedBox(width: 6),
                Text(
                  'Create',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDropdownHeader(isDarkMode),
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _slideAnimation,
                axisAlignment: -1.0,
                child: _buildDropdownContent(isDarkMode),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownHeader(bool isDarkMode) {
    return InkWell(
      onTap: _toggleDropdown,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.task_square,
                color: Color(0xFF1E3A8A),
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCategory,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 8,
                      color: isDarkMode ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _isDropdownOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFF1E3A8A).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Iconsax.arrow_down_1,
                  color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                  size: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownContent(bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed divider
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFF1E293B).withOpacity(0.1),
          ),
        ),
        
        // Scrollable content
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5, // 50% of screen height
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterSection('RECENT FILTERS', _recentFilters, isDarkMode),
                const SizedBox(height: 24),
                _buildFilterSection('DEFAULT FILTERS', _defaultFilters, isDarkMode),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(String title, List<Map<String, dynamic>> filters, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white60 : const Color(0xFF64748B),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...filters.map((filter) => _buildFilterOption(filter, isDarkMode)),
      ],
    );
  }

  Widget _buildFilterOption(Map<String, dynamic> filter, bool isDarkMode) {
    final isSelected = selectedCategory == filter['title'];
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedCategory = filter['title'];
          });
          _navigateToPage(filter['title']);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF1E3A8A).withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected 
                ? Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2))
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF1E3A8A)
                      : (isDarkMode 
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFF1E3A8A).withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  filter['icon'],
                  size: 10,
                  color: isSelected 
                      ? Colors.white
                      : (isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  filter['title'],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? (isDarkMode ? Colors.white : const Color(0xFF1E293B))
                        : (isDarkMode ? Colors.white60 : const Color(0xFF1E293B)),
                  ),
                ),
              ),
              if (filter['count'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFF1E3A8A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${filter['count']}',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Iconsax.star,
                size: 10,
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFF64748B).withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 12), // reduced margin
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(50), // reduced padding
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12), // reduced radius
              boxShadow: [
                BoxShadow(
                  color: isDarkMode 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 8, // reduced blur
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // reduced padding
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10), // reduced radius
                  ),
                  child: const Icon(
                    Iconsax.task_square,
                    size: 32, // reduced icon size
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12), // reduced spacing
                Text(
                  'No work assigned... Nice!',
                  style: TextStyle(
                    fontSize: 14, // reduced font size
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6), // reduced spacing
                Text(
                  "When you're assigned new issues,\nthey'll appear here",
                  style: TextStyle(
                    fontSize: 10, // reduced font size
                    color: isDarkMode ? Colors.white60 : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16), // reduced spacing
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const CreateIssueScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // reduced padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // reduced radius
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.add_circle, size: 14), // reduced icon size
                      SizedBox(width: 4), // reduced spacing
                      Text(
                        'Create Issue',
                        style: TextStyle(
                          fontSize: 10, // reduced font size
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Create Issue Screen
class CreateIssueScreen extends StatelessWidget {
  const CreateIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A0E27) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: isDarkMode
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.1)
                  : const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.arrow_left,
              color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create New Issue',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Iconsax.document_text,
                  size: 48,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Create Issue Form',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Form implementation coming soon',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced Placeholder Screen
class PlaceholderScreen extends StatelessWidget {
  final String category;
  const PlaceholderScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A0E27) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: isDarkMode
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.1)
                  : const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.arrow_left,
              color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          category,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Iconsax.folder_open,
                  size: 48,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No data found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No items match this filter yet',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}