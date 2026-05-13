import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realtime_workspace/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/router/app_router.dart';
import 'package:flutter_realtime_workspace/store/theme_provider.dart';
import 'package:flutter_realtime_workspace/app/components/ui/connectivity_toast.dart';

class TeamSpotApp extends ConsumerWidget {
  const TeamSpotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'TeamSpot',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      themeMode: themeMode,

      // Router
      routerConfig: appRouter,

      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor:
                isDark ? TColors.darkBg : TColors.lightBg,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => Column(
                  children: [
                    const ConnectivityToast(),
                    Expanded(child: child ?? const SizedBox.shrink()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}