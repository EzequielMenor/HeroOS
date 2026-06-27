import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as pkg;
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../viewmodels/habits_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';
import '../viewmodels/sleep_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/quick_capture_viewmodel.dart';
import '../viewmodels/shell_controller.dart';

import '../widgets/responsive_shell.dart';
import '../widgets/quick_capture_input.dart'; // QuickCaptureButtons
import '../widgets/liquid_glass_indicator.dart';
import '../widgets/glass_card.dart';
import '../widgets/bento_helpers.dart';
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
    context.read<FinanceViewModel>().loadAll();
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
    final shell = context.watch<ShellController>();
    if (_currentIndex != shell.currentIndex) {
      _currentIndex = shell.currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    }

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
          context.read<ShellController>().setTab(index);
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
    final shell = context.watch<ShellController>();
    return ResponsiveShell(
      child: Row(
        children: [
          Expanded(
            child: IndexedStack(
              index: shell.currentIndex,
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
        child: pkg.GlassContainer(
          height: 60,
          settings: const pkg.LiquidGlassSettings(
            thickness: 40,
            blur: 15,
            refractiveIndex: 0.6,
            lightIntensity: 0.7,
            saturation: 1.2,
          ),
          quality: pkg.GlassQuality.premium,
          useOwnLayer: true,
          shape: const pkg.LiquidRoundedSuperellipse(borderRadius: 28),
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
        );
  }
}

/// Today Overview widget: greeting + bento grid (Sleep / Habits / Tasks / Balance).
class _TodayOverview extends StatelessWidget {
  const _TodayOverview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: pkg.GlassAppBar(
        backgroundColor: Colors.transparent,
        centerTitle: false,
        buttonSettings: const pkg.LiquidGlassSettings(
          thickness: 40,
          blur: 15,
        ),
        title: const Text(
          'Hoy',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GreetingSection(),
            const SizedBox(height: 24),
            const _SleepBentoCard(),
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(child: _HabitsBentoCard()),
                SizedBox(width: 10),
                Expanded(child: _TasksBentoCard()),
              ],
            ),
            const SizedBox(height: 10),
            const _BalanceBentoCard(),
          ],
        ),
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection();

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

void _goToTab(BuildContext context, int index) {
  context.read<ShellController>().setTab(index);
}

String _formatEur(double v) {
  // 358.6 → "358,60 €" (es-ES style, no thousands for sub-10k balances).
  return '${v.toStringAsFixed(2).replaceAll('.', ',')} €';
}

String _formatHours(double hours) {
  final h = hours.floor();
  final m = ((hours - h) * 60).round();
  return '${h}h ${m}m';
}

class _SleepBentoCard extends StatelessWidget {
  const _SleepBentoCard();

  @override
  Widget build(BuildContext context) {
    final sleepVm = context.watch<SleepViewModel>();
    final log = sleepVm.todayLog;
    final rating = log?.qualityRating ?? 0;

    return GlassCard(
      onTap: () => _goToTab(context, 4),
      padding: const EdgeInsets.all(14),
      child: log == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                BentoKicker('FASES DE SUEÑO'),
                SizedBox(height: 10),
                BentoMuted('Sin registro de anoche'),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BentoKicker('FASES DE SUEÑO'),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          size: 13,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    BentoMetric(_formatHours(log.totalHours)),
                    const SizedBox(width: 8),
                    Text(
                      '· ${DateFormat.Hm().format(log.startTime)} – ${DateFormat.Hm().format(log.endTime)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SleepBarTrack(
                  deep: log.deepSleepPct ?? 0,
                  light: log.lightSleepPct ?? 0,
                  rem: log.remSleepPct ?? 0,
                ),
              ],
            ),
    );
  }
}

class _SleepBarTrack extends StatelessWidget {
  final int deep;
  final int light;
  final int rem;
  const _SleepBarTrack({required this.deep, required this.light, required this.rem});

  @override
  Widget build(BuildContext context) {
    final total = deep + light + rem;
    if (total <= 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(5),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            Expanded(flex: deep, child: Container(color: AppColors.habits)),
            const SizedBox(width: 3),
            Expanded(flex: light, child: Container(color: AppColors.gold)),
            const SizedBox(width: 3),
            Expanded(flex: rem, child: Container(color: AppColors.coral)),
          ],
        ),
      ),
    );
  }
}

class _HabitsBentoCard extends StatelessWidget {
  const _HabitsBentoCard();

  @override
  Widget build(BuildContext context) {
    final habitsVm = context.watch<HabitsViewModel>();
    final today = habitsVm.todayHabits;
    final completed = today.where((h) => habitsVm.isCompletedToday(h.id)).length;
    final total = today.length;
    final pct = total > 0 ? completed / total : 0.0;

    return GlassCard(
      onTap: () => _goToTab(context, 2),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const BentoKicker('HÁBITOS'),
          const SizedBox(height: 10),
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 4,
                    backgroundColor: AppColors.divider,
                    color: AppColors.habits,
                  ),
                ),
                Text(
                  '${(pct * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          BentoMuted('$completed de $total completados'),
        ],
      ),
    );
  }
}

class _TasksBentoCard extends StatelessWidget {
  const _TasksBentoCard();

  @override
  Widget build(BuildContext context) {
    final tasksVm = context.watch<TasksViewModel>();
    final pending = tasksVm.pendingTasks;
    final next = pending.isNotEmpty ? pending.first : null;

    return GlassCard(
      onTap: () => _goToTab(context, 1),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const BentoKicker('TAREAS'),
          const SizedBox(height: 6),
          BentoMetric('${pending.length}'),
          const SizedBox(height: 2),
          const BentoMuted('Pendientes'),
          if (next != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Media',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    next.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceBentoCard extends StatelessWidget {
  const _BalanceBentoCard();

  @override
  Widget build(BuildContext context) {
    final financeVm = context.watch<FinanceViewModel>();
    final balance = financeVm.totalBalance;
    final count = financeVm.accounts.length;

    return GlassCard(
      onTap: () => _goToTab(context, 3),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const BentoKicker('BALANCE TOTAL'),
          const SizedBox(height: 6),
          BentoMetric(_formatEur(balance), size: 30),
          const SizedBox(height: 4),
          BentoMuted(
            '$count cuenta${count == 1 ? '' : 's'} activa${count == 1 ? '' : 's'}',
          ),
        ],
      ),
    );
  }
}
