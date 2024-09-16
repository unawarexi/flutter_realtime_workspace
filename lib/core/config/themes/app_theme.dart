import "package:flutter/material.dart";
import "package:flutter_realtime_workspace/core/config/themes/custom/app_bar_theme.dart";
import "package:flutter_realtime_workspace/core/config/themes/custom/bottom_sheet_theme.dart";
import "package:flutter_realtime_workspace/core/config/themes/custom/check_box_theme.dart";
import "package:flutter_realtime_workspace/core/config/themes/custom/chip_theme.dart";
import "package:flutter_realtime_workspace/core/config/themes/custom/elevated_button_theme.dart";
import "package:flutter_realtime_workspace/core/config/themes/custom/outlined_button_theme.dart";
import "package:flutter_realtime_workspace/core/config/themes/custom/text_field_theme.dart";
import "package:flutter_realtime_workspace/core/config/themes/custom/text_theme.dart";

class TAppTheme {
  TAppTheme._();

  static ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      fontFamily: "Poppins",
      brightness: Brightness.light,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      textTheme: TTextTheme.lightTextTheme,
      chipTheme: TChipTheme.lightChipTheme,
      appBarTheme: TAppBarTheme.lightAppBarTheme,
      checkboxTheme: TCheckBoxTheme.lightCheckBoxTheme,
      bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
      outlinedButtonTheme: TOutlineButtonTheme.lightOutlinedButtonTheme,
      elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
      inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme);

  // ---------- GENERAL DARK APLLICATION THEME ------------------ //
  static ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      fontFamily: "Poppins",
      brightness: Brightness.dark,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.black,
      textTheme: TTextTheme.darkTextTheme,
      chipTheme: TChipTheme.darkChipTheme,
      appBarTheme: TAppBarTheme.darkAppBarTheme,
      checkboxTheme: TCheckBoxTheme.darkCheckBoxTheme,
      bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,
      outlinedButtonTheme: TOutlineButtonTheme.darkOutlinedButtonTheme,
      elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
      inputDecorationTheme: TTextFormFieldTheme.darkInputDecorationTheme);
}
