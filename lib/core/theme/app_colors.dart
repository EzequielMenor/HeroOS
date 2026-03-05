import 'package:flutter/material.dart';

/// Paleta de colores centralizada de HeroOS.
/// Módulos con su accent color específico para mantener identidad visual.
abstract final class AppColors {
  // --- Backgrounds ---
  static const Color scaffold = Color(0xFF121212); // Dark base
  static const Color surface = Color(0xFF1E1E1E); // Cards / Sheets

  // --- Primary ---
  static const Color primary = Colors.white;

  // --- Module Accents ---
  static const Color finance = Color(0xFF4CAF50); // 🟢 Oro / Ingresos
  static const Color habits = Color(0xFF2196F3); // 🔵 Racha / Hábitos
  static const Color sleep = Color(0xFF673AB7); // 🟣 Sueño / Descanso
  static const Color rpg = Color(0xFF9C27B0); // 🟣 XP / Level Up
  static const Color danger = Color(0xFFF44336); // 🔴 HP Loss / Gastos

  // --- Neutral ---
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF2C2C2C);
}
