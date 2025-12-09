import 'package:flutter/material.dart';

/// App color constants based on design spec
class AppColors {
  // Primary colors
  static const Color primaryBlue = Color(0xFF1E3A5F);
  static const Color powerballRed = Color(0xFFE63946);
  static const Color accentOrange = Color(0xFFF4A261);
  static const Color successGreen = Color(0xFF2A9D8F);
  static const Color coldBlue = Color(0xFFA8DADC);

  // Trend indicators
  static const Color hotRising = powerballRed; // Red
  static const Color warming = accentOrange; // Orange
  static const Color stable = successGreen; // Green
  static const Color cooling = coldBlue; // Light Blue
  static const Color coldFalling = Color(0xFF457B9D); // Darker Blue

  // UI colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color divider = Color(0xFFE9ECEF);

  // Dark theme
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Status colors
  static const Color warning = accentOrange;
  static const Color warningYellow = Color(0xFFFFC107);
  static const Color error = powerballRed;
  static const Color errorRed = powerballRed;
  static const Color info = primaryBlue;
  static const Color success = successGreen;

  // Number ball colors
  static const Color whiteBallFill = Colors.white;
  static const Color whiteBallBorder = Color(0xFF495057);
  static const Color powerballFill = powerballRed;
  static const Color powerballText = Colors.white;
}
