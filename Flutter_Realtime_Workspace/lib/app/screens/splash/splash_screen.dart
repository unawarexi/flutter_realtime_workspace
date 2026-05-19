import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realtime_workspace/core/animations/screen_animations.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:go_router/go_router.dart';

import 'widgets/splash_app_name.dart';
import 'widgets/splash_background.dart';
import 'widgets/splash_logo.dart';

class TeamSpotSplashScreen extends StatefulWidget {
  const TeamSpotSplashScreen({super.key});

  @override
  State<TeamSpotSplashScreen> createState() => _TeamSpotSplashScreenState();
}

class _TeamSpotSplashScreenState extends State<TeamSpotSplashScreen>
    with TickerProviderStateMixin {
  // Animation presets (screen_animations.dart)
  late final RadarSweepAnim _radar;
  late final OscillatePulseAnim _pulse;
  late final BrandRevealAnim _brand;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _radar = RadarSweepAnim(vsync: this)..repeat();
    _pulse = OscillatePulseAnim(vsync: this)..repeat();
    _brand = BrandRevealAnim(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // GoRouter redirect determines actual destination:
    //   • first-time user  → /onboarding
    //   • returning user   → /home
    //   • logged-out user  → /login
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _radar.dispose();
    _pulse.dispose();
    _brand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    // In light mode: use rich brand-blue so the white icon pops clearly.
    final ringColor =
        isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF1E40AF);
    final logoContainerColor =
        isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF1E40AF);
    final textColor =
        isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF1E40AF);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _radar.controller,
          _pulse.controller,
          _brand.controller,
        ]),
        builder: (context, _) {
          return SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Layer 1: Radial gradient bg + animated radar rings ─────────
                Positioned.fill(
                  child: SplashBackground(
                    ringColor: ringColor,
                    sweepValue: _radar.value.value,
                    pulseValue: _pulse.value.value,
                    isDarkMode: isDarkMode,
                  ),
                ),

                // ── Layer 2: Central logo + orbiting particles ─────────────────
                SplashLogo(
                  fadeValue: _brand.fade.value,
                  scaleValue: _brand.scale.value,
                  orbitValue: _radar.value.value,
                  containerColor: logoContainerColor,
                  particleColor: ringColor,
                  isDarkMode: isDarkMode,
                ),

                // ── Layer 3: App name text (below center) ──────────────────────
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.30,
                  child: SplashAppName(
                    fadeValue: _brand.fade.value,
                    textColor: textColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
