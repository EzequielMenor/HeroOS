import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ThemeData centralizado de HeroOS — Dark Mode only.
/// Se inyecta en MaterialApp.theme para que todos los widgets
/// hereden la paleta y tipografía automáticamente.
abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.scaffold,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.primary,
      error: AppColors.danger,
    ),
    // Tipografía: Inter via Google Fonts
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    // Card
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      margin: EdgeInsets.zero,
    ),
    // AppBar transparente
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.scaffold,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    // BottomNavigationBar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
    ),
    // Divider
    dividerColor: AppColors.divider,
    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.scaffold,
    ),
  );
}
