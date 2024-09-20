import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/screens/dashboard.dart';
import 'package:flutter_realtime_workspace/screens/issues.dart';
import 'package:flutter_realtime_workspace/screens/notifications.dart';
import 'package:flutter_realtime_workspace/screens/project.dart';
import '../../screens/home.dart';

class BottomNavigationBarWidget extends StatefulWidget {
  const BottomNavigationBarWidget({Key? key}) : super(key: key);

  @override
  _BottomNavigationBarWidgetState createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _hoveredIndex = -1; // Keep track of the hovered icon

  final List<Widget> _screens = [
    const Home(),
    const ProjectHome(),
    const IssuesScreen(),
    const DashboardScreen(),
    const NotificationScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final isSelected = _selectedIndex == index;
              final isHovered = _hoveredIndex == index;

              return MouseRegion(
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
                    width: isHovered || isSelected ? 60 : 50,
                    height: isHovered || isSelected ? 60 : 50,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHovered || isSelected
                            ? Colors.blue
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isHovered || isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _getIcon(index),
                      color: isSelected ? Colors.blue : Colors.grey,
                      size: isHovered || isSelected ? 30 : 25,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.folder;
      case 2:
        return Icons.bug_report;
      case 3:
        return Icons.dashboard;
      case 4:
        return Icons.notifications;
      default:
        return Icons.circle;
    }
  }
}
