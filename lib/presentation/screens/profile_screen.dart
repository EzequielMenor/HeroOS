import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/responsive.dart';
import '../../domain/entities/profile_entity.dart';

import '../../core/theme/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/goals_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
Color get _kBg => AppColors.scaffold;
Color get _kTextPrimary => AppColors.textPrimary;
Color get _kTextSecondary => AppColors.textSecondary;
Color get _kDivider => AppColors.divider;
Color get _kAccent => AppColors.accent;
Color get _kDanger => AppColors.danger;

/// Pantalla de Perfil del usuario.
/// Zen OS pivot: RPG stats removed, AI configuration added.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiKeyController = TextEditingController();
  final _endpointController = TextEditingController();
  final _modelController = TextEditingController();

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
      _endpointController.text = prefs.getString('ai_endpoint') ?? '';
      _modelController.text = prefs.getString('ai_model') ?? '';
    });
  }

  Future<void> _saveAiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_api_key', _apiKeyController.text);
    await prefs.setString('ai_endpoint', _endpointController.text);
    await prefs.setString('ai_model', _modelController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuración de IA guardada'),
          backgroundColor: _kAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
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

  // ── Web ───────────────────────────────────────────────────────────────────

  Widget _buildWebLayout(ProfileEntity? profile, GoalsViewModel goalsVm) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(profile),
                    SizedBox(height: 44),
                    _buildSectionLabel('CONFIGURACIÓN IA'),
                    SizedBox(height: 20),
                    _buildAiConfigSection(),
                  ],
                ),
              ),
              SizedBox(width: 80),
              // Right column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('MIS OBJETIVOS'),
                    SizedBox(height: 20),
                    _buildGoalsSection(goalsVm),
                    SizedBox(height: 44),
                    _buildSectionLabel('APARIENCIA'),
                    SizedBox(height: 20),
                    _buildAppearanceToggle(),
                    SizedBox(height: 44),
                    _buildSectionLabel('CUENTA'),
                    SizedBox(height: 20),
                    _buildSignOutButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mobile ────────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(ProfileEntity? profile, GoalsViewModel goalsVm) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(profile),
              SizedBox(height: 44),
              _buildSectionLabel('MIS OBJETIVOS'),
              SizedBox(height: 20),
              _buildGoalsSection(goalsVm),
              SizedBox(height: 44),
              _buildSectionLabel('CONFIGURACIÓN IA'),
              SizedBox(height: 20),
              _buildAiConfigSection(),
              SizedBox(height: 44),
              _buildSectionLabel('APARIENCIA'),
              SizedBox(height: 20),
              _buildAppearanceToggle(),
              SizedBox(height: 44),
              _buildSectionLabel('CUENTA'),
              SizedBox(height: 20),
              _buildSignOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header / username ─────────────────────────────────────────────────────

  Widget _buildHeader(ProfileEntity? profile) {
    final name = profile?.username ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERFIL',
          style: TextStyle(
            color: _kTextSecondary,
            fontSize: 9,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
            height: 1.1,
          ),
        ),
        SizedBox(height: 16),
        Divider(height: 1, thickness: 1, color: _kDivider),
      ],
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: _kTextSecondary,
        fontSize: 9,
        letterSpacing: 2.0,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── AI Config ─────────────────────────────────────────────────────────────

  Widget _buildAiConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('ENDPOINT'),
        SizedBox(height: 8),
        _buildUnderlineInput(
          controller: _endpointController,
          hint: 'Ej: https://api.openai.com/v1/chat/completions',
        ),
        SizedBox(height: 16),
        _buildFieldLabel('MODELO'),
        _buildUnderlineInput(
          controller: _modelController,
          hint: 'Ej: gpt-3.5-turbo, llama-3',
        ),
        SizedBox(height: 16),
        _buildFieldLabel('API KEY'),
        SizedBox(height: 8),
        _buildUnderlineInput(
          controller: _apiKeyController,
          hint: 'sk-…',
          obscureText: true,
        ),
        SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: _saveAiConfig,
            child: Text(
              'GUARDAR',
              style: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ── Appearance Toggle ─────────────────────────────────────────────────────

  Widget _buildAppearanceToggle() {
    return const SizedBox.shrink();
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Widget _buildGoalsSection(GoalsViewModel vm) {
    if (vm.isLoading) {
      return Center(
        heightFactor: 2,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
          strokeWidth: 1.5,
        ),
      );
    }

    if (vm.goals == null) {
      return Text(
        'No se pudieron cargar los objetivos.',
        style: TextStyle(color: _kTextSecondary, fontSize: 13),
      );
    }

    final g = vm.goals!;
    return Column(
      children: [
        _ZenGoalRow(label: 'Sueño', value: '${g.sleepHoursTarget.toStringAsFixed(1)} h / noche'),
        _ZenGoalRow(label: 'Hábitos', value: 'mín ${g.minHabitsDaily} / día'),
        _ZenGoalRow(
          label: 'Gasto máximo',
          value: '${g.maxMonthlySpending.toStringAsFixed(0)} € / mes',
          isLast: true,
        ),
      ],
    );
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: () => context.read<AuthViewModel>().signOut(),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: _kDivider),
            bottom: BorderSide(color: _kDivider),
          ),
        ),
        child: Row(
          children: [
            Text(
              'CERRAR SESIÓN',
              style: TextStyle(
                color: _kDanger,
                fontSize: 10,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward, color: _kDanger, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: _kTextSecondary,
        fontSize: 9,
        letterSpacing: 2.0,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildUnderlineInput({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: _kTextPrimary, fontSize: 14),
      cursorColor: _kAccent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _kTextSecondary, fontSize: 13),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _kDivider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _kAccent),
        ),
        contentPadding: EdgeInsets.only(bottom: 8),
      ),
    );
  }
}

// ─── Goal row ─────────────────────────────────────────────────────────────────

class _ZenGoalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _ZenGoalRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _kDivider),
          bottom: isLast ? BorderSide(color: _kDivider) : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(color: _kAccent, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
