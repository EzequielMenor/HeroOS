import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/task_entity.dart';
import '../viewmodels/habits_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';
import '../viewmodels/sleep_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/quick_capture_viewmodel.dart';

import '../widgets/quick_capture_input.dart'; // QuickCaptureButtons
import '../widgets/liquid_glass_indicator.dart';
import 'habits_screen.dart';
import 'tasks_screen.dart';
import 'finance_screen.dart';
import 'sleep_screen.dart';
import 'profile_screen.dart';
import 'notes_screen.dart';
import 'global_add_screen.dart';

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
  late final PageController _pageController;
  late final ValueNotifier<double> _pageOffsetNotifier;

  @override
  void initState() {
    super.initState();
    _qcVm = QuickCaptureViewModel();
    _pageController = PageController(initialPage: _currentIndex);
    _pageOffsetNotifier = ValueNotifier<double>(_currentIndex.toDouble());

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        try {
          final position = _pageController.position;
          // Verificamos que ya existan dimensiones de viewport válidas
          if (position.hasPixels && position.viewportDimension > 0) {
            final double calculatedPage = _pageController.offset / position.viewportDimension;
            // Limitamos el rango de manera segura
            _pageOffsetNotifier.value = calculatedPage.clamp(0.0, (_tabs.length - 1).toDouble());
          }
        } catch (e) {
          // Captura silenciosa para evitar bloquear el hilo de gestos en rebuilds rápidos
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    _pageController.dispose();
    _pageOffsetNotifier.dispose();
    _qcVm.dispose();
    super.dispose();
  }

  // Note: Zen OS uses text-only navigation on mobile, but icons are kept for web rail if needed.
  static final List<_TabInfo> _tabs = [
    _TabInfo('Hoy', 'HOY', Icons.today_outlined, AppColors.habits),
    _TabInfo('Misiones', 'MIS', Icons.task_alt_outlined, AppColors.habits),
    _TabInfo('Hábitos', 'HÁB', Icons.repeat_outlined, AppColors.habits),
    _TabInfo('Finanzas', 'FIN', Icons.account_balance_wallet_outlined, AppColors.finance),
    _TabInfo('Descanso', 'DES', Icons.nightlight_round, AppColors.sleep),
    _TabInfo('Notas', 'NOT', Icons.note_alt_outlined, AppColors.habits),
    _TabInfo('Perfil', 'PER', Icons.person_outline, AppColors.textPrimary),
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
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _TodayOverview(),
          TasksScreen(),
          HabitsScreen(),
          FinanceScreen(),
          SleepScreen(),
          NotesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _LiquidNavBar(
        pageController: _pageController,
        pageOffsetNotifier: _pageOffsetNotifier,
        currentIndex: _currentIndex,
        tabs: _tabs,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
        },
      ),
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
          VerticalDivider(thickness: 1, width: 1, color: AppColors.divider),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _TodayOverview(),
                TasksScreen(),
                HabitsScreen(),
                FinanceScreen(),
                SleepScreen(),
                NotesScreen(),
                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildQuickCapture(),
    );
  }

  Widget _buildQuickCapture() {
    return ChangeNotifierProvider.value(
      value: _qcVm,
      child: Consumer<QuickCaptureViewModel>(
        builder: (ctx, vm, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Result toast
              if (vm.lastResult != null)
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    vm.lastResult ?? '',
                    style: TextStyle(
                      color: AppColors.habits,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              if (vm.isLoading)
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.habits,
                    ),
                  ),
                ),
              QuickCaptureButtons(qcVm: _qcVm),
            ],
          );
        },
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
  _TabInfo(this.label, this.shortLabel, this.icon, this.color);
}

class _LiquidNavBar extends StatelessWidget {
  final PageController pageController;
  final ValueNotifier<double> pageOffsetNotifier;
  final int currentIndex;
  final List<_TabInfo> tabs;
  final ValueChanged<int> onTap;

