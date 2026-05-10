import 'package:flutter/material.dart';

class THelperFunctions {
   // Check if dark mode is enabled
  static bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }
}