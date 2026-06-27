import 'package:flutter/material.dart';
import '../widgets/zen_glass.dart';
import '../widgets/glass_sheet.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/adaptive_modal.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/habit_analytics.dart';
import '../viewmodels/habits_viewmodel.dart';
import '../widgets/bento_helpers.dart';
import '../widgets/glass_card.dart';
import '../widgets/habit_heatmap.dart';
import '../widgets/habit_stats_card.dart';

/// Pantalla de Rituales — toggle entre Lista (checkboxes) y Stats (analytics).
/// Diseño Zen OS: flat, fondo negro, acento sage green.
/// El botón de añadir está en el header (no FAB propio — el Dashboard gestiona los FABs globales).
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  bool _showStats = false;
  String? _selectedHabitId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitsViewModel>().loadHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HabitsViewModel>();

    if (context.isWeb) {
      return _buildWebLayout(vm);
    }
    return _buildMobileLayout(vm);
  }

  // ── WEB: lista + stats en paralelo ─────────────────────────────────────────

  Widget _buildWebLayout(HabitsViewModel vm) {
    return Scaffold(
      body: vm.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.habits,
                strokeWidth: 1,
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ListView(
                    vm: vm,
                    onAdd: () => showHabitCreateSheet(context, vm),
                  ),
                ),
                Container(width: 1, color: AppColors.divider),
                Expanded(
                  child: _StatsView(
                    selectedHabitId: _selectedHabitId,
                    onHabitSelected: (id) =>
                        setState(() => _selectedHabitId = id),
                  ),
                ),
              ],
            ),
    );
  }

  // ── MOBILE: toggle lista / stats ────────────────────────────────────────────

  Widget _buildMobileLayout(HabitsViewModel vm) {
    final today = DateFormat('EEEE, d MMM', 'es').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header compartido ──
            ZenGlass(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label superior: fecha uppercase
                    Text(
                      today.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 6),
                    // Título grande + botón añadir en la misma fila
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Hábitos',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.0,
                          ),
                        ),
                        Spacer(),
                        // Botón + en el header (no FAB)
                        GestureDetector(
                          onTap: () => showHabitCreateSheet(context, vm),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // Barra de progreso: 1px justo bajo el título
                    if (!_showStats) ...[
                      SizedBox(height: 8),
                      _DayProgressBar(vm: vm),
                    ],
                    SizedBox(height: 18),
                    // Toggle lista/stats
                    _ViewToggle(
                      showStats: _showStats,
                      onToggle: (v) => setState(() => _showStats = v),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            // Divisor ultra fino
            Container(height: 1, color: AppColors.divider),
            // Contenido
            Expanded(
              child: vm.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.habits,
                        strokeWidth: 1,
                      ),
                    )
                  : _showStats
                  ? _StatsView(
                      selectedHabitId: _selectedHabitId,
                      onHabitSelected: (id) =>
                          setState(() => _selectedHabitId = id),
                    )
                  : _ListView(
                      vm: vm,
                      onAdd: () => showHabitCreateSheet(context, vm),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Sheet: Crear hábito ───
}

// ═══════════════════════════════════════════════════════
//  Barra de progreso del día — 1px, justo bajo el título
// ═══════════════════════════════════════════════════════

class _DayProgressBar extends StatelessWidget {
  final HabitsViewModel vm;

  const _DayProgressBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    final total = vm.todayHabits.length;
    final done = vm.todayHabits.where((h) => vm.isCompletedToday(h.id)).length;
    final progress = total == 0 ? 0.0 : done / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(height: 1, color: Color(0x12FFFFFF)),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(height: 1, color: AppColors.habits),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          '$done / $total completados',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Toggle Lista / Stats — filtros uppercase, línea activa
// ═══════════════════════════════════════════════════════

class _ViewToggle extends StatelessWidget {
  final bool showStats;
  final ValueChanged<bool> onToggle;

  const _ViewToggle({required this.showStats, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tab('RITUALES', !showStats, () => onToggle(false)),
        SizedBox(width: 20),
        _tab('ESTADÍSTICAS', showStats, () => onToggle(true)),
      ],
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 3),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: 1.5,
            width: active ? (label.length * 6.5).clamp(0.0, 120.0) : 0,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Vista Lista
// ═══════════════════════════════════════════════════════

class _ListView extends StatelessWidget {
  final HabitsViewModel vm;
  final VoidCallback? onAdd;

  const _ListView({required this.vm, this.onAdd});

  @override
  Widget build(BuildContext context) {
    if (vm.todayHabits.isEmpty) {
      return Center(
        child: Text(
          'Aún no hay hábitos',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'HOY',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _HabitTile(habit: vm.todayHabits[i], vm: vm),
            childCount: vm.todayHabits.length,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Vista Stats
// ═══════════════════════════════════════════════════════

class _StatsView extends StatelessWidget {
  final String? selectedHabitId;
  final ValueChanged<String?> onHabitSelected;

  const _StatsView({
    required this.selectedHabitId,
    required this.onHabitSelected,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HabitsViewModel>();
    final analytics = vm.analytics;
    final habits = vm.habits;

    if (habits.isEmpty) {
      return Center(
        child: Text(
          'Aún no hay hábitos',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    if (analytics == null) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.habits,
          strokeWidth: 1,
        ),
      );
    }

    final showGlobal = selectedHabitId == null;
    final selectedHabit = showGlobal
        ? null
        : (habits.where((h) => h.id == selectedHabitId).firstOrNull ??
              habits.first);

    return CustomScrollView(
      slivers: [
        // Selector de filtro
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FILTRAR POR RITUAL',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: habits.length + 1,
                    separatorBuilder: (_, _) => SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _ZenChip(
                          label: 'Todos',
                          active: showGlobal,
                          onTap: () => onHabitSelected(null),
                        );
                      }
                      final h = habits[i - 1];
                      final isSelected =
                          !showGlobal && h.id == selectedHabit!.id;
                      return _ZenChip(
                        label: h.title,
                        active: isSelected,
                        onTap: () => onHabitSelected(h.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 16),
            child: Divider(height: 1, thickness: 1, color: AppColors.divider),
          ),
        ),

        if (showGlobal) ...[
          SliverToBoxAdapter(
            child: _GlobalStatsSection(analytics: analytics, habits: habits),
          ),
        ] else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HabitStatsCard(
                    currentStreak: analytics.currentStreak(selectedHabit!.id),
                    bestStreak: analytics.bestStreak(selectedHabit.id),
                    completionRate: analytics.completionRate(selectedHabit.id),
                  ),
                  SizedBox(height: 28),
                  Text(
                    'ACTIVIDAD — 90 DÍAS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12),
                  HabitHeatmap(data: analytics.weeklyHeatmap(selectedHabit.id)),
                  SizedBox(height: 28),
                  Text(
                    'TENDENCIA MENSUAL',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: _MonthlyTrendChart(
                      data: analytics.monthlyTrend(selectedHabit.id, months: 6),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Chip Zen — borde fino, sin relleno
// ═══════════════════════════════════════════════════════

class _ZenChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ZenChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.habits.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.habits.withValues(alpha: 0.5) : AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.habits : AppColors.textSecondary,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Vista Global
// ═══════════════════════════════════════════════════════

class _GlobalStatsSection extends StatelessWidget {
  final HabitAnalytics analytics;
  final List<HabitEntity> habits;

  const _GlobalStatsSection({required this.analytics, required this.habits});

  @override
  Widget build(BuildContext context) {
    final pct = (analytics.overallCompletionRate() * 100).round();
    final perHabitRates = <String, double>{
      for (final h in habits) h.title: analytics.completionRate(h.id),
    };
    final sorted = perHabitRates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final globalTrend = analytics.overallMonthlyTrend();

    // Aggregate streak stats across all habits for the prototype's chips.
    int bestCurrent = 0;
    int bestEver = 0;
    for (final h in habits) {
      final c = analytics.currentStreak(h.id);
      final b = analytics.bestStreak(h.id);
      if (c > bestCurrent) bestCurrent = c;
      if (b > bestEver) bestEver = b;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          // ── Card 1: Resumen de estadísticas (match prototipo HTML) ──
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BentoKicker('ESTADÍSTICAS'),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$pct',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'serif',
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                      TextSpan(
                        text: '%',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const BentoMuted('Tasa de éxito semanal'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatChip('Racha: $bestCurrent días'),
                    StatChip('Mejor: $bestEver'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Card 2: Tasa por ritual (30 días) ──
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BentoKicker('TASA POR RITUAL — 30 DÍAS'),
                const SizedBox(height: 12),
                ...sorted.map((e) {
                  final rate = e.value;
                  final p = (rate * 100).round();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: rate,
                              minHeight: 3,
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                rate >= 0.7
                                    ? AppColors.habits
                                    : AppColors.habits.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '$p%',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Card 3: Tendencia global mensual ──
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BentoKicker('TENDENCIA GLOBAL MENSUAL'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: _MonthlyTrendChart(data: globalTrend),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Line Chart — Tendencia mensual (fl_chart)
// ═══════════════════════════════════════════════════════

class _MonthlyTrendChart extends StatelessWidget {
  final Map<String, double> data;

  const _MonthlyTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Sin datos suficientes',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final entries = data.entries.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value * 100));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.divider, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}%',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) return SizedBox();
                final parts = entries[idx].key.split('-');
                final month = int.tryParse(parts.last) ?? 1;
                final label = DateFormat.MMM(
                  'es',
                ).format(DateTime(2026, month));
                return Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.habits,
            barWidth: 1.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.habits,
                strokeWidth: 1.5,
                strokeColor: AppColors.scaffold,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.habits.withValues(alpha: 0.12),
                  AppColors.habits.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(
                '${s.y.round()}%',
                TextStyle(
                  color: AppColors.habits,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Habit Tile — plano, borde inferior, círculo check Zen
// ═══════════════════════════════════════════════════════

class _HabitTile extends StatelessWidget {
  final HabitEntity habit;
  final HabitsViewModel vm;

  const _HabitTile({required this.habit, required this.vm});

  @override
  Widget build(BuildContext context) {
    final done = vm.isCompletedToday(habit.id);
    final streak = habit.currentStreak;
    final streakColor = streak >= 7
        ? AppColors.habits
        : AppColors.textSecondary;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: ZenGlass(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // ── Círculo check ──
            GestureDetector(
              onTap: () {
                if (done) {
                  vm.uncompleteHabit(habit);
                } else {
                  vm.completeHabit(habit);
                }
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done
                        ? AppColors.habits
                        : Color(0x40F0EDE8), // dim blanco
                    width: 1.5,
                  ),
                  color: Colors.transparent,
                ),
                child: done
                    ? Icon(Icons.check, size: 13, color: AppColors.habits)
                    : null,
              ),
            ),
            SizedBox(width: 16),

            // ── Título ──
            Expanded(
              child: Text(
                habit.title,
                style: TextStyle(
                  color: done ? AppColors.textSecondary : AppColors.textPrimary,
                  fontSize: 15,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
            ),

            SizedBox(width: 12),

            // ── Racha ──
            if (streak > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$streak',
                    style: TextStyle(
                      color: streakColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text('d', style: TextStyle(color: streakColor, fontSize: 11)),
                ],
              )
            else
              Text(
                '—',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showAdaptiveModal<void>(
      context,
      GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre del hábito como subtítulo
              Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    habit.title.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
              Divider(height: 1, thickness: 1, color: AppColors.divider),
              _ContextMenuItem(
                label: 'Editar',
                icon: Icons.edit_outlined,
                color: AppColors.textPrimary,
                onTap: () {
                  Navigator.pop(context);
                  _showEditSheet(context);
                },
              ),
              Divider(height: 1, thickness: 1, color: AppColors.divider),
              _ContextMenuItem(
                label: 'Archivar',
                icon: Icons.archive_outlined,
                color: AppColors.textSecondary,
                onTap: () {
                  Navigator.pop(context);
                  vm.archiveHabit(habit.id);
                },
              ),
              Divider(height: 1, thickness: 1, color: AppColors.divider),
              _ContextMenuItem(
                label: 'Borrar permanentemente',
                icon: Icons.delete_outline,
                color: AppColors.danger,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'Borrar ritual',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '¿Eliminar "${habit.title}" permanentemente?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCELAR',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              vm.deleteHabit(habit.id);
              Navigator.pop(context);
            },
            child: Text(
              'BORRAR',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final titleCtrl = TextEditingController(text: habit.title);
    const days = <String>{'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'};
    final selected = habit.frequencyMask.isEmpty
        ? <String>{...days}
        : habit.frequencyMask.split(',').map((d) => d.trim()).toSet();

    const dayLabels = {
      'Mon': 'LUN',
      'Tue': 'MAR',
      'Wed': 'MIÉ',
      'Thu': 'JUE',
      'Fri': 'VIE',
      'Sat': 'SÁB',
      'Sun': 'DOM',
    };

    showAdaptiveModal<void>(
      context,
      StatefulBuilder(
        builder: (ctx, setSheetState) => GlassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar ritual',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 20),
              ZenGlass(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  cursorColor: AppColors.habits,
                  decoration: InputDecoration(
                    hintText: 'Nombre del hábito',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'DÍAS ACTIVOS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: days.map((d) {
                  final isActive = selected.contains(d);
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        isActive ? selected.remove(d) : selected.add(d);
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isActive
                              ? AppColors.habits
                              : AppColors.divider,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        dayLabels[d] ?? d,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.habits
                              : AppColors.textSecondary,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 28),
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    child: Text(
                      'CANCELAR',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Spacer(),
                  InkWell(
                    onTap: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      vm.updateHabit(
                        habit.copyWith(
                          title: title,
                          frequencyMask: selected.join(','),
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'GUARDAR',
                      style: TextStyle(
                        color: AppColors.scaffold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Ítem de menú contextual
// ═══════════════════════════════════════════════════════

class _ContextMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ContextMenuItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 16),
            Text(label, style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

void showHabitCreateSheet(BuildContext context, HabitsViewModel vm) {
  final titleCtrl = TextEditingController();
  const days = <String>{'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'};
  final selected = <String>{...days};

  showAdaptiveModal<void>(
    context,
    StatefulBuilder(
      builder: (ctx, setSheetState) => GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del sheet
            Text(
              'Nuevo ritual',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 20),
            // Campo texto
            ZenGlass(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: titleCtrl,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                cursorColor: AppColors.habits,
                decoration: InputDecoration(
                  hintText: 'Ej: Beber 2L de agua',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 24),
            // Label días
            Text(
              'DÍAS ACTIVOS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: days.map((d) {
                final isActive = selected.contains(d);
                return GestureDetector(
                  onTap: () {
                    setSheetState(() {
                      isActive ? selected.remove(d) : selected.add(d);
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isActive ? AppColors.habits : AppColors.divider,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      dayLabel(d),
                      style: TextStyle(
                        color: isActive
                            ? AppColors.habits
                            : AppColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 28),
            // Botones: Cancel + Add
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(ctx),
                  child: Text(
                    'CANCELAR',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Spacer(),
                InkWell(
                  onTap: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    vm.createHabit(
                      title: title,
                      frequencyMask: selected.join(','),
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'CREAR',
                    style: TextStyle(
                      color: AppColors.scaffold,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

String dayLabel(String d) {
  const map = {
    'Mon': 'LUN',
    'Tue': 'MAR',
    'Wed': 'MIÉ',
    'Thu': 'JUE',
    'Fri': 'VIE',
    'Sat': 'SÁB',
    'Sun': 'DOM',
  };
  return map[d] ?? d;
}
