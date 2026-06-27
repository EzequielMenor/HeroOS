import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/responsive_shell.dart';
import '../widgets/zen_glass.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Center(
          child: Text(
            'Jardín Zen',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ZenGlass(
              borderRadius: 32.0,
              height: 64.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(Icons.dashboard_outlined, color: AppColors.textPrimary),
                  Icon(Icons.add_circle_outline, color: AppColors.textPrimary, size: 32),
                  Icon(Icons.person_outline, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
