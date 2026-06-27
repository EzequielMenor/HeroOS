import 'package:flutter/material.dart';

/// Paleta de colores centralizada de HeroOS.
/// Estilo Zen OS: Pitch black, ultra minimalista.
class AppColors {
  // Brand / Semantic
  static const Color primary = Color(0xFFF0EDE8);
  static const Color danger = Color(0xFFF44336);

  // Features (Accent colors)
  static const Color habits = Color(0xFF8FBC8F); // Sage green
  static const Color tasks = Color(0xFF448AFF); // Blue
  static const Color sleep = Color(0xFF7C4DFF); // Purple
  static const Color finance = Color(0xFF00BFA5); // Teal;

  // Zen OS UI Accents (Apple Industrial)
  // Tokens del prototipo CSS — sólo para decoración UI, no semánticos.
  static const Color gold = Color(0xFFD4AF37);
  static const Color coral = Color(0xFFFF6B6B);

  // Theme control (Forced to Dark Mode always, as requested)
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);
  static bool get isDark => true; // Always dark

  // Zen OS Core Colors
  static const Color scaffold = Color(0xFF1C1C1E); // Pitch black
  static const Color surface = Color(0xFF2C2C2E); // Slightly elevated black for sheets/cards
  
  static const Color textPrimary = Color(0xFFF0EDE8); // Bone white
  static const Color textSecondary = Color(0x73F0EDE8); // Bone white 45% opacity
  
  static const Color divider = Color(0x0DFFFFFF); // White 5% opacity
  static const Color accent = habits; 
}
