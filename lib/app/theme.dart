import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app's design tokens and ThemeData.
///
/// Palette is drawn from the subject (India travel) rather than a stock
/// scheme: [indigoNight] (twilight / indigo-dyed cloth) for headers and
/// text, [marigold] (garlands, spice markets) as the single energetic
/// action color, [chili] for errors and the last stop of a day, and
/// [banyan] (a deep leaf green) as a calm secondary accent.
/// Type: Fraunces for display/headlines, Manrope for everything else.
class AppTheme {
  AppTheme._();

  // Core palette
  static const Color indigoNight = Color(0xFF1B2A4A);
  static const Color indigoNightLight = Color(0xFF2E4270);
  static const Color marigold = Color(0xFFE8871E);
  static const Color marigoldDeep = Color(0xFFC96A0C);
  static const Color chili = Color(0xFFC0392B);
  static const Color banyan = Color(0xFF2F6B4F);

  // Neutrals
  static const Color canvas = Color(0xFFFAF8F5);
  static const Color surface = Colors.white;
  static const Color hairline = Color(0xFFE1E3E8);
  static const Color inkMuted = Color(0xFF5B6272);

  // Stop-order colors (map markers / stop badges)
  static const Color stopFirst = marigold;
  static const Color stopMiddle = indigoNight;
  static const Color stopLast = chili;

  // Kept for any older code that still references the original names.
  static const Color primary = indigoNight;
  static const Color secondary = marigold;
  static const Color background = canvas;
  static const Color error = chili;

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: indigoNight,
      brightness: Brightness.light,
    ).copyWith(
      primary: indigoNight,
      onPrimary: Colors.white,
      secondary: marigold,
      tertiary: banyan,
      error: chili,
      surface: surface,
      onSurface: indigoNight,
      outline: hairline,
      outlineVariant: hairline,
    );

    final base = GoogleFonts.manropeTextTheme(ThemeData.light().textTheme)
        .apply(bodyColor: indigoNight, displayColor: indigoNight);

    TextStyle? fraunces(TextStyle? style) => style == null
        ? null
        : GoogleFonts.fraunces(textStyle: style, fontWeight: FontWeight.w600);

    final textTheme = base.copyWith(
      displayLarge: fraunces(base.displayLarge),
      displayMedium: fraunces(base.displayMedium),
      displaySmall: fraunces(base.displaySmall),
      headlineLarge: fraunces(base.headlineLarge),
      headlineMedium: fraunces(base.headlineMedium),
      headlineSmall: fraunces(base.headlineSmall),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: hairline),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: canvas,
        foregroundColor: indigoNight,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: indigoNight,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: hairline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: marigold,
          foregroundColor: Colors.white,
          disabledBackgroundColor: marigold.withOpacity(0.4),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: indigoNight,
          side: const BorderSide(color: indigoNight, width: 1.4),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: marigoldDeep,
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: indigoNight, width: 1.6),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: chili),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: chili, width: 1.6),
        ),
        labelStyle: const TextStyle(color: inkMuted),
        hintStyle: const TextStyle(color: inkMuted),
        prefixIconColor: inkMuted,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: indigoNight,
        unselectedLabelColor: inkMuted,
        indicatorColor: marigold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: hairline,
        labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w500),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? indigoNight : surface),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.white : indigoNight),
          side: const WidgetStatePropertyAll(BorderSide(color: hairline)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: indigoNight,
        contentTextStyle: GoogleFonts.manrope(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: marigold),
      dividerTheme: const DividerThemeData(color: hairline, thickness: 1),
    );
  }
}