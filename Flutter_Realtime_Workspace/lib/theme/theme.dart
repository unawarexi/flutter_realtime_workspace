import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/theme/custom_themes/app_bar_theme.dart';
import 'package:flutter_realtime_workspace/theme/custom_themes/bottom_sheet_theme.dart';
import 'package:flutter_realtime_workspace/theme/custom_themes/check_box_theme.dart';
import 'package:flutter_realtime_workspace/theme/custom_themes/chip_theme.dart';
import 'package:flutter_realtime_workspace/theme/custom_themes/elevated_button_theme.dart';
import 'package:flutter_realtime_workspace/theme/custom_themes/outlined_button_theme.dart';
import 'package:flutter_realtime_workspace/theme/custom_themes/text_field_theme.dart';
import 'package:flutter_realtime_workspace/theme/custom_themes/text_theme.dart';

class TAppTheme {
  TAppTheme._();

  // ──────────────── LIGHT THEME ────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: TColors.primary,
    colorScheme: const ColorScheme.light(
      primary: TColors.primary,
      primaryContainer: TColors.primarySurface,
      secondary: TColors.blue700,
      surface: TColors.lightSurface,
      error: TColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: TColors.textLight,
      onError: Colors.white,
      outline: TColors.lightBorder,
    ),
    scaffoldBackgroundColor: TColors.lightBg,
    cardColor: TColors.lightCard,
    dividerColor: TColors.lightBorder,
    hoverColor: TColors.lightHover,
    textTheme: TTextTheme.lightTextTheme,
    chipTheme: TChipTheme.lightChipTheme,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    checkboxTheme: TCheckBoxTheme.lightCheckBoxTheme,
    bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
    outlinedButtonTheme: TOutlineButtonTheme.lightOutlinedButtonTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TColors.lightSurface,
      selectedItemColor: TColors.primary,
      unselectedItemColor: TColors.lightMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: TColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: TColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TColors.darkCard,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TColors.primary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return TColors.primary;
        return TColors.lightMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return TColors.primaryMuted;
        return TColors.lightBorder;
      }),
    ),
  );

  // ──────────────── DARK THEME ────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: TColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: TColors.primary,
      primaryContainer: TColors.blue900,
      secondary: TColors.blue400,
      surface: TColors.darkSurface,
      error: TColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: TColors.textDark,
      onError: Colors.white,
      outline: TColors.darkBorder,
    ),
    scaffoldBackgroundColor: TColors.darkBg,
    cardColor: TColors.darkCard,
    dividerColor: TColors.darkBorder,
    hoverColor: TColors.darkHover,
    textTheme: TTextTheme.darkTextTheme,
    chipTheme: TChipTheme.darkChipTheme,
    appBarTheme: TAppBarTheme.darkAppBarTheme,
    checkboxTheme: TCheckBoxTheme.darkCheckBoxTheme,
    bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,
    outlinedButtonTheme: TOutlineButtonTheme.darkOutlinedButtonTheme,
    elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.darkInputDecorationTheme,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TColors.darkSurface,
      selectedItemColor: TColors.primary,
      unselectedItemColor: TColors.darkMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: TColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: TColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TColors.darkElevated,
      contentTextStyle: const TextStyle(color: TColors.textDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TColors.primary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return TColors.primary;
        return TColors.darkMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return TColors.blue900;
        return TColors.darkBorder;
      }),
    ),
  );
}
