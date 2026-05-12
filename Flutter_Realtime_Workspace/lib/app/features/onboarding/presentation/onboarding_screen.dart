import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isAutoSliding = true;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> onboardingData = [
    {
      'icon': Icons.people_alt_outlined,
      'title': 'Real-time Collaboration',
      'subtitle': 'Work Together, Achieve More',
      'description': 'Connect with your team instantly and collaborate on projects in real-time. Share ideas, files, and feedback seamlessly.',
      'color': const Color(0xFF1E40AF),
    },
    {
      'icon': Icons.task_alt_outlined,
      'title': 'Smart Task Management',
      'subtitle': 'Organize • Prioritize • Execute',
      'description': 'Streamline your workflow with intelligent task organization, priority setting, and progress tracking tools.',
      'color': const Color.fromARGB(255, 34, 37, 174),
    },
    {
      'icon': Icons.forum_outlined,
      'title': 'Seamless Communication',
      'subtitle': 'Stay Connected, Stay Productive',
      'description': 'Integrated messaging, video calls, and notifications keep your team connected and informed at all times.',
      'color': const Color(0xFF1E3A8A),
    },
    {
      'icon': Icons.timeline_outlined,
      'title': 'Project Timeline Tracking',
      'subtitle': 'Visualize Progress in Real-time',
      'description': 'Monitor project milestones, deadlines, and deliverables with interactive timelines and progress indicators.',
      'color': const Color(0xFF164E63),
    },
    {
      'icon': Icons.analytics_outlined,
      'title': 'Performance Analytics',
      'subtitle': 'Data-Driven Productivity',
      'description': 'Get insights into team performance, project efficiency, and productivity metrics to optimize your workspace.',
      'color': const Color(0xFF0C4A6E),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAutoSlider();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  void _startAutoSlider() {
    Future.delayed(const Duration(seconds: 4), () {
      if (_isAutoSliding && mounted) {
        if (_currentPage < onboardingData.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _controller.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
        _startAutoSlider();
      }
    });
  }

  void _stopAutoSlider() {
    setState(() {
      _isAutoSliding = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFAFBFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildTopSection(isDarkMode, size),
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: onboardingData.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      _scaleController.reset();
                      _scaleController.forward();
                    },
                    itemBuilder: (context, index) => OnboardingContent(
                      data: onboardingData[index],
                      isDarkMode: isDarkMode,
                      animation: _scaleAnimation,
                    ),
                  ),
                ),
              ),
              _buildBottomSection(isDarkMode, size),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(bool isDarkMode, Size size) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode 
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Workspace Pro',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              _stopAutoSlider();
              Navigator.pushReplacementNamed(context, '/signup');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: isDarkMode 
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDarkMode 
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              'Skip',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isDarkMode, Size size) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Page Indicators
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 32 : 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF1E40AF)
                        : isDarkMode 
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          
          // Progress Text
          Text(
            '${_currentPage + 1} of ${onboardingData.length}',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white60 : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: _buildActionButton(
                    text: 'Previous',
                    isPrimary: false,
                    isDarkMode: isDarkMode,
                    onPressed: () {
                      _stopAutoSlider();
                      _controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 16),
              Expanded(
                flex: _currentPage == 0 ? 1 : 1,
                child: _buildActionButton(
                  text: _currentPage == onboardingData.length - 1
                      ? 'Get Started'
                      : 'Continue',
                  isPrimary: true,
                  isDarkMode: isDarkMode,
                  onPressed: () {
                    _stopAutoSlider();
                    if (_currentPage < onboardingData.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubic,
                      );
                    } else {
                      Navigator.pushReplacementNamed(context, '/signup');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required bool isPrimary,
    required bool isDarkMode,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: const Color(0xFF1E40AF).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary 
              ? const Color(0xFF1E40AF)
              : isDarkMode 
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : Colors.white,
          foregroundColor: isPrimary 
              ? Colors.white
              : isDarkMode ? Colors.white70 : const Color(0xFF64748B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary ? BorderSide.none : BorderSide(
              color: isDarkMode 
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isPrimary 
                    ? Colors.white
                    : isDarkMode ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            if (isPrimary) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward,
                size: 18,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDarkMode;
  final Animation<double> animation;

  const OnboardingContent({
    required this.data,
    required this.isDarkMode,
    required this.animation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: (data['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: (data['color'] as Color).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    data['icon'] as IconData,
                    size: 48,
                    color: data['color'] as Color,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Subtitle
                Text(
                  data['subtitle'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: data['color'] as Color,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Title
                Text(
                  data['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Description
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    data['description'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: isDarkMode 
                          ? Colors.white.withOpacity(0.7)
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Feature Cards
                _buildFeatureCards(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCards() {
    final features = _getFeatures();
    
    return Row(
      children: features.map((feature) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF1E293B).withOpacity(0.6)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode 
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  feature['icon'] as IconData,
                  size: 20,
                  color: data['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  feature['text'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getFeatures() {
    switch (data['title']) {
      case 'Real-time Collaboration':
        return [
          {'icon': Icons.speed, 'text': 'Instant Sync'},
          {'icon': Icons.security, 'text': 'Secure'},
          {'icon': Icons.cloud_done, 'text': 'Cloud Based'},
        ];
      case 'Smart Task Management':
        return [
          {'icon': Icons.auto_awesome, 'text': 'AI Powered'},
          {'icon': Icons.track_changes, 'text': 'Progress Track'},
          {'icon': Icons.notifications_active, 'text': 'Smart Alerts'},
        ];
      case 'Seamless Communication':
        return [
          {'icon': Icons.chat_bubble_outline, 'text': 'Live Chat'},
          {'icon': Icons.videocam, 'text': 'Video Calls'},
          {'icon': Icons.share, 'text': 'File Share'},
        ];
      case 'Project Timeline Tracking':
        return [   
          {'icon': Icons.calendar_today, 'text': 'Milestones'},
          {'icon': Icons.timeline, 'text': 'Visual Timeline'},
          {'icon': Icons.insights, 'text': 'Insights'},
        ];
      case 'Performance Analytics':
        return [
          {'icon': Icons.bar_chart, 'text': 'Reports'},
          {'icon': Icons.trending_up, 'text': 'Metrics'},
          {'icon': Icons.psychology, 'text': 'AI Insights'},
        ];
      default:
        return [
          {'icon': Icons.check, 'text': 'Feature 1'},
          {'icon': Icons.check, 'text': 'Feature 2'},
          {'icon': Icons.check, 'text': 'Feature 3'},
        ];
    }
  }
}