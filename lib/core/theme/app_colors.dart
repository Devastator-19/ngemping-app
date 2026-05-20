import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Forest Green
  static const Color primary = Color(0xFF4A7C59);
  static const Color primaryLight = Color(0xFF7BAD8B);
  static const Color primaryPastel = Color(0xFFA8C5A0);
  static const Color primaryDark = Color(0xFF2D5C3F);
  static const Color primarySurface = Color(0xFFEDF4ED);

  // Secondary - Earthy Amber
  static const Color secondary = Color(0xFF8B6914);
  static const Color secondaryLight = Color(0xFFD4A853);
  static const Color secondarySurface = Color(0xFFFFF8E7);

  // Background & Surface
  static const Color background = Color(0xFFF5F0E8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0EDE6);

  // Text
  static const Color textDark = Color(0xFF1E2D1E);
  static const Color textMedium = Color(0xFF5C6E5C);
  static const Color textLight = Color(0xFF9EB09E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // UI Elements
  static const Color divider = Color(0xFFDCE8DC);
  static const Color border = Color(0xFFCDDDCD);
  static const Color error = Color(0xFFB85C5C);
  static const Color errorSurface = Color(0xFFFDF0F0);
  static const Color success = Color(0xFF4A7C59);
  static const Color white = Color(0xFFFFFFFF);

  // Gradients
  static const List<Color> splashGradient = [
    Color(0xFF1A3D2B),
    Color(0xFF2D5C3F),
    Color(0xFF4A7C59),
  ];

  static const List<Color> heroBannerGradient = [
    Color(0xFF2D5C3F),
    Color(0xFF4A7C59),
    Color(0xFF6B9E7A),
  ];

  static const List<Color> cardGradient = [
    Color(0xFF4A7C59),
    Color(0xFF7BAD8B),
  ];
}
