import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';

class TBottomSheetTheme {
  TBottomSheetTheme._();

  static const BottomSheetThemeData lightBottomSheetTheme =
      BottomSheetThemeData(
    backgroundColor: TColors.lightSurface,
    modalBackgroundColor: TColors.lightSurface,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    constraints: BoxConstraints(minWidth: double.infinity),
    showDragHandle: true,
    dragHandleColor: TColors.lightMuted,
  );

  static const BottomSheetThemeData darkBottomSheetTheme = BottomSheetThemeData(
    backgroundColor: TColors.darkSurface,
    modalBackgroundColor: TColors.darkSurface,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    constraints: BoxConstraints(minWidth: double.infinity),
    showDragHandle: true,
    dragHandleColor: TColors.darkMuted,
  );
}
