import 'package:flutter/material.dart';

class AppTheme {
  // Premium, Minimalist, & Futuristic Dark Palette
  static const Color background = Color(0xFF0B0B0C);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceHighlight = Color(0xFF252528);
  static const Color accent = Color(0xFF0A84FF); // Striking Cyber Blue
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA0A0A5);

  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
        background: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontFamily: 'Inter', color: textPrimary),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: textSecondary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
