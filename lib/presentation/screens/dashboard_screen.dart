import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/task_entity.dart';
import '../viewmodels/habits_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';
import '../viewmodels/sleep_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/quick_capture_viewmodel.dart';

import '../widgets/quick_capture_input.dart';
import 'habits_screen.dart';
import 'tasks_screen.dart';
import 'finance_screen.dart';
import 'sleep_screen.dart';
import 'profile_screen.dart';
import 'notes_screen.dart';

/// Dashboard con BottomNavigationBar (6 tabs).
/// Zen OS pivot: Today Overview + Notes module + Quick Capture.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late final QuickCaptureViewModel _qcVm;

  @override
  void initState() {
    super.initState();
    // ponytail: context.read<>() not safe in initState (InheritedWidgets unmounted).
    // Defer to post-frame so Provider tree is ready. Type `dynamic` is banned by Provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _qcVm = QuickCaptureViewModel();
      _loadData();
    });
  }

  void _loadData() {
    context.read<HabitsViewModel>().loadHabits();
    context.read<TasksViewModel>().loadTasks();
    context.read<SleepViewModel>().loadLogs();
    context.read<ProfileViewModel>().loadProfile();
  }

  @override
  void dispose() {
    _qcVm.dispose();
    super.dispose();
  }

  static const List<_TabInfo> _tabs = [
    _TabInfo(AppStrings.moduleFinance, Icons.account_balance_wallet_outlined, AppColors.finance),
    _TabInfo(AppStrings.moduleHabits, Icons.repeat_outlined, AppColors.habits),
    _TabInfo('Hoy', Icons.today_outlined, AppColors.sageGreen),
    _TabInfo(AppStrings.moduleSleep, Icons.nightlight_round, AppColors.sleep),
    _TabInfo(AppStrings.moduleTasks, Icons.task_alt_outlined, AppColors.habits),
    _TabInfo(AppStrings.moduleNotes, Icons.note_alt_outlined, AppColors.sageGreen),
    _TabInfo(AppStrings.moduleProfile, Icons.person_outline, AppColors.textSecondary),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (context.isWeb && MediaQuery.of(context).size.width >= 900) {
      return _buildWebLayout();
    }
    return _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          FinanceScreen(),
          HabitsScreen(),
          _TodayOverview(),
          SleepScreen(),
          TasksScreen(),
          NotesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: AppColors.surface,
        indicatorColor: _tabs[_currentIndex].color.withValues(alpha: 0.2),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon, color: AppColors.textSecondary),
                  selectedIcon: Icon(t.icon, color: t.color),
                  label: t.label,
                ))
            .toList(),
      ),
      floatingActionButton: _currentIndex == 2 ? _buildQuickCapture() : null,
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            backgroundColor: AppColors.surface,
            indicatorColor: _tabs[_currentIndex].color.withValues(alpha: 0.2),
            labelType: NavigationRailLabelType.all,
            destinations: _tabs
                .map((t) => NavigationRailDestination(
                      icon: Icon(t.icon, color: AppColors.textSecondary),
                      selectedIcon: Icon(t.icon, color: t.color),
                      label: Text(t.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: AppColors.divider),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                FinanceScreen(),
                HabitsScreen(),
                _TodayOverview(),
                SleepScreen(),
                TasksScreen(),
                NotesScreen(),
                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 2 ? _buildQuickCapture() : null,
    );
  }

  Widget _buildQuickCapture() {
    return ChangeNotifierProvider.value(
      value: _qcVm,
      child: Consumer<QuickCaptureViewModel>(
        builder: (ctx, vm, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (vm.lastResult != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: AppColors.sageGreen,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
              vm.lastResult ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
                    ),
                  ),
                ),
              if (vm.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageGreen),
                  ),
                ),
              QuickCaptureInput(
                onSubmit: (text) => vm.capture(text),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _TabInfo(this.label, this.icon, this.color);
}

/// Today Overview widget: greeting, habits %, top tasks, sleep quality.
class _TodayOverview extends StatelessWidget {
  const _TodayOverview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Hoy', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingSection(),
            const SizedBox(height: 24),
            _HabitsProgressSection(),
            const SizedBox(height: 24),
            _TopTasksSection(),
            const SizedBox(height: 24),
            _SleepQualitySection(),
          ],
        ),
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewModel>();
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Buenos días' : hour < 18 ? 'Buenas tardes' : 'Buenas noches';
    final name = profileVm.profile?.username ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting${name.isNotEmpty ? ", $name" : ""}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _HabitsProgressSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final habitsVm = context.watch<HabitsViewModel>();
    final todayHabits = habitsVm.todayHabits;
    final completed = todayHabits.where((h) => habitsVm.isCompletedToday(h.id)).length;
    final total = todayHabits.length;
    final pct = total > 0 ? completed / total : 0.0;

    return _OverviewCard(
      title: 'Hábitos de hoy',
      icon: Icons.repeat,
      iconColor: AppColors.habits,
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 8,
                  backgroundColor: AppColors.divider,
                  color: AppColors.sageGreen,
                ),
                Text(
                  '${(pct * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                  '$completed de $total completados',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                if (total == 0)
                  const Text(
                    'No hay hábitos programados',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTasksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasksVm = context.watch<TasksViewModel>();
    final urgent = tasksVm.pendingTasks.take(3).toList();

    return _OverviewCard(
      title: 'Tareas urgentes',
      icon: Icons.task_alt,
      iconColor: AppColors.danger,
      child: urgent.isEmpty
          ? const Text(
              'Sin tareas pendientes',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          : Column(
              children: urgent.map((t) => _TaskRow(task: t)).toList(),
            ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskEntity task;
  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final energyColors = [AppColors.habits, Colors.orange, AppColors.danger];
    final energyLabels = ['Baja', 'Media', 'Alta'];
    final energyIdx = task.energy?.index ?? 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: task.isDone ? AppColors.sageGreen : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                color: AppColors.textPrimary,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: energyColors[energyIdx].withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              energyLabels[energyIdx],
              style: TextStyle(color: energyColors[energyIdx], fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepQualitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sleepVm = context.watch<SleepViewModel>();
    final todayLog = sleepVm.todayLog;

    return _OverviewCard(
      title: 'Calidad del sueño',
      icon: Icons.nightlight_round,
      iconColor: AppColors.sleep,
      child: todayLog == null
          ? const Text(
              'Sin datos de sueño hoy',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${todayLog.totalHours.toStringAsFixed(1)} horas',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SleepPill('Profundo', todayLog.deepSleepPct ?? 0),
                    const SizedBox(width: 8),
                    _SleepPill('Ligero', todayLog.lightSleepPct ?? 0),
                    const SizedBox(width: 8),
                    _SleepPill('REM', todayLog.remSleepPct ?? 0),
                  ],
                ),
                if (todayLog.qualityRating != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < todayLog.qualityRating! ? Icons.star : Icons.star_border,
                        size: 16,
                        color: AppColors.sleep,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SleepPill extends StatelessWidget {
  final String label;
  final int pct;
  const _SleepPill(this.label, this.pct);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sleep.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label $pct%',
        style: const TextStyle(color: AppColors.sleep, fontSize: 11),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _OverviewCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
