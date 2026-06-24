import os
import re

app_colors = """import 'package:flutter/material.dart';

/// Paleta de colores centralizada de HeroOS.
class AppColors {
  // Brand / Semantic
  static Color primary = Color(0xFFF0EDE8);
  static Color danger = Color(0xFFE57373); // Softer red

  // Features
  static Color habits = Color(0xFF81C784); // Softer sage green
  static Color tasks = Color(0xFF64B5F6); // Softer blue
  static Color sleep = Color(0xFF9575CD); // Softer purple
  static Color finance = Color(0xFF4DB6AC); // Softer teal

  // Theme control
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);
  static bool get isDark => themeMode.value == ThemeMode.dark;

  // Dynamic Theme Colors
  // Dark: Not pitch black (#1A1A1A instead of #060606)
  // Light: Not blinding white (#F5F4F1 instead of #FFFFFF)
  static Color get scaffold => isDark ? Color(0xFF1A1A1A) : Color(0xFFF5F4F1);
  static Color get surface => isDark ? Color(0xFF242424) : Color(0xFFEFEFEA);
  
  static Color get textPrimary => isDark ? Color(0xFFE0E0E0) : Color(0xFF2D2D2D);
  static Color get textSecondary => isDark ? Color(0xFF9E9E9E) : Color(0xFF757575);
  
  static Color get divider => isDark ? Color(0x1AFFFFFF) : Color(0x1A000000);
  static Color get accent => isDark ? habits : habits; 
}
"""

with open('lib/core/theme/app_colors.dart', 'w') as f:
    f.write(app_colors)

# List of files to replace hardcoded colors
files = [
    'lib/presentation/screens/finance_screen.dart',
    'lib/presentation/screens/habits_screen.dart',
    'lib/presentation/screens/notes_screen.dart',
    'lib/presentation/screens/profile_screen.dart',
    'lib/presentation/screens/sleep_screen.dart',
    'lib/presentation/screens/tasks_screen.dart',
]

def replace_hardcoded(filepath):
    if not os.path.exists(filepath): return
    with open(filepath, 'r') as f:
        c = f.read()
    
    # Ensure import is present if not
    if "import '../../core/theme/app_colors.dart';" not in c:
        # finance_screen had a warning about unused import, so it might be there.
        # But just to be safe, if we use AppColors, we need to import it.
        c = c.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../core/theme/app_colors.dart';")

    # Replace getters
    # Finance
    c = re.sub(r'Color get _kSageGreen\s*=>\s*Color\(.*?\);', r'Color get _kSageGreen => AppColors.habits;', c)
    c = re.sub(r'Color get _kDanger\s*=>\s*Color\(.*?\);', r'Color get _kDanger => AppColors.danger;', c)
    c = re.sub(r'Color get _kTextPrim\s*=>\s*Color\(.*?\);', r'Color get _kTextPrim => AppColors.textPrimary;', c)
    c = re.sub(r'Color get _kTextSec\s*=>\s*Color\(.*?\);', r'Color get _kTextSec => AppColors.textSecondary;', c)
    c = re.sub(r'Color get _kDivider\s*=>\s*Color\(.*?\);', r'Color get _kDivider => AppColors.divider;', c)
    c = re.sub(r'Color get _kSurface\s*=>\s*Color\(.*?\);', r'Color get _kSurface => AppColors.surface;', c)
    c = re.sub(r'Color get _kScaffold\s*=>\s*Color\(.*?\);', r'Color get _kScaffold => AppColors.scaffold;', c)

    # General / Notes / Profile / Sleep / Tasks
    c = re.sub(r'Color get _kBg\s*=>\s*.*?;\n?', r'Color get _kBg => AppColors.scaffold;\n', c)
    c = re.sub(r'Color get _kSurface\s*=>\s*.*?;\n?', r'Color get _kSurface => AppColors.surface;\n', c)
    c = re.sub(r'Color get _kTextPrimary\s*=>\s*.*?;\n?', r'Color get _kTextPrimary => AppColors.textPrimary;\n', c)
    c = re.sub(r'Color get _kTextSecondary\s*=>\s*.*?;\n?', r'Color get _kTextSecondary => AppColors.textSecondary;\n', c)
    c = re.sub(r'Color get _kDivider\s*=>\s*.*?;\n?', r'Color get _kDivider => AppColors.divider;\n', c)
    c = re.sub(r'Color get _kAccent\s*=>\s*.*?;\n?', r'Color get _kAccent => AppColors.accent;\n', c)
    c = re.sub(r'Color get _kDanger\s*=>\s*.*?;\n?', r'Color get _kDanger => AppColors.danger;\n', c)

    with open(filepath, 'w') as f:
        f.write(c)

for f in files:
    replace_hardcoded(f)
print("Replaced hardcoded colors successfully.")
