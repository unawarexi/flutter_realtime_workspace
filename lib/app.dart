import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/config/themes/app_theme.dart';
import 'package:flutter_realtime_workspace/features/authentication/presentation/authentication.dart';
import 'package:flutter_realtime_workspace/screens/onboarding_screens/onboarding_screens.dart';
import 'package:flutter_realtime_workspace/shared/components/custom_bottom_sheet.dart'; // Import BottomNavigationBarWidget

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      home: const OnboardingScreen(), // Show onboarding screen initially
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return MaterialPageRoute(
              builder: (context) => const OnboardingScreen(),
            );
          case '/signup':
            return MaterialPageRoute(
              builder: (context) => const Authentication(), // Sign-up screen
            );
          case '/home':
            return MaterialPageRoute(
              builder: (context) => const BottomNavigationBarWidget(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const OnboardingScreen(),
            );
        }
      },
    );
  }
}
