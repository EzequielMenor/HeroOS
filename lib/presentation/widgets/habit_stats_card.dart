import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'zen_solid_card.dart';

/// Habit stats card with key metrics: current streak, best streak, completion rate.
///
/// Per Zen Glass Hierarchy: content cards use solid surface, not glass.
class HabitStatsCard extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final double completionRate; // 0.0 to 1.0

  const HabitStatsCard({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (completionRate * 100).round();

    return ZenSolidCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics row
          Row(
            children: [
              _metric(Icons.local_fire_department, '$currentStreak', 'Racha'),
              const SizedBox(width: 24),
              _metric(Icons.emoji_events_outlined, '$bestStreak', 'Mejor'),
              const SizedBox(width: 24),
              _metric(Icons.bar_chart_rounded, '$pct%', '30 días'),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completionRate,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Completado $pct%',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(height: 4),
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
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
