import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/rpg_hud.dart';
import '../viewmodels/stats_viewmodel.dart';
import 'habits_screen.dart';
import 'tasks_screen.dart';
import 'finance_screen.dart';
import 'sleep_screen.dart';
import 'profile_screen.dart';

/// Dashboard con stats RPG y BottomNavigationBar (5 tabs).
/// En web (≥900px) muestra un sidebar lateral en lugar del bottom nav.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  VoidCallback? _statsListener;

  static const List<_TabInfo> _tabs = [
    _TabInfo(
      AppStrings.moduleFinance,
      Icons.account_balance_wallet_outlined,
      AppColors.finance,
    ),
    _TabInfo(AppStrings.moduleHabits, Icons.repeat_outlined, AppColors.habits),
    _TabInfo(AppStrings.moduleSleep, Icons.nightlight_round, AppColors.sleep),
    _TabInfo(AppStrings.moduleTasks, Icons.task_alt_outlined, AppColors.rpg),
    _TabInfo(
      AppStrings.moduleProfile,
      Icons.person_outline,
      AppColors.textSecondary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final statsVm = context.read<StatsViewModel>();
      _statsListener = () => _onStatsChange(statsVm);
      statsVm.addListener(_statsListener!);
      statsVm.loadProfile().then((_) {
        _checkEvents(statsVm);
        _checkWelcome(statsVm);
      });
    });
  }

  @override
  void dispose() {
    if (_statsListener != null) {
      context.read<StatsViewModel>().removeListener(_statsListener!);
    }
    super.dispose();
  }

  void _checkWelcome(StatsViewModel vm) {
    if (!mounted) return;
    if (vm.profile != null && vm.profile!.username == 'Hero') {
      _showWelcomeDialog(vm);
    }
  }

  void _showWelcomeDialog(StatsViewModel vm) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Text('⚔️', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              '¡Bienvenido, héroe!',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Cómo te llamas?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Nombre de héroe',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.scaffold,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.rpg),
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rpg),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.of(context).pop();
              await vm.updateUsername(name);
            },
            child: const Text('Comenzar Aventura'),
          ),
        ],
      ),
    );
  }

  void _checkEvents(StatsViewModel vm) {
    if (!mounted) return;
    if (vm.didLevelUp) _showLevelUpDialog(vm.profile!.level);
    if (vm.isGameOver) _showGameOverDialog();
    vm.clearEvents();
  }

  void _onStatsChange(StatsViewModel vm) {
    if (!mounted) return;
    if (vm.lastXpGain != null) {
      _showXpToast(vm.lastXpGain!);
      vm.clearToast();
    } else if (vm.lastHpLoss != null) {
      _showHpLossToast(vm.lastHpLoss!);
      vm.clearToast();
    }
  }

  void _showXpToast(int xp) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.rpg, size: 18),
              const SizedBox(width: 8),
              Text(
                '+$xp XP',
                style: const TextStyle(
                  color: AppColors.rpg,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          elevation: 6,
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.rpg, width: 1),
          ),
        ),
      );
  }

  void _showHpLossToast(int hp) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.heart_broken_outlined,
                color: AppColors.danger,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '-$hp HP',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          elevation: 6,
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.danger, width: 1),
          ),
        ),
      );
  }

  void _showLevelUpDialog(int newLevel) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.rpg),
            SizedBox(width: 8),
            Text('¡Level Up!', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          '¡Has alcanzado el nivel $newLevel! Tu HP máx ha aumentado.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '¡A por más!',
              style: TextStyle(color: AppColors.rpg),
            ),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.heart_broken_outlined, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Game Over', style: TextStyle(color: AppColors.danger)),
          ],
        ),
        content: const Text(
          'Tu HP cayó a 0. ¡Has vuelto al nivel 1! Cuida mejor tus hábitos.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Intentar de nuevo',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  static const List<Widget> _screens = [
    FinanceScreen(),
    HabitsScreen(),
    SleepScreen(),
    TasksScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final statsVm = context.watch<StatsViewModel>();

    if (context.isWeb) {
      return _buildWebLayout(statsVm);
    }
    return _buildMobileLayout(statsVm);
  }

  // ── WEB LAYOUT ──────────────────────────────────────────────────────────────

  Widget _buildWebLayout(StatsViewModel statsVm) {
    return Scaffold(
      body: Row(
        children: [
          _WebSidebar(
            currentIndex: _currentIndex,
            tabs: _tabs,
            statsVm: statsVm,
            onTabSelected: (i) => setState(() => _currentIndex = i),
          ),
          const VerticalDivider(
            width: 1,
            color: AppColors.divider,
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }

  // ── MOBILE LAYOUT ───────────────────────────────────────────────────────────

  Widget _buildMobileLayout(StatsViewModel statsVm) {
    final tab = _tabs[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(tab.label)),
      body: Column(
        children: [
          // HUD RPG visible en todos los tabs excepto Perfil
          if (_currentIndex != 4)
            if (statsVm.isLoading)
              const LinearProgressIndicator(
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.rpg),
              )
            else if (statsVm.profile != null)
              RpgHud(profile: statsVm.profile!),

          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: _tabs
            .map(
              (t) =>
                  BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
            )
            .toList(),
      ),
    );
  }
}

// ── WEB SIDEBAR ─────────────────────────────────────────────────────────────

class _WebSidebar extends StatelessWidget {
  final int currentIndex;
  final List<_TabInfo> tabs;
  final StatsViewModel statsVm;
  final ValueChanged<int> onTabSelected;

  const _WebSidebar({
    required this.currentIndex,
    required this.tabs,
    required this.statsVm,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Container(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.rpg, width: 2),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: AppColors.rpg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'HeroOS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // RpgHud
            if (statsVm.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.rpg),
                ),
              )
            else if (statsVm.profile != null)
              RpgHud(profile: statsVm.profile!, compact: true),

            const SizedBox(height: 8),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 8),

            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: tabs.length,
                itemBuilder: (_, i) {
                  final tab = tabs[i];
                  final selected = i == currentIndex;
                  return _SidebarNavItem(
                    icon: tab.icon,
                    label: tab.label,
                    color: tab.color,
                    selected: selected,
                    onTap: () => onTabSelected(i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? color.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? color : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? color : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── DATA ────────────────────────────────────────────────────────────────────

class _TabInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _TabInfo(this.label, this.icon, this.color);
}
