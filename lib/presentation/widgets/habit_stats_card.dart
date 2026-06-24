import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Card con las métricas clave de un hábito:
/// racha actual, mejor racha, tasa de completado + barra de progreso.
class HabitStatsCard extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final double completionRate; // 0.0 a 1.0

  const HabitStatsCard({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (completionRate * 100).round();

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila de métricas
            Row(
              children: [
                _metric(Icons.local_fire_department, '$currentStreak', 'Racha'),
                SizedBox(width: 24),
                _metric(Icons.emoji_events_outlined, '$bestStreak', 'Mejor'),
                SizedBox(width: 24),
                _metric(Icons.bar_chart_rounded, '$pct%', '30 días'),
              ],
            ),
            SizedBox(height: 16),
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: completionRate,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.habits,
                ),
              ),
            ),
            SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Completado $pct%',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.habits, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
