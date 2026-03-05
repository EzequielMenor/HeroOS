import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/adaptive_modal.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/rpg_event_entity.dart';
import '../../domain/entities/user_goals_entity.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/goals_viewmodel.dart';
import '../viewmodels/stats_viewmodel.dart';

/// Pantalla de Perfil del héroe.
/// Muestra Hero Card con stats RPG, objetivos personales editables y configuración.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GoalsViewModel>().loadGoals();
        context.read<StatsViewModel>().loadRecentEvents();
      }
    });
  }

  Future<void> _showEditNameDialog() async {
    final statsVm = context.read<StatsViewModel>();
    final controller = TextEditingController(
      text: statsVm.profile?.username ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Editar nombre',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nombre del héroe',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.rpg),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await statsVm.updateUsername(name);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text(
              'Guardar',
              style: TextStyle(color: AppColors.rpg),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAvatarTap() async {
    final statsVm = context.read<StatsViewModel>();
    try {
      await statsVm.uploadAvatar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  Future<void> _showEditGoalsSheet() async {
    final goalsVm = context.read<GoalsViewModel>();
    if (goalsVm.goals == null) return;

    await showAdaptiveModal<void>(
      context,
      _EditGoalsSheet(
        goals: goalsVm.goals!,
        onSave: (updated) async {
          await goalsVm.updateGoals(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsVm = context.watch<StatsViewModel>();
    final goalsVm = context.watch<GoalsViewModel>();
    final profile = statsVm.profile;

    if (context.isWeb) {
      return _buildWebLayout(profile, goalsVm, statsVm.recentEvents, statsVm);
    }
    return _buildMobileLayout(profile, goalsVm, statsVm.recentEvents, statsVm);
  }

  // ── WEB: 2-column layout ────────────────────────────────────────────────────

  Widget _buildWebLayout(
    ProfileEntity? profile,
    GoalsViewModel goalsVm,
    List<RpgEventEntity> events,
    StatsViewModel statsVm,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: hero card + settings
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (profile != null) _HeroCard(
                      profile: profile,
                      isUploading: statsVm.isUploading,
                      onAvatarTap: _handleAvatarTap,
                    ),
                    const SizedBox(height: 16),
                    const _SectionLabel(
                      icon: Icons.settings_outlined,
                      title: 'CONFIGURACIÓN',
                    ),
                    const SizedBox(height: 8),
                    _buildSettingsCard(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right column: goals
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionLabel(
                      icon: Icons.track_changes_outlined,
                      title: 'MIS OBJETIVOS',
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildGoalsContent(goalsVm),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel(
            icon: Icons.history_outlined,
            title: 'ACTIVIDAD RECIENTE',
          ),
          const SizedBox(height: 8),
          _ActivityFeed(events: events),
        ],
      ),
    );
  }

  // ── MOBILE: single-column layout ───────────────────────────────────────────

  Widget _buildMobileLayout(
    ProfileEntity? profile,
    GoalsViewModel goalsVm,
    List<RpgEventEntity> events,
    StatsViewModel statsVm,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profile != null) _HeroCard(
            profile: profile,
            isUploading: statsVm.isUploading,
            onAvatarTap: _handleAvatarTap,
          ),
          const SizedBox(height: 16),
          const _SectionLabel(
            icon: Icons.track_changes_outlined,
            title: 'MIS OBJETIVOS',
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildGoalsContent(goalsVm),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel(
            icon: Icons.settings_outlined,
            title: 'CONFIGURACIÓN',
          ),
          const SizedBox(height: 8),
          _buildSettingsCard(),
          const SizedBox(height: 16),
          const _SectionLabel(
            icon: Icons.history_outlined,
            title: 'ACTIVIDAD RECIENTE',
          ),
          const SizedBox(height: 8),
          _ActivityFeed(events: events),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.edit_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text(
              'Editar nombre',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onTap: _showEditNameDialog,
          ),
          const Divider(
            color: AppColors.divider,
            height: 1,
            indent: 56,
            endIndent: 16,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.danger),
            ),
            onTap: () => context.read<AuthViewModel>().signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsContent(GoalsViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        heightFactor: 2,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.rpg),
        ),
      );
    }

    if (vm.goals == null) {
      return const Text(
        'No se pudieron cargar los objetivos.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    final g = vm.goals!;
    return Column(
      children: [
        _GoalRow(
          icon: Icons.nightlight_round,
          color: AppColors.sleep,
          label: 'Dormir',
          value: '${g.sleepHoursTarget.toStringAsFixed(1)} h / noche',
        ),
        const Divider(color: AppColors.divider, height: 20),
        _GoalRow(
          icon: Icons.fitness_center_outlined,
          color: AppColors.habits,
          label: 'Hábitos',
          value: 'mín ${g.minHabitsDaily} / día',
        ),
        const Divider(color: AppColors.divider, height: 20),
        _GoalRow(
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.finance,
          label: 'Gasto máx',
          value: '${g.maxMonthlySpending.toStringAsFixed(0)} € / mes',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showEditGoalsSheet,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Editar objetivos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.rpg,
              side: const BorderSide(color: AppColors.rpg),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Card
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  final ProfileEntity profile;
  final bool isUploading;
  final VoidCallback onAvatarTap;

  const _HeroCard({
    required this.profile,
    required this.isUploading,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = profile.username.isNotEmpty
        ? profile.username.substring(0, 1).toUpperCase()
        : 'H';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: isUploading ? null : onAvatarTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.rpg.withValues(alpha: 0.2),
                        child: profile.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  profile.avatarUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                initial,
                                style: const TextStyle(
                                  color: AppColors.rpg,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      if (isUploading)
                        const SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.rpg),
                          ),
                        ),
                      if (!isUploading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.rpg,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.username,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rpg.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Nivel ${profile.level}',
                          style: const TextStyle(
                            color: AppColors.rpg,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.monetization_on_outlined,
                      color: AppColors.finance,
                      size: 18,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${profile.currentGold.toStringAsFixed(2)} G',
                      style: const TextStyle(
                        color: AppColors.finance,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _BarStat(
              icon: Icons.auto_awesome,
              label: 'XP',
              value: '${profile.currentXp} / ${profile.xpNextLevel}',
              progress: profile.xpProgress,
              color: AppColors.rpg,
            ),
            const SizedBox(height: 12),
            _BarStat(
              icon: Icons.favorite_outline,
              label: 'HP',
              value: '${profile.currentHp} / ${profile.maxHp}',
              progress: profile.hpProgress,
              color: profile.currentHp < profile.maxHp * 0.3
                  ? AppColors.danger
                  : AppColors.habits,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _BarStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _BarStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
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
            backgroundColor: AppColors.divider.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _GoalRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Activity Feed
// ---------------------------------------------------------------------------

class _ActivityFeed extends StatelessWidget {
  final List<RpgEventEntity> events;

  const _ActivityFeed({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Aún no hay actividad registrada.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (_, _) => const Divider(
          color: AppColors.divider,
          height: 1,
          indent: 56,
          endIndent: 16,
        ),
        itemBuilder: (_, i) => _EventTile(event: events[i]),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final RpgEventEntity event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final (icon, color, amountText) = _eventStyle();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (amountText.isNotEmpty)
                  Text(
                    amountText,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(
                  event.description,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeTime(event.createdAt),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _eventStyle() => switch (event.type) {
        RpgEventType.xpGain => (
            Icons.auto_awesome,
            AppColors.rpg,
            '+${event.amount} XP',
          ),
        RpgEventType.xpLoss => (
            Icons.trending_down,
            AppColors.textSecondary,
            '-${event.amount} XP',
          ),
        RpgEventType.hpLoss => (
            Icons.favorite,
            AppColors.danger,
            '-${event.amount} HP',
          ),
        RpgEventType.levelUp => (
            Icons.arrow_upward,
            AppColors.rpg,
            'Nivel ${event.amount}',
          ),
        RpgEventType.gameOver => (
            Icons.sentiment_very_dissatisfied,
            AppColors.danger,
            '',
          ),
      };

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    return 'hace ${diff.inDays} días';
  }
}

// ---------------------------------------------------------------------------
// Edit Goals Bottom Sheet
// ---------------------------------------------------------------------------

class _EditGoalsSheet extends StatefulWidget {
  final UserGoalsEntity goals;
  final Future<void> Function(UserGoalsEntity) onSave;

  const _EditGoalsSheet({required this.goals, required this.onSave});

  @override
  State<_EditGoalsSheet> createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends State<_EditGoalsSheet> {
  late double _sleepHours;
  late int _minHabits;
  late TextEditingController _spendingCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sleepHours = widget.goals.sleepHoursTarget;
    _minHabits = widget.goals.minHabitsDaily;
    _spendingCtrl = TextEditingController(
      text: widget.goals.maxMonthlySpending.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _spendingCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final spending = double.tryParse(_spendingCtrl.text.trim());
    if (spending == null || spending <= 0) return;

    setState(() => _saving = true);
    final updated = widget.goals.copyWith(
      sleepHoursTarget: _sleepHours,
      minHabitsDaily: _minHabits,
      maxMonthlySpending: spending,
    );
    await widget.onSave(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Editar Objetivos',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // Sueño
          Row(
            children: [
              const Icon(
                Icons.nightlight_round,
                color: AppColors.sleep,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Sueño objetivo',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '${_sleepHours.toStringAsFixed(1)} h',
                style: const TextStyle(
                  color: AppColors.sleep,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _sleepHours,
            min: 5.0,
            max: 12.0,
            divisions: 14,
            activeColor: AppColors.sleep,
            inactiveColor: AppColors.divider,
            onChanged: (v) => setState(() => _sleepHours = v),
          ),
          const SizedBox(height: 8),

          // Hábitos
          Row(
            children: [
              const Icon(
                Icons.fitness_center_outlined,
                color: AppColors.habits,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Hábitos mínimos / día',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '$_minHabits',
                style: const TextStyle(
                  color: AppColors.habits,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _minHabits.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: AppColors.habits,
            inactiveColor: AppColors.divider,
            onChanged: (v) => setState(() => _minHabits = v.round()),
          ),
          const SizedBox(height: 8),

          // Gasto máx
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.finance,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Gasto máx mensual (€)',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _spendingCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixText: '€ ',
              prefixStyle: const TextStyle(color: AppColors.finance),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.finance),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Guardar
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.rpg,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
