import 'package:flutter/material.dart';

class TColors {
  TColors._();

  // app basic colors
  static const Color accentBlue = Color(0xFF2B77AD);
  static const Color primaryBlue = Color(0xFF1A365D);
  static const Color lightBlue = Color(0xFF4299E1);
  static const Color green = Color(0xFF10B981);
  static const Color yellow = Color(0xFFF59E0B);
  static const Color purple = Color(0xFF8B5CF6);

  // gradient colors
  static const LinearGradient blueGradient = LinearGradient(
    colors: [primaryBlue, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // text colors
  static const Color textPrimaryLight = Color(0xFF1A202C);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryLight = Color(0xFF718096);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryLight = Color(0xFF64748B);
  static const Color textTertiaryDark = Color(0xFF64748B);

  // background colors
  static const Color backgroundLight = Color(0xFFF7FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color backgroundDarkAlt = Color(0xFF0A0E1A);

  // Aliases for compatibility
  static const Color backgroundColorLight = backgroundLight;
  static const Color backgroundColorDark = backgroundDarkAlt;

  // backgriund container colors
  static const Color cardColorLight = Color(0xFFFFFFFF);
  static const Color cardColorDark = Color(0xFF1E293B);

  // button colors
  static const Color buttonPrimary = Color(0xFF1E40AF);
  static const Color buttonPrimaryLight = Color(0xFF3B82F6);

  // border colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Error & Validation Colors
  static const Color error = Color(0xFFFF4D4F);
  static const Color warning = Color(0xFFFFC53D);
  static const Color success = Color(0xFF52C41A);
  static const Color info = Color(0xFF1890FF);

  // Neutral Colors
  static const Color neutralGray = Color(0xFF6B7280);

  // Add missing colors from home.dart

  // Used for text and backgrounds in home.dart
  static const Color darkText = Color(0xFF0F172A); // Used for text in light mode
  static const Color lightCard = Color(0xFFFFFFFF); // Alias for white
  static const Color darkCard = Color(0xFF1E293B); // Alias for cardColorDark
  static const Color darkBorder = Color(0xFF334155); // Alias for borderDark
  static const Color lightBorder = Color(0xFFE2E8F0); // Alias for borderLight

  // Quick Actions and ToolCard colors
  static const Color quickActionBlue = Color(0xFF3B82F6);
  static const Color quickActionGreen = Color(0xFF10B981);
  static const Color quickActionPurple = Color(0xFF8B5CF6);
  static const Color quickActionYellow = Color(0xFFF59E0B);

  // Used for activity and tool icons
  static const Color blue600 = Color(0xFF2563EB); // e.g. Color(0xFF3B82F6) is blue-500, 0xFF2563EB is blue-600
  static const Color blue700 = Color(0xFF1D4ED8); // e.g. Color(0xFF1E3A8A) is blue-900, 0xFF1D4ED8 is blue-700
  static const Color blue900 = Color(0xFF1E3A8A); // Used for dark blue backgrounds/shadows

  // Used for search bar and trailing icons
  static const Color lightGray = Color(0xFFF1F5F9);

  // Used for tertiary and secondary text
  static const Color tertiaryLight = Color(0xFF64748B);
  static const Color secondaryDark = Color(0xFF94A3B8);
}
