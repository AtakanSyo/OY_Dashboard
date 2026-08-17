import 'package:flutter/material.dart';

abstract final class DmlColors {
  static const ink = Color(0xFF182629);
  static const inkSoft = Color(0xFF26373B);
  static const slate = Color(0xFF607176);
  static const mist = Color(0xFFE8ECEC);
  static const surface = Color(0xFFF5F7F7);
  static const white = Colors.white;
  static const accent = Color(0xFF9DB4B8);
}

abstract final class DmlTheme {
  static ThemeData get data {
    final scheme = ColorScheme.fromSeed(
      seedColor: DmlColors.ink,
      brightness: Brightness.light,
      primary: DmlColors.ink,
      secondary: DmlColors.slate,
      surface: DmlColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: DmlColors.surface,
      dividerColor: DmlColors.mist,
      cardTheme: const CardThemeData(
        color: DmlColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DmlColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DmlColors.mist),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DmlColors.ink,
          foregroundColor: DmlColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DmlColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          side: const BorderSide(color: DmlColors.slate),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
