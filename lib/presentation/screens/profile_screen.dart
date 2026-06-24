import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/profile_entity.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/goals_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';

/// Pantalla de Perfil del usuario.
/// Zen OS pivot: RPG stats removed, AI configuration added.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiKeyController = TextEditingController();
  String _selectedProvider = 'openai';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GoalsViewModel>().loadGoals();
        _loadAiConfig();
      }
    });
  }

  Future<void> _loadAiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('ai_api_key') ?? '';
      _selectedProvider = prefs.getString('ai_provider') ?? 'openai';
    });
  }

  Future<void> _saveAiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_api_key', _apiKeyController.text);
    await prefs.setString('ai_provider', _selectedProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración de IA guardada'),
          backgroundColor: AppColors.habits,
        ),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsVm = context.watch<GoalsViewModel>();
    final profileVm = context.watch<ProfileViewModel>();
    final profile = profileVm.profile;

    if (context.isWeb) {
      return _buildWebLayout(profile, goalsVm);
    }
    return _buildMobileLayout(profile, goalsVm);
  }

  Widget _buildWebLayout(ProfileEntity? profile, GoalsViewModel goalsVm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (profile != null) _buildProfileCard(profile),
                    const SizedBox(height: 16),
                    const _SectionLabel(
                      icon: Icons.settings_outlined,
                      title: 'CONFIGURACIÓN',
                    ),
                    const SizedBox(height: 8),
                    _buildSettingsCard(),
                    const SizedBox(height: 16),
                    _buildAiConfigCard(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
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
        ],
      ),
    );
  }

  Widget _buildMobileLayout(ProfileEntity? profile, GoalsViewModel goalsVm) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (profile != null) _buildProfileCard(profile),
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
              icon: Icons.smart_toy_outlined,
              title: 'CONFIGURACIÓN IA',
            ),
            const SizedBox(height: 8),
            _buildAiConfigCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ProfileEntity profile) {
    final initial = profile.username.isNotEmpty
        ? profile.username.substring(0, 1).toUpperCase()
        : 'U';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.habits.withValues(alpha: 0.2),
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
                            color: AppColors.habits,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
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
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Column(
        children: [
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

  Widget _buildAiConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proveedor de IA',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedProvider,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
              ],
              onChanged: (v) => setState(() => _selectedProvider = v ?? 'openai'),
            ),
            const SizedBox(height: 16),
            const Text(
              'API Key',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Introduce tu API key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveAiConfig,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.habits,
                ),
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsContent(GoalsViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        heightFactor: 2,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.habits),
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
