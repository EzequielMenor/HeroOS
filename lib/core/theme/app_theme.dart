import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ThemeData centralizado de HeroOS — Dark Mode only.
/// Se inyecta en MaterialApp.theme para que todos los widgets
/// hereden la paleta y tipografía automáticamente.
abstract final class AppTheme {
  static ThemeData get dark {
    AppColors.themeMode.value = ThemeMode.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.scaffold,
      colorScheme: ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        displaySmall: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
      ),
      dividerColor: AppColors.divider,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.scaffold,
      ),
    );
  }

  static ThemeData get light {
    AppColors.themeMode.value = ThemeMode.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.scaffold,
      colorScheme: ColorScheme.light(
        surface: AppColors.surface,
        primary: AppColors.primary,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        displaySmall: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
      ),
      dividerColor: AppColors.divider,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.scaffold,
      ),
    );
  }
}
