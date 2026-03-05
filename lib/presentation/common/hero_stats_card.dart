import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/profile_entity.dart';

/// Widget reutilizable que muestra los stats de héroe.
/// Dumb Widget: solo recibe [ProfileEntity] y renderiza. Sin lógica.
class HeroStatsCard extends StatelessWidget {
  final ProfileEntity profile;

  const HeroStatsCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // — Header: nombre y nivel —
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.rpg,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    profile.username,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rpg.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lvl ${profile.level}',
                    style: const TextStyle(
                      color: AppColors.rpg,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // — XP Bar —
            _StatBar(
              label: 'XP',
              value: '${profile.currentXp} / ${profile.xpNextLevel}',
              progress: profile.xpProgress,
              color: AppColors.rpg,
              icon: Icons.auto_awesome,
            ),
            const SizedBox(height: 10),

            // — HP Bar —
            _StatBar(
              label: 'HP',
              value: '${profile.currentHp} / ${profile.maxHp}',
              progress: profile.hpProgress,
              color: profile.currentHp < profile.maxHp * 0.3
                  ? AppColors.danger
                  : AppColors.habits,
              icon: Icons.favorite_outline,
            ),
            const SizedBox(height: 14),

            // — Oro —
            Row(
              children: [
                const Icon(
                  Icons.monetization_on_outlined,
                  color: AppColors.finance,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${profile.currentGold.toStringAsFixed(2)} G',
                  style: const TextStyle(
                    color: AppColors.finance,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;
  final IconData icon;

  const _StatBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
