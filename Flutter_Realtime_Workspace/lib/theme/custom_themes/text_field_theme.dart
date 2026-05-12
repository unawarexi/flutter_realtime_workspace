import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';

class TTextFormFieldTheme {
  TTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: TColors.lightMuted,
    suffixIconColor: TColors.lightMuted,
    labelStyle: const TextStyle().copyWith(fontSize: 14, color: TColors.textLight),
    hintStyle: const TextStyle().copyWith(color: TColors.lightMuted),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal, color: TColors.error),
    floatingLabelStyle:
        const TextStyle().copyWith(color: TColors.primary),
    border: const OutlineInputBorder().copyWith(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: const BorderSide(color: TColors.lightBorder, width: 1),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: const BorderSide(color: TColors.lightBorder, width: 1)),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: const BorderSide(color: TColors.primary, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: const BorderSide(color: TColors.error, width: 1),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: const BorderSide(color: TColors.warning, width: 2),
    ),
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: TColors.darkMuted,
    suffixIconColor: TColors.darkMuted,
    labelStyle: const TextStyle().copyWith(fontSize: 14, color: TColors.textDark),
    hintStyle: const TextStyle().copyWith(color: TColors.darkMuted),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal, color: TColors.error),
    floatingLabelStyle:
        const TextStyle().copyWith(color: TColors.primary),
    border: const OutlineInputBorder().copyWith(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: const BorderSide(color: TColors.darkBorder, width: 1),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: const BorderSide(color: TColors.darkBorder, width: 1)),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: const BorderSide(color: TColors.primary, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: const BorderSide(color: TColors.error, width: 1),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: const BorderSide(color: TColors.warning, width: 2),
    ),
  );
}
