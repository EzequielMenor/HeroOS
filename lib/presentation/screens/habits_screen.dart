import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/adaptive_modal.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/habit_entity.dart';
import '../viewmodels/habits_viewmodel.dart';
import '../widgets/habit_heatmap.dart';
import '../widgets/habit_stats_card.dart';

/// Pantalla de Hábitos — toggle entre Lista (checkboxes) y Stats (analytics).
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.habits),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Izquierda: lista de hábitos de hoy
                Expanded(child: _ListView(vm: vm)),
                const VerticalDivider(width: 1, color: AppColors.divider),
                // Derecha: stats
                Expanded(
                  child: _StatsView(
                    vm: vm,
                    selectedHabitId: _selectedHabitId,
                    onHabitSelected: (id) =>
                        setState(() => _selectedHabitId = id),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.habits,
        onPressed: () => _showCreateSheet(context, vm),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── MOBILE: toggle lista / stats ────────────────────────────────────────────

  Widget _buildMobileLayout(HabitsViewModel vm) {
    return Scaffold(
      body: Column(
        children: [
          _ViewToggle(
            showStats: _showStats,
            onToggle: (v) => setState(() => _showStats = v),
          ),
          Expanded(
            child: vm.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.habits),
                  )
                : _showStats
                ? _StatsView(
                    vm: vm,
                    selectedHabitId: _selectedHabitId,
                    onHabitSelected: (id) =>
                        setState(() => _selectedHabitId = id),
                  )
                : _ListView(vm: vm),
          ),
        ],
      ),
      floatingActionButton: _showStats
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.habits,
              onPressed: () => _showCreateSheet(context, vm),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  // ─── Bottom Sheet: Crear hábito ───

  void _showCreateSheet(BuildContext context, HabitsViewModel vm) {
    final titleCtrl = TextEditingController();
    final days = <String>{'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'};
    final selected = <String>{...days};

    showAdaptiveModal<void>(
      context,
      StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nuevo Hábito',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Ej: Beber 2L de agua',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Días activos',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: days.map((d) {
                  final isActive = selected.contains(d);
                  return FilterChip(
                    label: Text(
                      d,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    selected: isActive,
                    selectedColor: AppColors.habits,
                    checkmarkColor: Colors.white,
                    backgroundColor: AppColors.scaffold,
                    onSelected: (v) {
                      setSheetState(() {
                        v ? selected.add(d) : selected.remove(d);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.habits,
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    vm.createHabit(
                      title: title,
                      frequencyMask: selected.join(','),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Crear Hábito'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Toggle Lista / Stats
// ═══════════════════════════════════════════════════════

class _ViewToggle extends StatelessWidget {
  final bool showStats;
  final ValueChanged<bool> onToggle;

  const _ViewToggle({required this.showStats, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _tab(Icons.checklist, 'Lista', !showStats, () => onToggle(false)),
          const SizedBox(width: 8),
          _tab(Icons.insights, 'Stats', showStats, () => onToggle(true)),
        ],
      ),
    );
  }

  Widget _tab(IconData icon, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppColors.habits.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.habits : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? AppColors.habits : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.habits : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Vista Lista (checkboxes — la original)
// ═══════════════════════════════════════════════════════

class _ListView extends StatelessWidget {
  final HabitsViewModel vm;

  const _ListView({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.todayHabits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.self_improvement_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin hábitos para hoy.\n¡Crea tu primer entrenamiento!',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: vm.todayHabits.length,
      itemBuilder: (_, i) => _HabitTile(habit: vm.todayHabits[i], vm: vm),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Vista Stats (analytics dashboard)
// ═══════════════════════════════════════════════════════

class _StatsView extends StatelessWidget {
  final HabitsViewModel vm;
  // null = vista global "Todos"
  final String? selectedHabitId;
  final ValueChanged<String?> onHabitSelected;

  const _StatsView({
    required this.vm,
    required this.selectedHabitId,
    required this.onHabitSelected,
  });

  @override
  Widget build(BuildContext context) {
    final analytics = vm.analytics;
    final habits = vm.habits;

    if (habits.isEmpty) {
      return const Center(
        child: Text(
          'Crea hábitos para ver estadísticas',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    if (analytics == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.habits),
      );
    }

    final showGlobal = selectedHabitId == null;
    final selectedHabit = showGlobal
        ? null
        : (habits.where((h) => h.id == selectedHabitId).firstOrNull ??
            habits.first);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Selector: Todos + hábitos individuales ──
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: habits.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return ChoiceChip(
                    label: Text(
                      'Todos',
                      style: TextStyle(
                        color: showGlobal
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    selected: showGlobal,
                    selectedColor: AppColors.habits,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: showGlobal
                          ? AppColors.habits
                          : AppColors.divider,
                    ),
                    onSelected: (_) => onHabitSelected(null),
                  );
                }
                final h = habits[i - 1];
                final isSelected =
                    !showGlobal && h.id == selectedHabit!.id;
                return ChoiceChip(
                  label: Text(
                    h.title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.habits,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected ? AppColors.habits : AppColors.divider,
                  ),
                  onSelected: (_) => onHabitSelected(h.id),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          if (showGlobal) ...[
            // ─── Vista Global ───
            _GlobalStatsSection(
              overallRate: analytics.overallCompletionRate(),
              habitCount: habits.length,
              perHabitRates: {
                for (final h in habits)
                  h.title: analytics.completionRate(h.id),
              },
              globalTrend: analytics.overallMonthlyTrend(),
            ),
          ] else ...[
            // ─── Vista Individual ───
            HabitStatsCard(
              currentStreak: analytics.currentStreak(selectedHabit!.id),
              bestStreak: analytics.bestStreak(selectedHabit.id),
              completionRate: analytics.completionRate(selectedHabit.id),
            ),
            const SizedBox(height: 20),

            const Text(
              'Actividad (90 días)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: HabitHeatmap(
                  data: analytics.weeklyHeatmap(selectedHabit.id),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Tendencia mensual',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: SizedBox(
                  height: 200,
                  child: _MonthlyTrendChart(
                    data: analytics.monthlyTrend(selectedHabit.id, months: 6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Line Chart — Tendencia mensual (fl_chart)
// ═══════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════
//  Vista Global — stats del conjunto de todos los hábitos
// ═══════════════════════════════════════════════════════

class _GlobalStatsSection extends StatelessWidget {
  final double overallRate;
  final int habitCount;
  final Map<String, double> perHabitRates; // nombre → tasa 0-1
  final Map<String, double> globalTrend;   // 'YYYY-MM' → tasa 0-1

  const _GlobalStatsSection({
    required this.overallRate,
    required this.habitCount,
    required this.perHabitRates,
    required this.globalTrend,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (overallRate * 100).round();
    // Ordenar hábitos de mayor a menor tasa
    final sorted = perHabitRates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Resumen global ──
        Card(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.speed, color: AppColors.habits, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasa global — $habitCount hábitos',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: overallRate,
                          minHeight: 6,
                          backgroundColor: AppColors.divider,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.habits,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Tasa por hábito ──
        const Text(
          'Tasa por hábito (30 días)',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: sorted.map((e) {
                final rate = e.value;
                final p = (rate * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: rate,
                            minHeight: 7,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              rate >= 0.7
                                  ? AppColors.habits
                                  : AppColors.habits.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Tendencia global mensual ──
        const Text(
          'Tendencia global mensual',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: SizedBox(
              height: 200,
              child: _MonthlyTrendChart(data: globalTrend),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Line Chart — Tendencia mensual (fl_chart)
// ═══════════════════════════════════════════════════════

class _MonthlyTrendChart extends StatelessWidget {
  final Map<String, double> data; // {'2026-01': 0.85, ...}

  const _MonthlyTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
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
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}%',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox();
                // Formato: "2026-02" → "Feb"
                final parts = entries[idx].key.split('-');
                final month = int.tryParse(parts.last) ?? 1;
                final label = DateFormat.MMM(
                  'es',
                ).format(DateTime(2026, month));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: const TextStyle(
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
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.habits,
                strokeWidth: 2,
                strokeColor: AppColors.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.habits.withValues(alpha: 0.3),
                  AppColors.habits.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.scaffold,
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(
                '${s.y.round()}%',
                const TextStyle(
                  color: AppColors.habits,
                  fontWeight: FontWeight.bold,
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
//  Habit Tile (lista individual con long press menu)
// ═══════════════════════════════════════════════════════

class _HabitTile extends StatelessWidget {
  final HabitEntity habit;
  final HabitsViewModel vm;

  const _HabitTile({required this.habit, required this.vm});

  @override
  Widget build(BuildContext context) {
    final done = vm.isCompletedToday(habit.id);

    return ListTile(
      leading: IconButton(
        icon: Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done
              ? AppColors.habits
              : AppColors.textSecondary.withValues(alpha: 0.5),
        ),
        onPressed: () {
          if (done) {
            vm.uncompleteHabit(habit);
          } else {
            vm.completeHabit(habit);
          }
        },
      ),
      title: Text(
        habit.title,
        style: TextStyle(
          color: done ? AppColors.textSecondary : AppColors.textPrimary,
          decoration: done ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        habit.currentStreak > 0
            ? '+${habit.xpReward} XP  •  🔥 ${habit.currentStreak} días'
            : '+${habit.xpReward} XP',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      onLongPress: () => _showContextMenu(context),
    );
  }

  void _showContextMenu(BuildContext context) {
    showAdaptiveModal<void>(
      context,
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.habits),
              title: const Text(
                'Editar',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.archive_outlined,
                color: AppColors.textSecondary,
              ),
              title: const Text(
                'Archivar',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                vm.archiveHabit(habit.id);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text(
                'Borrar permanentemente',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Borrar hábito',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '¿Eliminar "${habit.title}" permanentemente?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              vm.deleteHabit(habit.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Borrar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final titleCtrl = TextEditingController(text: habit.title);
    final days = <String>{'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'};
    final selected = habit.frequencyMask.isEmpty
        ? <String>{...days}
        : habit.frequencyMask.split(',').map((d) => d.trim()).toSet();

    showAdaptiveModal<void>(
      context,
      StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Editar Hábito',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Nombre del hábito',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Días activos',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: days.map((d) {
                  final isActive = selected.contains(d);
                  return FilterChip(
                    label: Text(
                      d,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    selected: isActive,
                    selectedColor: AppColors.habits,
                    checkmarkColor: Colors.white,
                    backgroundColor: AppColors.scaffold,
                    onSelected: (v) {
                      setSheetState(() {
                        v ? selected.add(d) : selected.remove(d);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.habits,
                  ),
                  onPressed: () {
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
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
