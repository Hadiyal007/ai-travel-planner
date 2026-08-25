import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF2D6A4F); // deep travel green
  static const Color secondary = Color(0xFFE9C46A); // warm accent
  static const Color background = Color(0xFFF8F9FA);
  static const Color error = Color(0xFFBA1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        error: error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 15),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: background,
        foregroundColor: Colors.black87,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}