  const _LiquidNavBar({
    required this.pageController,
    required this.pageOffsetNotifier,
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.scaffold.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // El botón de "+" ocupa un ancho fijo a la derecha
                  const double addButtonWidth = 56.0;
                  final double barWidth = constraints.maxWidth - addButtonWidth - 8.0 - 1.0 - 8.0;
                  final double tabWidth = barWidth / tabs.length;
                  const double navHeight = 44.0;

                  return Row(
                    children: [
                      // Área interactiva de arrastre de pestañas
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          final localX = details.localPosition.dx;
                          final index = (localX / tabWidth).floor().clamp(0, tabs.length - 1);
                          onTap(index);
                        },
                        onHorizontalDragStart: (details) {
                          final localX = details.localPosition.dx;
                          final double pageValue = (localX / tabWidth) - 0.5;
                          final double clampedPage = pageValue.clamp(0.0, (tabs.length - 1).toDouble());
                          if (pageController.hasClients) {
                            final position = pageController.position;
                            pageController.jumpTo(clampedPage * position.viewportDimension);
                          }
                        },
                        onHorizontalDragUpdate: (details) {
                          final localX = details.localPosition.dx;
                          final double pageValue = (localX / tabWidth) - 0.5;
                          final double clampedPage = pageValue.clamp(0.0, (tabs.length - 1).toDouble());
                          if (pageController.hasClients) {
                            final position = pageController.position;
                            pageController.jumpTo(clampedPage * position.viewportDimension);
                          }
                        },
                        onHorizontalDragEnd: (details) {
                          final nearestPage = pageOffsetNotifier.value.round();
                          pageController.animateToPage(
                            nearestPage,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: SizedBox(
                          height: navHeight,
                          width: barWidth,
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              // Indicador de cristal líquido
                              ValueListenableBuilder<double>(
                                valueListenable: pageOffsetNotifier,
                                builder: (context, offset, _) {
                                  return LiquidGlassIndicator(
                                    pageOffset: offset,
                                    tabWidth: tabWidth,
                                    height: navHeight,
                                  );
                                },
                              ),
                              // Fila de etiquetas de texto abreviadas (sin scroll)
                              Row(
                                children: List.generate(tabs.length, (index) {
                                  final isSelected = currentIndex == index;
                                  final tab = tabs[index];
                                  return SizedBox(
                                    width: tabWidth,
                                    child: Center(
                                      child: Text(
                                        tab.shortLabel,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: isSelected
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: AppColors.divider,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      // Botón de captura rápida
                      SizedBox(
                        width: addButtonWidth,
                        child: IconButton(
                          icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 28),
                          padding: EdgeInsets.zero,
                          onPressed: () => showGlobalAdd(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Today Overview widget: greeting, habits %, top tasks, sleep quality.
class _TodayOverview extends StatelessWidget {
  const _TodayOverview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Hoy', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingSection(),
            SizedBox(height: 24),
            _HabitsProgressSection(),
            SizedBox(height: 24),
            _TopTasksSection(),
            SizedBox(height: 24),
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
          DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()).toUpperCase(),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '$greeting${name.isNotEmpty ? ",\n$name" : ""}',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 42,
            height: 1.02,
            letterSpacing: -0.5,
          ),
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
                  color: AppColors.habits,
                ),
                Text(
                  '${(pct * 100).toInt()}%',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completed de $total completados',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                if (total == 0)
                  Text(
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
          ? Text(
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
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: task.isDone ? AppColors.habits : AppColors.textSecondary,
          ),
          SizedBox(width: 8),
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
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          ? Text(
              'Sin datos de sueño hoy',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${todayLog.totalHours.toStringAsFixed(1)} horas',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _SleepPill('Profundo', todayLog.deepSleepPct ?? 0),
                    SizedBox(width: 8),
                    _SleepPill('Ligero', todayLog.lightSleepPct ?? 0),
                    SizedBox(width: 8),
                    _SleepPill('REM', todayLog.remSleepPct ?? 0),
                  ],
                ),
                if (todayLog.qualityRating != null) ...[
                  SizedBox(height: 8),
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sleep.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label $pct%',
        style: TextStyle(color: AppColors.sleep, fontSize: 11),
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
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
