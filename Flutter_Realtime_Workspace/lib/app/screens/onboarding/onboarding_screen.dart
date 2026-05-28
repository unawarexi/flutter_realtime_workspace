import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/animations/screen_animations.dart';
import 'package:flutter_realtime_workspace/core/services/storage_service.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:go_router/go_router.dart';

import 'widgets/onboarding_bottom_bar.dart';
import 'widgets/onboarding_page_content.dart';
import 'widgets/onboarding_shape_overlay.dart';
import 'widgets/onboarding_top_bar.dart';
import 'widgets/onboarding_video_bg.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAutoSliding = true;

  late final SlideUpFadeAnim _entryAnim;

  static const List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.people_alt_outlined,
      'image': 'assets/images/collab.png',
      'title': 'Real-time Collaboration',
      'subtitle': 'Work Together, Achieve More',
      'description': 'Connect with your team instantly and collaborate on projects in real-time. Share ideas, files, and feedback seamlessly.',
      'color': const Color(0xFF1E40AF),
    },
    {
      'icon': Icons.task_alt_outlined,
      'image': 'assets/images/manage.png',
      'title': 'Smart Task Management',
      'subtitle': 'Organize • Prioritize • Execute',
      'description': 'Streamline your workflow with intelligent task organization, priority setting, and progress tracking tools.',
      'color': const Color(0xFF4F46E5),
    },
    {
      'icon': Icons.forum_outlined,
      'image': 'assets/images/communicate.png',
      'title': 'Seamless Communication',
      'subtitle': 'Stay Connected, Stay Productive',
      'description': 'Integrated messaging, video calls, and notifications keep your team connected and informed at all times.',
      'color': const Color(0xFF0891B2),
    },
    {
      'icon': Icons.timeline_outlined,
      'image': 'assets/images/deadline.png',
      'title': 'Project Timeline Tracking',
      'subtitle': 'Visualize Progress in Real-time',
      'description': 'Monitor project milestones, deadlines, and deliverables with interactive timelines and progress indicators.',
      'color': const Color(0xFF059669),
    },
    {
      'icon': Icons.analytics_outlined,
      'image': 'assets/images/stats.png',
      'title': 'Performance Analytics',
      'subtitle': 'Data-Driven Productivity',
      'description':
          'Get insights into team performance, project efficiency, and productivity metrics to optimize your workspace.',
      'color': const Color(0xFF0891B2),
    },
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _entryAnim = SlideUpFadeAnim(vsync: this)..forward();
    _startAutoSlider();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryAnim.dispose();
    super.dispose();
  }

  // ── Auto-slider ────────────────────────────────────────────────────────────

  void _startAutoSlider() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isAutoSliding || !mounted) return;
      final next = (_currentPage + 1) % _pages.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
      _startAutoSlider();
    });
  }

  void _stopAutoSlider() => setState(() => _isAutoSliding = false);

  // ── Navigation helpers ─────────────────────────────────────────────────────

  void _onPageChanged(int index) => setState(() => _currentPage = index);

  void _goNext() {
    _stopAutoSlider();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    } else {
      LocalStorageService.setOnboardingComplete();
      context.go('/signup');
    }
  }

  void _goPrev() {
    _stopAutoSlider();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _onSkip() {
    _stopAutoSlider();
    LocalStorageService.setOnboardingComplete();
    context.go('/signup');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final accentColor = _pages[_currentPage]['color'] as Color;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Layer 1 — video background (animated gradient fallback)
          Positioned.fill(
            child: IgnorePointer(
              child: OnboardingVideoBg(
                isDarkMode: isDarkMode,
                accentColor: accentColor,
              ),
            ),
          ),

          // Layer 2 — theme overlay + decorative shapes
          OnboardingShapeOverlay(
            isDarkMode: isDarkMode,
            accentColor: accentColor,
          ),

          // Layer 3 — content
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _entryAnim.fade,
              child: SlideTransition(
                position: _entryAnim.slide,
                child: Column(
                  children: [
                    OnboardingTopBar(
                      isDarkMode: isDarkMode,
                      onSkip: _onSkip,
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: _onPageChanged,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) => Center(
                          child: OnboardingPageContent(
                            key: ValueKey(index),
                            data: _pages[index],
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ),
                    ),
                    OnboardingBottomBar(
                      currentPage: _currentPage,
                      pageCount: _pages.length,
                      pageController: _pageController,
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                      onNext: _goNext,
                      onPrev: _goPrev,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

