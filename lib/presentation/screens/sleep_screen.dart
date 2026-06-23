import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/adaptive_modal.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/openrouter_service.dart';
import '../../domain/entities/sleep_log_entity.dart';
import '../../domain/services/sleep_diagnosis_service.dart';
import '../viewmodels/sleep_viewmodel.dart';

/// Pantalla de Sueño — toggle Hoy / Historial / Stats + CRUD completo.
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  // 0 = Hoy, 1 = Historial, 2 = Stats
  int _viewIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SleepViewModel>().loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SleepViewModel>();

    return Scaffold(
      body: Column(
        children: [
          _ViewToggle(
            selectedIndex: _viewIndex,
            onSelect: (i) => setState(() => _viewIndex = i),
          ),
          Expanded(
            child: vm.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.sleep),
                  )
                : switch (_viewIndex) {
                    1 => _HistoryView(vm: vm),
                    2 => _StatsView(vm: vm),
                    _ => _TodayView(vm: vm),
                  },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Toggle Hoy / Historial / Stats (3 tabs)
// ═══════════════════════════════════════════════════════

class _ViewToggle extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ViewToggle({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _tab(Icons.nightlight_round, 'Hoy', 0),
          const SizedBox(width: 8),
          _tab(Icons.history, 'Historial', 1),
          const SizedBox(width: 8),
          _tab(Icons.insights, 'Stats', 2),
        ],
      ),
    );
  }

  Widget _tab(IconData icon, String label, int index) {
    final active = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppColors.sleep.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.sleep : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? AppColors.sleep : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.sleep : AppColors.textSecondary,
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
//  Vista HOY
// ═══════════════════════════════════════════════════════

class _TodayView extends StatelessWidget {
  final SleepViewModel vm;

  const _TodayView({required this.vm});

  @override
  Widget build(BuildContext context) {
    final log = vm.todayLog;

    if (log == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bedtime_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Cómo has dormido?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Registra tu descanso de anoche',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showSleepModal(context, vm, null),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Registrar sueño'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sleep,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SleepCard(log: log, expanded: true),
          const SizedBox(height: 16),
          // Botones Editar / Borrar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSleepModal(context, vm, log),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.sleep,
                    side: const BorderSide(color: AppColors.sleep),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, vm, log.id),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Borrar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DiagnosisCard(log: log),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Vista HISTORIAL
// ═══════════════════════════════════════════════════════

class _HistoryView extends StatelessWidget {
  final SleepViewModel vm;

  const _HistoryView({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.logs.isEmpty) {
      return const Center(
        child: Text(
          'Aún no hay registros de sueño',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vm.logs.length,
      itemBuilder: (context, index) {
        final log = vm.logs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: ValueKey(log.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (_) => _showDeleteConfirm(context),
            onDismissed: (_) => vm.deleteSleepLog(log.id),
            child: GestureDetector(
              onTap: () => _showSleepModal(context, vm, log),
              child: _SleepCard(log: log, expanded: false),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Borrar registro',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          '¿Eliminar este registro de sueño?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Borrar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Sleep Card (compartida por Hoy e Historial)
// ═══════════════════════════════════════════════════════

class _SleepCard extends StatelessWidget {
  final SleepLogEntity log;
  final bool
  expanded; // true = vista Hoy (grande), false = historial (compacta)

  const _SleepCard({required this.log, required this.expanded});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM', 'es').format(log.endTime);
    final startStr = DateFormat('HH:mm').format(log.startTime);
    final endStr = DateFormat('HH:mm').format(log.endTime);
    final hasPhases =
        log.remSleepPct != null ||
        log.deepSleepPct != null ||
        log.lightSleepPct != null;

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha
            Text(
              dateStr,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: expanded ? 13 : 11,
              ),
            ),
            const SizedBox(height: 8),

            // Horas + horarios
            Row(
              children: [
                Icon(
                  Icons.nightlight_round,
                  color: AppColors.sleep,
                  size: expanded ? 28 : 20,
                ),
                const SizedBox(width: 10),
                Text(
                  '${log.totalHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: expanded ? 28 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$startStr → $endStr',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: expanded ? 14 : 12,
                  ),
                ),
                const Spacer(),
                // Estrellas
                if (log.qualityRating != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star,
                        size: expanded ? 16 : 12,
                        color: i < log.qualityRating!
                            ? Colors.amber
                            : AppColors.divider,
                      ),
                    ),
                  ),
              ],
            ),

            // Fases de sueño
            if (hasPhases) ...[
              SizedBox(height: expanded ? 16 : 10),
              _PhasesSegmentedBar(
                remPct: log.remSleepPct,
                deepPct: log.deepSleepPct,
                lightPct: log.lightSleepPct,
                expanded: expanded,
              ),
            ],

            // Notas
            if (log.notes != null && log.notes!.isNotEmpty && expanded) ...[
              const SizedBox(height: 12),
              Text(
                log.notes!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Barra única segmentada con los 3 colores de fases de sueño.
class _PhasesSegmentedBar extends StatelessWidget {
  static const Color _remColor = Color(0xFF7C4DFF);
  static const Color _deepColor = Color(0xFF448AFF);
  static const Color _lightColor = Color(0xFF80CBC4);

  final int? remPct;
  final int? deepPct;
  final int? lightPct;
  final bool expanded;

  const _PhasesSegmentedBar({
    required this.remPct,
    required this.deepPct,
    required this.lightPct,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final rem = remPct ?? 0;
    final deep = deepPct ?? 0;
    final light = lightPct ?? 0;
    final total = rem + deep + light;
    if (total == 0) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra segmentada
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: expanded ? 10 : 6,
            child: Row(
              children: [
                if (rem > 0)
                  Flexible(
                    flex: rem,
                    child: Container(color: _remColor),
                  ),
                if (deep > 0)
                  Flexible(
                    flex: deep,
                    child: Container(color: _deepColor),
                  ),
                if (light > 0)
                  Flexible(
                    flex: light,
                    child: Container(color: _lightColor),
                  ),
                if (total < 100)
                  Flexible(
                    flex: 100 - total,
                    child: Container(color: AppColors.divider),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Leyenda inline
        Row(
          children: [
            if (rem > 0) _label(_remColor, 'REM', rem, expanded),
            if (deep > 0) _label(_deepColor, 'Profundo', deep, expanded),
            if (light > 0) _label(_lightColor, 'Ligero', light, expanded),
          ],
        ),
      ],
    );
  }

  Widget _label(Color color, String name, int pct, bool expanded) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: expanded ? 8 : 6,
            height: expanded ? 8 : 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$name $pct%',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: expanded ? 11 : 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Diálogo de confirmación de borrado
// ═══════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════
//  Tarjeta de diagnóstico de sueño
// ═══════════════════════════════════════════════════════

class _DiagnosisCard extends StatefulWidget {
  final SleepLogEntity log;

  const _DiagnosisCard({required this.log});

  @override
  State<_DiagnosisCard> createState() => _DiagnosisCardState();
}

class _DiagnosisCardState extends State<_DiagnosisCard> {
  bool _expanded = false;
  bool _loading = true;
  SleepDiagnosis? _diagnosis;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await OpenRouterService.analyzeSleep(widget.log);
      if (mounted) setState(() => _diagnosis = d);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  color: AppColors.sleep,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Diagnóstico IA de tu noche',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_loading) ...[
                  const Spacer(),
                  const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      color: AppColors.sleep,
                      strokeWidth: 2,
                    ),
                  ),
                ],
                if (!_loading && _diagnosis != null) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: _load,
                    child: const Icon(
                      Icons.refresh,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Cargando
            if (_loading)
              const Text(
                'Analizando tu sueño…',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),

            // Error
            if (_error != null && !_loading) ...[
              const Text(
                'No se pudo obtener el análisis.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.sleep,
                  side: const BorderSide(color: AppColors.sleep, width: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],

            // Resultado
            if (_diagnosis != null && !_loading) ...[
              Text(
                _diagnosis!.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Consejo destacado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sleep.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.sleep.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      color: AppColors.sleep,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _diagnosis!.advice,
                        style: const TextStyle(
                          color: AppColors.sleep,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Detalles expandibles
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  children: [
                    Text(
                      _expanded ? 'Ver menos' : 'Ver análisis completo',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              ),

              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 12),
                _diagRow(
                  Icons.fitness_center_outlined,
                  'Físico',
                  _diagnosis!.physicalAnalysis,
                ),
                const SizedBox(height: 10),
                _diagRow(
                  Icons.psychology_outlined,
                  'Mental',
                  _diagnosis!.mentalAnalysis,
                ),
                const SizedBox(height: 10),
                _diagRow(
                  Icons.help_outline,
                  '¿Por qué?',
                  _diagnosis!.reason,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _diagRow(IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.sleep, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _confirmDelete(BuildContext context, SleepViewModel vm, String logId) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Borrar registro',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: const Text(
        '¿Eliminar este registro de sueño?',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            vm.deleteSleepLog(logId);
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

// ═══════════════════════════════════════════════════════
//  Modal de crear / editar sueño
// ═══════════════════════════════════════════════════════

void _showSleepModal(
  BuildContext context,
  SleepViewModel vm,
  SleepLogEntity? existing,
) {
  // Valores iniciales
  DateTime startTime =
      existing?.startTime ?? DateTime.now().subtract(const Duration(hours: 8));
  DateTime endTime = existing?.endTime ?? DateTime.now();
  int quality = existing?.qualityRating ?? 3;
  int remPct = existing?.remSleepPct ?? 0;
  int deepPct = existing?.deepSleepPct ?? 0;
  int lightPct = existing?.lightSleepPct ?? 0;
  bool phasesEnabled =
      existing != null &&
      (existing.remSleepPct != null ||
          existing.deepSleepPct != null ||
          existing.lightSleepPct != null);
  int heartRate = existing?.avgHeartRate ?? 60;
  bool heartRateEnabled = existing?.avgHeartRate != null;
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');

  showAdaptiveModal(
    context,
    StatefulBuilder(
      builder: (ctx, setSheetState) {
        final totalPct = remPct + deepPct + lightPct;
        final pctValid = totalPct <= 100;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  existing != null ? 'Editar Descanso' : 'Registrar Descanso',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // — Time pickers —
                _TimeTile(
                  label: 'Me acosté a las:',
                  time: startTime,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(startTime),
                    );
                    if (time != null) {
                      setSheetState(() {
                        startTime = DateTime(
                          startTime.year,
                          startTime.month,
                          startTime.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  },
                ),
                _TimeTile(
                  label: 'Me desperté a las:',
                  time: endTime,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(endTime),
                    );
                    if (time != null) {
                      setSheetState(() {
                        endTime = DateTime(
                          endTime.year,
                          endTime.month,
                          endTime.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // — Calidad —
                const Text(
                  'Calidad del sueño',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      icon: Icon(
                        index < quality ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setSheetState(() => quality = index + 1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // — Fases toggle —
                Row(
                  children: [
                    const Text(
                      'Fases de sueño',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: phasesEnabled,
                      activeTrackColor: AppColors.sleep.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.sleep,
                      onChanged: (v) => setSheetState(() {
                        phasesEnabled = v;
                        if (!v) {
                          remPct = 0;
                          deepPct = 0;
                          lightPct = 0;
                        }
                      }),
                    ),
                  ],
                ),

                if (phasesEnabled) ...[
                  _PhaseSlider(
                    label: 'REM',
                    value: remPct,
                    color: const Color(0xFF7C4DFF),
                    onChanged: (v) => setSheetState(() => remPct = v),
                  ),
                  _PhaseSlider(
                    label: 'Profundo',
                    value: deepPct,
                    color: const Color(0xFF448AFF),
                    onChanged: (v) => setSheetState(() => deepPct = v),
                  ),
                  _PhaseSlider(
                    label: 'Ligero',
                    value: lightPct,
                    color: const Color(0xFF80CBC4),
                    onChanged: (v) => setSheetState(() => lightPct = v),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: $totalPct%${!pctValid ? ' (máx 100%)' : ''}',
                    style: TextStyle(
                      color: pctValid
                          ? AppColors.textSecondary
                          : AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // — Ritmo Cardíaco —
                Row(
                  children: [
                    const Text(
                      'Ritmo cardíaco (LPM)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: heartRateEnabled,
                      activeTrackColor: AppColors.sleep.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.sleep,
                      onChanged: (v) => setSheetState(() {
                        heartRateEnabled = v;
                        if (!v) heartRate = 60;
                      }),
                    ),
                  ],
                ),
                if (heartRateEnabled) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_outline,
                        color: AppColors.danger,
                        size: 16,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.danger,
                            inactiveTrackColor: AppColors.divider,
                            thumbColor: AppColors.danger,
                            overlayColor: AppColors.danger.withValues(alpha: 0.2),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: heartRate.toDouble(),
                            min: 40,
                            max: 100,
                            divisions: 60,
                            onChanged: (v) =>
                                setSheetState(() => heartRate = v.round()),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text(
                          '$heartRate LPM',
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),

                // — Notas —
                TextField(
                  controller: notesCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Notas (opcional)',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.scaffold,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // — Guardar —
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pctValid
                          ? AppColors.sleep
                          : AppColors.divider,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: pctValid
                        ? () {
                            vm.saveSleepLog(
                              existingId: existing?.id,
                              startTime: startTime,
                              endTime: endTime,
                              qualityRating: quality,
                              remSleepPct: phasesEnabled ? remPct : null,
                              deepSleepPct: phasesEnabled ? deepPct : null,
                              lightSleepPct: phasesEnabled ? lightPct : null,
                              notes: notesCtrl.text.trim().isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                              avgHeartRate:
                                  heartRateEnabled ? heartRate : null,
                            );
                            Navigator.pop(ctx);
                          }
                        : null,
                    child: Text(
                      existing != null ? 'Guardar Cambios' : 'Registrar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ═══════════════════════════════════════════════════════
//  Widgets auxiliares del modal
// ═══════════════════════════════════════════════════════

class _TimeTile extends StatelessWidget {
  final String label;
  final DateTime time;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Text(
        DateFormat('HH:mm').format(time),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _PhaseSlider extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _PhaseSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: AppColors.divider,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value%',
            style: TextStyle(color: color, fontSize: 12),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Vista STATS — dashboard de analíticas de sueño
// ═══════════════════════════════════════════════════════

class _StatsView extends StatefulWidget {
  final SleepViewModel vm;

  const _StatsView({required this.vm});

  @override
  State<_StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<_StatsView> {
  bool _allTime = false;

  static const Color _remColor = Color(0xFF7C4DFF);
  static const Color _deepColor = Color(0xFF448AFF);
  static const Color _lightColor = Color(0xFF80CBC4);

  int get _days => _allTime ? 36500 : 30;

  int _totalWeeks() {
    final logs = widget.vm.logs;
    if (logs.isEmpty) return 5;
    final oldest = logs
        .map((l) => l.endTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final weeks = DateTime.now().difference(oldest).inDays ~/ 7 + 1;
    return weeks.clamp(1, 104);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final analytics = vm.analytics;

    if (vm.logs.isEmpty) {
      return const Center(
        child: Text(
          'Registra tu sueño para ver estadísticas',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    if (analytics == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.sleep),
      );
    }

    final avgHours = analytics.averageHours(days: _days);
    final avgQuality = analytics.averageQuality(days: _days);
    final consistency = analytics.consistencyScore(days: _days);
    final phases = analytics.averagePhases(days: _days);
    final weeks = _allTime ? _totalWeeks() : 5;
    final weeklyData = analytics.weeklyTrend(weeks: weeks);
    final best = analytics.bestDay(days: _allTime ? null : _days);
    final worst = analytics.worstDay(days: _allTime ? null : _days);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Toggle Mes / Todo ──
          Center(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Mes')),
                ButtonSegment(value: true, label: Text('Todo')),
              ],
              selected: {_allTime},
              onSelectionChanged: (s) => setState(() => _allTime = s.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.sleep.withValues(alpha: 0.25);
                  }
                  return AppColors.surface;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.sleep;
                  }
                  return AppColors.textSecondary;
                }),
                side: WidgetStateProperty.all(
                  const BorderSide(color: AppColors.sleep, width: 1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Resumen ──
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _summaryMetric(
                    Icons.bedtime_outlined,
                    '${avgHours.toStringAsFixed(1)}h',
                    'Media horas',
                  ),
                  _summaryMetric(
                    Icons.star_outline,
                    avgQuality.toStringAsFixed(1),
                    'Calidad media',
                  ),
                  _summaryMetric(
                    Icons.schedule,
                    '${(consistency * 100).round()}%',
                    'Consistencia',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── PieChart + BarChart ──
          if (context.isWeb)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distribución media de fases',
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
                          child: _PhasePieChart(
                            rem: phases.rem,
                            deep: phases.deep,
                            light: phases.light,
                            remColor: _remColor,
                            deepColor: _deepColor,
                            lightColor: _lightColor,
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
                        _allTime
                            ? 'Horas medias por semana (historial)'
                            : 'Horas medias por semana (últimas 5)',
                        style: const TextStyle(
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
                            child: _WeeklyBarChart(data: weeklyData),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            const Text(
              'Distribución media de fases',
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
                child: _PhasePieChart(
                  rem: phases.rem,
                  deep: phases.deep,
                  light: phases.light,
                  remColor: _remColor,
                  deepColor: _deepColor,
                  lightColor: _lightColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _allTime
                  ? 'Horas medias por semana (historial completo)'
                  : 'Horas medias por semana (últimas 5)',
              style: const TextStyle(
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
                  child: _WeeklyBarChart(data: weeklyData),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 20),

          // ── Mejor / Peor día ──
          if (best != null && worst != null) ...[
            const Text(
              'Mejor y peor noche',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DayCard(
                    label: 'Mejor noche',
                    icon: Icons.emoji_events_outlined,
                    iconColor: Colors.amber,
                    log: best,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DayCard(
                    label: 'Peor noche',
                    icon: Icons.warning_amber_outlined,
                    iconColor: AppColors.danger,
                    log: worst,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _summaryMetric(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.sleep, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PieChart — distribución media de fases
// ═══════════════════════════════════════════════════════

class _PhasePieChart extends StatelessWidget {
  final double rem, deep, light;
  final Color remColor, deepColor, lightColor;

  const _PhasePieChart({
    required this.rem,
    required this.deep,
    required this.light,
    required this.remColor,
    required this.deepColor,
    required this.lightColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = rem + deep + light;

    if (total == 0) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Sin datos de fases registrados',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          height: 140,
          width: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                PieChartSectionData(
                  value: rem,
                  color: remColor,
                  title: '${rem.round()}%',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  radius: 36,
                ),
                PieChartSectionData(
                  value: deep,
                  color: deepColor,
                  title: '${deep.round()}%',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  radius: 36,
                ),
                PieChartSectionData(
                  value: light,
                  color: lightColor,
                  title: '${light.round()}%',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  radius: 36,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(remColor, 'REM', rem),
            const SizedBox(height: 10),
            _legend(deepColor, 'Profundo', deep),
            const SizedBox(height: 10),
            _legend(lightColor, 'Ligero', light),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color color, String label, double value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label  ${value.round()}%',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  BarChart — tendencia semanal (fl_chart)
// ═══════════════════════════════════════════════════════

class _WeeklyBarChart extends StatelessWidget {
  final Map<String, double> data; // {'YYYY-WNN': hours}

  const _WeeklyBarChart({required this.data});

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
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < entries.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entries[i].value,
              color: entries[i].value >= 7
                  ? AppColors.sleep
                  : AppColors.sleep.withValues(alpha: 0.45),
              width: 18,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: 12,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 4,
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
              reservedSize: 28,
              interval: 4,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}h',
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
                // 'YYYY-WNN' → 'WNN'
                final parts = entries[idx].key.split('-');
                final label = parts.length >= 2 ? parts.last : '';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        // Línea de referencia a 8 horas
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 8,
              color: Colors.amber.withValues(alpha: 0.7),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => '8h',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.scaffold,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${rod.toY.toStringAsFixed(1)}h',
              const TextStyle(
                color: AppColors.sleep,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Mini card: mejor / peor noche
// ═══════════════════════════════════════════════════════

class _DayCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final SleepLogEntity log;

  const _DayCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM', 'es').format(log.endTime);
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${log.totalHours.toStringAsFixed(1)}h',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
