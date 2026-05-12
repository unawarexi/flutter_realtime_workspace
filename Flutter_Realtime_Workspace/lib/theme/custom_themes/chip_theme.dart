import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';

class TChipTheme {
  TChipTheme._();

  static ChipThemeData lightChipTheme = ChipThemeData(
      disabledColor: TColors.lightMuted.withValues(alpha: 0.4),
      labelStyle: const TextStyle(color: TColors.textLight),
      selectedColor: TColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
      checkmarkColor: Colors.white);

  static const ChipThemeData darkChipTheme = ChipThemeData(
      disabledColor: TColors.darkMuted,
      labelStyle: TextStyle(color: TColors.textDark),
      selectedColor: TColors.primary,
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
      checkmarkColor: Colors.white);
}
