import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/app/screens/dashboard.dart';
import 'package:flutter_realtime_workspace/app/screens/home.dart';
import 'package:flutter_realtime_workspace/app/screens/issues.dart';
import 'package:flutter_realtime_workspace/app/screens/notifications.dart';
import 'package:flutter_realtime_workspace/app/screens/project.dart';


class BottomNavigationBarWidget extends StatefulWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  _BottomNavigationBarWidgetState createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _hoveredIndex = -1;

  late AnimationController _animationController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;

  final List<Widget> _screens = [
    const Home(),
    const ProjectHome(),
    const IssuesScreen(),
    const DashboardScreen(),
    const NotificationScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
      color: const Color(0xFF1E40AF),
    ),
    NavigationItem(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder_rounded,
      label: 'Projects',
      color: const Color(0xFF1E3A8A),
    ),
    NavigationItem(
      icon: Icons.bug_report_outlined,
      selectedIcon: Icons.bug_report_rounded,
      label: 'Issues',
      color: const Color(0xFF1E3A8A),
    ),
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      color: const Color(0xFF164E63),
    ),
    NavigationItem(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
      label: 'Notifications',
      color: const Color(0xFF0C4A6E),
      hasNotification: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Individual item animations
    _itemControllers = List.generate(
        5,
        (index) => AnimationController(
              duration: Duration(milliseconds: 200 + (index * 50)),
              vsync: this,
            ));

    _itemAnimations = _itemControllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
            ))
        .toList();

    _animationController.forward();

    // Stagger item animations
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        _itemControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rippleController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      // Haptic feedback
      HapticFeedback.lightImpact();

      setState(() {
        _selectedIndex = index;
      });

      // Trigger ripple animation
      _rippleController.reset();
      _rippleController.forward();

      // Scale animation for selected item
      _itemControllers[index].reset();
      _itemControllers[index].forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFAFBFC),
      body: _screens[_selectedIndex],
      bottomNavigationBar: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _fadeAnimation.value) * 100),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 80, // Increased height
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12), // Adjusted padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_navigationItems.length, (index) {
                        return _buildNavigationItem(index, isDarkMode);
                      }),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationItem(int index, bool isDarkMode) {
    final item = _navigationItems[index];
    final isSelected = _selectedIndex == index;
    final isHovered = _hoveredIndex == index;

    return AnimatedBuilder(
      animation: _itemAnimations[index],
      builder: (context, child) {
        return Transform.scale(
            scale: _itemAnimations[index].value,
            child: MouseRegion(
              onEnter: (_) {
                setState(() {
                  _hoveredIndex = index;
                });
              },
              onExit: (_) {
                setState(() {
                  _hoveredIndex = -1;
                });
              },
              child: GestureDetector(
                onTap: () => _onItemTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  width: isSelected ? 70 : 52,
                  height: 56, // Increased height to accommodate content
                  constraints: BoxConstraints(
                    maxWidth: isSelected ? 70 : 52,
                    maxHeight: 56,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        width: isSelected ? 68 : (isHovered ? 60 : 56),
                        height: isSelected ? 68 : (isHovered ? 60 : 56),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? item.color.withOpacity(0.12)
                              : (isHovered
                                  ? (isDarkMode
                                      ? const Color(0xFF334155).withOpacity(0.5)
                                      : const Color(0xFFF1F5F9))
                                  : Colors.transparent),
                          borderRadius:
                              BorderRadius.circular(isSelected ? 10 : 16),
                          border: isSelected
                              ? Border.all(
                                  color: item.color.withOpacity(0.3),
                                  width: 1.5,
                                )
                              : null,
                        ),
                      ),

                      // Icon and label
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: isSelected ? 32 : 28,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ripple effect
                                if (isSelected)
                                  AnimatedBuilder(
                                    animation: _rippleController,
                                    builder: (context, child) {
                                      return Container(
                                        width: 32 *
                                            (1 + _rippleController.value * 0.5),
                                        height: 32 *
                                            (1 + _rippleController.value * 0.5),
                                        decoration: BoxDecoration(
                                          color: item.color.withOpacity(0.2 *
                                              (1 - _rippleController.value)),
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    },
                                  ),

                                // Icon
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    isSelected ? item.selectedIcon : item.icon,
                                    key: ValueKey('${index}_$isSelected'),
                                    color: isSelected
                                        ? item.color
                                        : (isDarkMode
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B)),
                                    size: isSelected ? 26 : 24,
                                  ),
                                ),

                                // Notification badge
                                if (item.hasNotification && !isSelected)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          if (isSelected) const SizedBox(height: 2),

                          // Label
                          if (isSelected)
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 14,
                                maxWidth: 64,
                              ),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isSelected ? 1.0 : 0.0,
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: item.color,
                                    letterSpacing: 0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ));
      },
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color color;
  final bool hasNotification;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.color,
    this.hasNotification = false,
  });
}
