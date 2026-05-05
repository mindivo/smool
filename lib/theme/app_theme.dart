import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SmoolColors {
  static const sky = Color(0xFFB8D4E8);
  static const horizon = Color(0xFFE8DCC4);
  static const meadow = Color(0xFF8FA68A);
  static const stone = Color(0xFF2E3530);
  static const stoneSoft = Color(0xFF4A554D);
  static const cream = Color(0xFFF5EFE0);
  static const glassTint = Color(0x33FFFFFF);
  static const glassEdge = Color(0x55FFFFFF);
  static const muted = Color(0xFF6B7268);
  static const accentCalm = Color(0xFF7A9078);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.fraunces(
        fontSize: 44,
        fontWeight: FontWeight.w500,
        color: SmoolColors.stone,
        height: 1.05,
      ),
      displayMedium: GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        color: SmoolColors.stone,
        height: 1.1,
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: SmoolColors.stone,
      ),
      titleLarge: GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: SmoolColors.stone,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: SmoolColors.stone,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        color: SmoolColors.stoneSoft,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: SmoolColors.stoneSoft,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: SmoolColors.muted,
        letterSpacing: 0.2,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: SmoolColors.stone,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: base.colorScheme.copyWith(
        primary: SmoolColors.accentCalm,
        secondary: SmoolColors.meadow,
        surface: SmoolColors.cream,
      ),
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: SmoolColors.stone, size: 22),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: SmoolColors.stone),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
