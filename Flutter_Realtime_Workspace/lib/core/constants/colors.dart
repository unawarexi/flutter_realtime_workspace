import 'package:flutter/material.dart';

class TColors {
  TColors._();

  // ── Core brand colors ──────────────────────────────────────────────────────
  static const Color accentBlue = Color(0xFF2B77AD);
  static const Color primaryBlue = Color(0xFF1A365D);
  static const Color lightBlue = Color(0xFF4299E1);
  static const Color green = Color(0xFF10B981);
  static const Color yellow = Color(0xFFF59E0B);
  static const Color purple = Color(0xFF8B5CF6);

  // ── Primary alias ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2B77AD);
  static const Color primarySurface = Color(0xFFE8F2FA);
  static const Color primaryMuted = Color(0xFF9DC5E0);

  // ── Gradient colors ────────────────────────────────────────────────────────
  static const LinearGradient blueGradient = LinearGradient(
    colors: [primaryBlue, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF1A365D), Color(0xFF2B77AD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Text colors ────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1A202C);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryLight = Color(0xFF718096);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryLight = Color(0xFF64748B);
  static const Color textTertiaryDark = Color(0xFF64748B);

  // Text aliases used across widgets
  static const Color textLight = Color(0xFF718096);
  static const Color textDark = Color(0xFF94A3B8);
  static const Color textLightSecondary = Color(0xFF718096);
  static const Color textDarkSecondary = Color(0xFF94A3B8);
  static const Color textLightTertiary = Color(0xFF64748B);
  static const Color textDarkTertiary = Color(0xFF64748B);

  // ── Background colors ──────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF7FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color backgroundDarkAlt = Color(0xFF0A0E1A);

  // Light/dark semantic aliases
  static const Color lightBg = Color(0xFFF7FAFC);
  static const Color darkBg = Color(0xFF0A0E1A);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color lightElevated = Color(0xFFF1F5F9);
  static const Color darkElevated = Color(0xFF334155);
  static const Color lightHover = Color(0xFFE2E8F0);
  static const Color darkHover = Color(0xFF475569);
  static const Color lightMuted = Color(0xFFA0AEC0);
  static const Color darkMuted = Color(0xFF64748B);

  // Compatibility aliases
  static const Color backgroundColorLight = backgroundLight;
  static const Color backgroundColorDark = backgroundDarkAlt;

  // ── Card colors ────────────────────────────────────────────────────────────
  static const Color cardColorLight = Color(0xFFFFFFFF);
  static const Color cardColorDark = Color(0xFF1E293B);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF1E293B);

  // ── Button colors ──────────────────────────────────────────────────────────
  static const Color buttonPrimary = Color(0xFF1E40AF);
  static const Color buttonPrimaryLight = Color(0xFF3B82F6);

  // ── Border colors ──────────────────────────────────────────────────────────
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color darkBorder = Color(0xFF334155);

  // ── Status colors ──────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFF4D4F);
  static const Color warning = Color(0xFFFFC53D);
  static const Color success = Color(0xFF52C41A);
  static const Color info = Color(0xFF1890FF);

  // ── Neutral ────────────────────────────────────────────────────────────────
  static const Color neutralGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF1F5F9);

  // ── Blue shades ────────────────────────────────────────────────────────────
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue900 = Color(0xFF1E3A8A);

  // ── Quick action palette ───────────────────────────────────────────────────
  static const Color quickActionBlue = Color(0xFF3B82F6);
  static const Color quickActionGreen = Color(0xFF10B981);
  static const Color quickActionPurple = Color(0xFF8B5CF6);
  static const Color quickActionYellow = Color(0xFFF59E0B);

  // ── Misc text aliases ──────────────────────────────────────────────────────
  static const Color tertiaryLight = Color(0xFF64748B);
  static const Color secondaryDark = Color(0xFF94A3B8);
  static const Color darkText = Color(0xFF0F172A);
}
