import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realtime_workspace/core/constants/image_strings.dart';
import 'dart:math' as math;

import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';

class TeamSpotSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const TeamSpotSplashScreen({super.key, required this.nextScreen});

  @override
  State<TeamSpotSplashScreen> createState() => _TeamSpotSplashScreenState();
}

class _TeamSpotSplashScreenState extends State<TeamSpotSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController;
  late AnimationController _logoController;
  late Animation<double> _radarAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Hide system UI for full immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Radar animation controller
    _radarController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Radar wave animation
    _radarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _radarController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Logo fade animation
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    // Start logo animation
    _logoController.forward();

    // Navigate to next screen after delay
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 3000));

    // Restore system UI before navigation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              widget.nextScreen,
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  // Theme colors based on dark/light mode
  Map<String, Color> _getThemeColors(bool isDarkMode) {
    if (isDarkMode) {
      return {
        'background1': const Color(0xFF0A0E1A),
        'background2': const Color(0xFF0D1423),
        'background3': const Color(0xFF0A0E1A),
        'primary': const Color(0xFFE2E8F0),
        'logoBackground': const Color(0xFFE2E8F0),
        'logoIcon': const Color(0xFF0A0E1A),
      };
    } else {
      return {
        'background1': const Color(0xFFF8FAFC),
        'background2': const Color(0xFFE2E8F0),
        'background3': const Color(0xFFF1F5F9),
        'primary': const Color(0xFF475569),
        'logoBackground': const Color(0xFF475569),
        'logoIcon': const Color(0xFFF8FAFC),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final themeColors = _getThemeColors(isDarkMode);

    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              themeColors['background1']!,
              themeColors['background2']!,
              themeColors['background3']!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated radar rings
            AnimatedBuilder(
              animation: _radarAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Multiple radar rings with different delays
                    for (int i = 0; i < 3; i++)
                      Transform.scale(
                        scale: 0.5 +
                            (_radarAnimation.value + i * 0.33) % 1.0 * 1.5,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: themeColors['primary']!.withOpacity(
                                (1.0 -
                                        (_radarAnimation.value + i * 0.33) %
                                            1.0) *
                                    (isDarkMode ? 0.3 : 0.4),
                              ),
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            // Pulse ring around logo
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeColors['primary']!
                            .withOpacity(isDarkMode ? 0.2 : 0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Logo with fade and scale animation
            AnimatedBuilder(
              animation:
                  Listenable.merge([_logoFadeAnimation, _logoScaleAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScaleAnimation.value,
                  child: Opacity(
                    opacity: _logoFadeAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeColors['logoBackground']!,
                        boxShadow: [
                          BoxShadow(
                            color: themeColors['logoBackground']!
                                .withOpacity(isDarkMode ? 0.3 : 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                         isDarkMode ? TImages.splashDark : TImages.splashLight,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                        // child: Icon(
                        //   Icons.groups_outlined, // TeamSpot icon
                        //   size: 40,
                        //   color: themeColors['logoIcon']!,
                        // ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Rotating particles around logo
            AnimatedBuilder(
              animation: _radarAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int i = 0; i < 8; i++)
                      Transform.rotate(
                        angle: (_radarAnimation.value * 2 * math.pi) +
                            (i * math.pi / 4),
                        child: Transform.translate(
                          offset: const Offset(60, 0),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeColors['primary']!
                                  .withOpacity(isDarkMode ? 0.6 : 0.7),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            // App name text
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.3,
              child: AnimatedBuilder(
                animation: _logoFadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoFadeAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          'TeamSpot',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: themeColors['primary']!,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Workspace',
                          style: TextStyle(
                            fontSize: 16,
                            color: themeColors['primary']!.withOpacity(0.7),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // // Loading indicator
            // Positioned(
            //   bottom: 60,
            //   child: AnimatedBuilder(
            //     animation: _logoFadeAnimation,
            //     builder: (context, child) {
            //       return Opacity(
            //         opacity: _logoFadeAnimation.value,
            //         child: SizedBox(
            //           width: 40,
            //           height: 40,
            //           child: CircularProgressIndicator(
            //             valueColor: AlwaysStoppedAnimation<Color>(
            //               themeColors['primary']!.withOpacity(0.5),
            //             ),
            //             strokeWidth: 2,
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
