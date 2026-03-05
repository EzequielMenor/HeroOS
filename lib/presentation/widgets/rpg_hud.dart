import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/profile_entity.dart';

/// HUD superior (Head-Up Display) para el Dashboard RPG.
/// Formato de Tarjeta (Card) para las estadísticas principales.
/// [compact] — versión reducida para el sidebar web (menos márgenes,
/// avatar más pequeño, oro en fila separada para no comprimir el nombre).
class RpgHud extends StatelessWidget {
  final ProfileEntity profile;
  final bool compact;

  const RpgHud({super.key, required this.profile, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildFull() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // — Header: Avatar/Nombre y Oro —
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.rpg.withValues(alpha: 0.2),
                  child: _avatarChild(20, 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.username,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _levelBadge(12),
                    ],
                  ),
                ),
                // Oro
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_outlined,
                      color: AppColors.finance,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${profile.currentGold.toStringAsFixed(2)} G',
                      style: const TextStyle(
                        color: AppColors.finance,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // — XP Bar —
            _StatBar(
              label: 'XP',
              value: '${profile.currentXp} / ${profile.xpNextLevel}',
              progress: profile.xpProgress,
              color: AppColors.rpg,
              icon: Icons.auto_awesome,
            ),
            const SizedBox(height: 12),

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
          ],
        ),
      ),
    );
  }

  /// Versión compacta para el sidebar: sin Card externa, avatar pequeño,
  /// oro en su propia fila para no comprimir el nombre del héroe.
  Widget _buildCompact() {
    final hpColor = profile.currentHp < profile.maxHp * 0.3
        ? AppColors.danger
        : AppColors.habits;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rpg.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.rpg.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Avatar + Nombre + Nivel
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.rpg.withValues(alpha: 0.2),
                child: _avatarChild(16, 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _levelBadge(11),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Fila 2: Oro
          Row(
            children: [
              const Icon(
                Icons.monetization_on_outlined,
                color: AppColors.finance,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                '${profile.currentGold.toStringAsFixed(2)} G',
                style: const TextStyle(
                  color: AppColors.finance,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // XP Bar
          _StatBar(
            label: 'XP',
            value: '${profile.currentXp}/${profile.xpNextLevel}',
            progress: profile.xpProgress,
            color: AppColors.rpg,
            icon: Icons.auto_awesome,
          ),
          const SizedBox(height: 8),

          // HP Bar
          _StatBar(
            label: 'HP',
            value: '${profile.currentHp}/${profile.maxHp}',
            progress: profile.hpProgress,
            color: hpColor,
            icon: Icons.favorite_outline,
          ),
        ],
      ),
    );
  }

  Widget _avatarChild(double radius, double fontSize) {
    if (profile.avatarUrl != null) {
      return ClipOval(
        child: Image.network(
          profile.avatarUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        ),
      );
    }
    return Text(
      profile.username.isNotEmpty
          ? profile.username.substring(0, 1).toUpperCase()
          : 'H',
      style: TextStyle(
        color: AppColors.rpg,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _levelBadge(double fontSize) {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.rpg.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Lvl ${profile.level}',
        style: TextStyle(
          color: AppColors.rpg,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
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
                fontWeight: FontWeight.w600,
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
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.divider.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
