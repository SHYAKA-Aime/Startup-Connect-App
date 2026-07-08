import 'package:flutter/material.dart';

/// Central design system for ALU Ventures.
///
/// Built around ALU's brand identity — deep navy + red on white — so the app
/// reads as an official ALU-ecosystem product rather than a generic template.
/// Keeping colours, radii and text styles in one place means every screen stays
/// visually consistent and a rebrand is a one-file change: this is the
/// "single source of truth" argument for maintainability you can make in the demo.
class AppColors {
  AppColors._();

  // ALU brand
  static const Color navy = Color(0xFF0B2C5D); // primary brand navy
  static const Color navyDark = Color(0xFF071E3F);
  static const Color navySoft = Color(0xFF1C4A8A); // lighter navy for gradients
  static const Color red = Color(0xFFE11F3C); // ALU red — used for key CTAs
  static const Color redDark = Color(0xFFB01730);

  // Semantic aliases (screens reference these, not raw brand colours)
  static const Color primary = navy;
  static const Color accent = red;

  static const Color background = Color(0xFFF5F6F9);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF141A24);
  static const Color textSecondary = Color(0xFF697084);

  static const Color success = Color(0xFF2F9E6E);
  static const Color warning = Color(0xFFE1A100);
  static const Color danger = Color(0xFFE0563F);
  static const Color info = navySoft;

  static const Color chipBg = Color(0xFFEEF1F6);
  static const Color border = Color(0xFFE4E7EE);

  /// Gradient used on hero / featured cards — navy into ALU red.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [navy, navySoft, red],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  AppTheme._();

  static const double radius = 16;

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.red,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.chipBg,
        side: BorderSide.none,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}
