import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/adaptive_modal.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/openrouter_service.dart';
import '../../domain/entities/sleep_log_entity.dart';
import '../../domain/services/sleep_diagnosis_service.dart';
import '../viewmodels/sleep_viewmodel.dart';

// ─── Zen OS Design Tokens ───────────────────────────────
Color get _kBg => AppColors.scaffold;
Color get _kSurface => AppColors.surface;
Color get _kTextPrimary => AppColors.textPrimary;
Color get _kTextSecondary => AppColors.textSecondary;
Color get _kDivider => AppColors.divider;
Color get _kAccent => AppColors.accent;
 // sage green
Color get _kDanger => AppColors.danger;

// Colores fases
Color get _kRemColor => Color(0xFF7C4DFF);
Color get _kDeepColor => Color(0xFF448AFF);
Color get _kLightColor => Color(0xFF80CBC4);

// ═══════════════════════════════════════════════════════
//  SleepScreen
// ═══════════════════════════════════════════════════════

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
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header compartido ──
            _ZenHeader(
              viewIndex: _viewIndex,
              onSelect: (i) => setState(() => _viewIndex = i),
              todayLog: vm.todayLog,
            ),
            Divider(color: _kDivider, height: 1),

            // ── Contenido ──
            Expanded(
              child: vm.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: _kAccent,
                        strokeWidth: 1.5,
                      ),
                    )
                  : switch (_viewIndex) {
                      1 => _HistoryView(vm: vm),
                      2 => _StatsView(vm: vm),
                      _ => _TodayView(vm: vm),
                    },
            ),

          ],
        ),
      ),
    );
  }
}


// ─── Header + Tab toggle ─────────────────────────────────

class _ZenHeader extends StatelessWidget {
  final int viewIndex;
  final ValueChanged<int> onSelect;
  final SleepLogEntity? todayLog;

  const _ZenHeader({
    required this.viewIndex,
    required this.onSelect,
    required this.todayLog,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel = DateFormat('EEEE, d MMMM', 'es').format(now).toUpperCase();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtítulo uppercase pequeño
          Text(
            dateLabel,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2.0,
              color: _kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),

          // Título principal y botón añadir
          Row(
            children: [
              Text(
                'Descanso',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                  height: 1.1,
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: () => showSleepModal(context, context.read<SleepViewModel>(), null),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: _kTextSecondary,
                ),
              ),
            ],
          ),

          // Bloque de datos plano (horas de hoy) — inmediatamente debajo
          if (todayLog != null && viewIndex == 0) ...[
            SizedBox(height: 10),
            _TodayInlineMetric(log: todayLog!),
          ],
          SizedBox(height: 14),

          // Tabs planos
          Row(
            children: [
              _Tab(label: 'Hoy', index: 0, selected: viewIndex, onSelect: onSelect),
              SizedBox(width: 24),
              _Tab(label: 'Historial', index: 1, selected: viewIndex, onSelect: onSelect),
              SizedBox(width: 24),
              _Tab(label: 'Stats', index: 2, selected: viewIndex, onSelect: onSelect),
            ],
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Resumen inline de horas debajo del header cuando hay registro de hoy.
class _TodayInlineMetric extends StatelessWidget {
  final SleepLogEntity log;

  const _TodayInlineMetric({required this.log});

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('HH:mm').format(log.startTime);
    final endStr = DateFormat('HH:mm').format(log.endTime);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${log.totalHours.toStringAsFixed(1)}h',
          style: GoogleFonts.inter(
            fontSize: 42,
            fontWeight: FontWeight.w400,
            color: _kTextPrimary,
            height: 1,
          ),
        ),
        SizedBox(width: 12),
        Text(
          '$startStr → $endStr',
          style: TextStyle(color: _kTextSecondary, fontSize: 13),
        ),
        if (log.qualityRating != null) ...[
          SizedBox(width: 12),
          _StarRating(rating: log.qualityRating!, size: 14),
        ],
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onSelect;

  const _Tab({
    required this.label,
    required this.index,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == index;
    return GestureDetector(
      onTap: () => onSelect(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? _kAccent : Colors.transparent,
              width: 1.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? _kTextPrimary : _kTextSecondary,
            letterSpacing: 0.4,
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
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bedtime_outlined, size: 48, color: _kTextSecondary),
              SizedBox(height: 20),
              Text(
                '¿Cómo has dormido?',
                style: GoogleFonts.inter(
                  color: _kTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Usa el botón inferior para registrar tu descanso',
                style: TextStyle(color: _kTextSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fases
          _SectionLabel('FASES DE SUEÑO'),
          SizedBox(height: 8),
          _PhaseRows(log: log),
          SizedBox(height: 28),

          // Notas
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            _SectionLabel('NOTAS'),
            SizedBox(height: 8),
            Text(
              log.notes!,
              style: TextStyle(
                color: _kTextSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
            SizedBox(height: 28),
          ],

          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _confirmDelete(context, vm, log.id),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Borrar registro',
                  style: TextStyle(
                    color: _kDanger.withValues(alpha: 0.7),
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: _kDanger.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 28),
          Divider(color: _kDivider),
          SizedBox(height: 24),
          _DiagnosisSection(log: log),
        ],
      ),
    );
  }
}

// ── Phase rows ───────────────────────────────────────────

class _PhaseRows extends StatelessWidget {
  final SleepLogEntity log;

  const _PhaseRows({required this.log});

  @override
  Widget build(BuildContext context) {
    final deep = log.deepSleepPct;
    final light = log.lightSleepPct;
    final rem = log.remSleepPct;

    if (deep == null && light == null && rem == null) {
      return Text(
        'Sin datos de fases registrados',
        style: TextStyle(color: _kTextSecondary, fontSize: 13),
      );
    }

    return Column(
      children: [
        if (deep != null) _PhaseRow(label: 'Sueño profundo', value: deep, color: _kDeepColor),
        if (light != null) _PhaseRow(label: 'Sueño ligero', value: light, color: _kLightColor),
        if (rem != null) _PhaseRow(label: 'REM', value: rem, color: _kRemColor),
      ],
    );
  }
}

class _PhaseRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _PhaseRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 16, color: color),
          SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: _kTextPrimary, fontSize: 14)),
          ),
          Text('$value%', style: TextStyle(color: _kTextSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Star rating ──────────────────────────────────────────

class _StarRating extends StatelessWidget {
  final int rating;
  final double size;

  const _StarRating({required this.rating, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Padding(
          padding: EdgeInsets.only(right: 3),
          child: Icon(
            Icons.star,
            size: size,
            color: i < rating ? _kAccent : _kDivider.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 9,
        letterSpacing: 2.0,
        color: _kTextSecondary,
        fontWeight: FontWeight.w500,
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
      return Center(
        child: Text(
          'Aún no hay registros de sueño',
          style: TextStyle(color: _kTextSecondary, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: vm.logs.length,
      itemBuilder: (context, index) {
        final log = vm.logs[index];
        return Dismissible(
          key: ValueKey(log.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            color: _kDanger.withValues(alpha: 0.12),
            child: Icon(Icons.delete_outline, color: _kDanger, size: 18),
          ),
          confirmDismiss: (_) => _showDeleteConfirm(context),
          onDismissed: (_) => vm.deleteSleepLog(log.id),
          child: GestureDetector(
            onTap: () => showSleepModal(context, vm, log),
            child: _HistoryRow(log: log),
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(),
        title: Text('Borrar registro', style: TextStyle(color: _kTextPrimary)),
        content: Text(
          '¿Eliminar este registro de sueño?',
          style: TextStyle(color: _kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCELAR', style: TextStyle(color: _kTextSecondary, fontSize: 12, letterSpacing: 1)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('BORRAR', style: TextStyle(color: _kDanger, fontSize: 12, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final SleepLogEntity log;

  const _HistoryRow({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM', 'es').format(log.endTime);
    final weekday = DateFormat('EEE', 'es').format(log.endTime).toUpperCase();
    final isGood = log.totalHours >= 7;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        children: [
          // Fecha
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekday,
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(color: _kTextPrimary, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),

          // Horas
          Text(
            '${log.totalHours.toStringAsFixed(1)}h',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              // sage green si >= 7h, textPrimary si normal
              color: isGood ? _kAccent : _kTextPrimary,
            ),
          ),
          Spacer(),

          // Estrellas
          if (log.qualityRating != null) _StarRating(rating: log.qualityRating!, size: 12),
          SizedBox(width: 8),
          Icon(Icons.chevron_right, color: _kTextSecondary, size: 14),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Diálogo confirmación borrado
// ═══════════════════════════════════════════════════════

void _confirmDelete(BuildContext context, SleepViewModel vm, String logId) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _kSurface,
      shape: RoundedRectangleBorder(),
      title: Text('Borrar registro', style: TextStyle(color: _kTextPrimary)),
      content: Text(
        '¿Eliminar este registro de sueño?',
        style: TextStyle(color: _kTextSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCELAR', style: TextStyle(color: _kTextSecondary, fontSize: 12, letterSpacing: 1)),
        ),
        TextButton(
          onPressed: () {
            vm.deleteSleepLog(logId);
            Navigator.pop(context);
          },
          child: Text('BORRAR', style: TextStyle(color: _kDanger, fontSize: 12, letterSpacing: 1)),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════
//  Diagnóstico IA (sección plana)
// ═══════════════════════════════════════════════════════

class _DiagnosisSection extends StatefulWidget {
  final SleepLogEntity log;

  const _DiagnosisSection({required this.log});

  @override
  State<_DiagnosisSection> createState() => _DiagnosisSectionState();
}

class _DiagnosisSectionState extends State<_DiagnosisSection> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionLabel('DIAGNÓSTICO IA'),
            Spacer(),
            if (_loading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(color: _kAccent, strokeWidth: 1.5),
              ),
            if (!_loading && _diagnosis != null)
              GestureDetector(
                onTap: _load,
                child: Icon(Icons.refresh, color: _kTextSecondary, size: 16),
              ),
          ],
        ),
        SizedBox(height: 12),

        if (_loading)
          Text(
            'Analizando tu sueño…',
            style: TextStyle(color: _kTextSecondary, fontSize: 13, fontStyle: FontStyle.italic),
          ),

        if (_error != null && !_loading) ...[
          Text(
            'No se pudo obtener el análisis.',
            style: TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: _load,
            child: Text(
              'Reintentar',
              style: TextStyle(
                color: _kAccent,
                fontSize: 12,
                decoration: TextDecoration.underline,
                decorationColor: _kAccent,
              ),
            ),
          ),
        ],

        if (_diagnosis != null && !_loading) ...[
          Text(
            _diagnosis!.title,
            style: GoogleFonts.inter(
              color: _kTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 12),

          // Consejo con borde izquierdo sage
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 2, height: 40, color: _kAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _diagnosis!.advice,
                  style: TextStyle(color: _kTextSecondary, fontSize: 13, height: 1.6),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),

          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Text(
                  _expanded ? 'Ver menos' : 'Ver análisis completo',
                  style: TextStyle(color: _kAccent, fontSize: 12),
                ),
                SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: _kAccent,
                  size: 16,
                ),
              ],
            ),
          ),

          if (_expanded) ...[
            SizedBox(height: 16),
            Divider(color: _kDivider),
            SizedBox(height: 16),
            _diagRow('FÍSICO', _diagnosis!.physicalAnalysis),
            SizedBox(height: 14),
            _diagRow('MENTAL', _diagnosis!.mentalAnalysis),
            SizedBox(height: 14),
            _diagRow('¿POR QUÉ?', _diagnosis!.reason),
          ],
        ],
      ],
    );
  }

  Widget _diagRow(String label, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _kTextSecondary,
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(color: _kTextPrimary, fontSize: 13, height: 1.6),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Modal de crear / editar sueño
// ═══════════════════════════════════════════════════════

void showSleepModal(
  BuildContext context,
  SleepViewModel vm,
  SleepLogEntity? existing,
) {
  DateTime startTime =
      existing?.startTime ?? DateTime.now().subtract(Duration(hours: 8));
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

        return Container(
          // Fondo del sheet
          decoration: BoxDecoration(
            color: _kSurface,
            border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
          ),
          padding: EdgeInsets.fromLTRB(
            22,
            26,
            22,
            MediaQuery.of(ctx).viewInsets.bottom + 44,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del sheet
                Text(
                  existing != null ? 'Editar descanso' : 'Registrar descanso',
                  style: GoogleFonts.inter(
                    color: _kTextPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Divider(color: _kDivider),
                SizedBox(height: 18),

                // — Horas —
                _ZenTimeTile(
                  label: 'ME ACOSTÉ A LAS',
                  time: startTime,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(startTime),
                      builder: (ctx, child) => _zenTimePickerTheme(ctx, child),
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
                _ZenTimeTile(
                  label: 'ME DESPERTÉ A LAS',
                  time: endTime,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(endTime),
                      builder: (ctx, child) => _zenTimePickerTheme(ctx, child),
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
                SizedBox(height: 20),

                // — Calidad —
                _SectionLabel('CALIDAD DEL SUEÑO'),
                SizedBox(height: 10),
                Row(
                  children: List.generate(
                    5,
                    (index) => GestureDetector(
                      onTap: () => setSheetState(() => quality = index + 1),
                      child: Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.star,
                          size: 28,
                          color: index < quality ? _kAccent : _kDivider.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Divider(color: _kDivider),
                SizedBox(height: 14),

                // — Fases toggle —
                Row(
                  children: [
                    Text('Fases de sueño', style: TextStyle(color: _kTextPrimary, fontSize: 14)),
                    Spacer(),
                    Switch(
                      value: phasesEnabled,
                      activeTrackColor: _kAccent.withValues(alpha: 0.5),
                      activeThumbColor: _kAccent,
                      inactiveThumbColor: _kTextSecondary,
                      inactiveTrackColor: _kDivider,
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
                  SizedBox(height: 8),
                  _ZenPhaseSlider(
                    label: 'REM',
                    value: remPct,
                    color: _kRemColor,
                    onChanged: (v) => setSheetState(() => remPct = v),
                  ),
                  _ZenPhaseSlider(
                    label: 'Profundo',
                    value: deepPct,
                    color: _kDeepColor,
                    onChanged: (v) => setSheetState(() => deepPct = v),
                  ),
                  _ZenPhaseSlider(
                    label: 'Ligero',
                    value: lightPct,
                    color: _kLightColor,
                    onChanged: (v) => setSheetState(() => lightPct = v),
                  ),
                  Text(
                    'Total: $totalPct%${!pctValid ? ' (máx. 100%)' : ''}',
                    style: TextStyle(
                      color: pctValid ? _kTextSecondary : _kDanger,
                      fontSize: 12,
                    ),
                  ),
                ],
                SizedBox(height: 14),
                Divider(color: _kDivider),
                SizedBox(height: 14),

                // — Ritmo cardíaco —
                Row(
                  children: [
                    Text('Ritmo cardíaco (LPM)', style: TextStyle(color: _kTextPrimary, fontSize: 14)),
                    Spacer(),
                    Switch(
                      value: heartRateEnabled,
                      activeTrackColor: _kAccent.withValues(alpha: 0.5),
                      activeThumbColor: _kAccent,
                      inactiveThumbColor: _kTextSecondary,
                      inactiveTrackColor: _kDivider,
                      onChanged: (v) => setSheetState(() {
                        heartRateEnabled = v;
                        if (!v) heartRate = 60;
                      }),
                    ),
                  ],
                ),
                if (heartRateEnabled) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.favorite_outline, color: _kDanger, size: 16),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: _kDanger,
                            inactiveTrackColor: _kDivider,
                            thumbColor: _kDanger,
                            overlayColor: _kDanger.withValues(alpha: 0.15),
                            trackHeight: 2,
                          ),
                          child: Slider(
                            value: heartRate.toDouble(),
                            min: 40,
                            max: 100,
                            divisions: 60,
                            onChanged: (v) => setSheetState(() => heartRate = v.round()),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '$heartRate LPM',
                          style: TextStyle(color: _kDanger, fontSize: 12),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 14),
                Divider(color: _kDivider),
                SizedBox(height: 14),

                // — Notas —
                TextField(
                  controller: notesCtrl,
                  style: TextStyle(color: _kTextPrimary, fontSize: 13),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Notas (opcional)',
                    hintStyle: TextStyle(color: _kTextSecondary, fontSize: 13),
                    filled: true,
                    fillColor: _kBg,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                SizedBox(height: 24),

                // — Acciones (Cancel + Guardar) —
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: _kDivider),
                          ),
                          child: Center(
                            child: Text(
                              'CANCELAR',
                              style: TextStyle(
                                color: _kTextSecondary,
                                fontSize: 12,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: pctValid
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
                                  avgHeartRate: heartRateEnabled ? heartRate : null,
                                );
                                Navigator.pop(ctx);
                              }
                            : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          color: pctValid
                              ? _kTextPrimary
                              : _kTextSecondary.withValues(alpha: 0.2),
                          child: Center(
                            child: Text(
                              existing != null ? 'GUARDAR' : 'REGISTRAR',
                              style: TextStyle(
                                color: pctValid
                                    ? AppColors.scaffold
                                    : _kTextSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Aplica el tema oscuro Zen al TimePicker nativo de Flutter.
Widget _zenTimePickerTheme(BuildContext context, Widget? child) {
  return Theme(
    data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.dark(
        primary: _kAccent,
        surface: _kSurface,
        onSurface: _kTextPrimary,
      ), dialogTheme: DialogThemeData(backgroundColor: _kSurface),
    ),
    child: child!,
  );
}

// ═══════════════════════════════════════════════════════
//  Widgets auxiliares del modal
// ═══════════════════════════════════════════════════════

class _ZenTimeTile extends StatelessWidget {
  final String label;
  final DateTime time;
  final VoidCallback onTap;

  const _ZenTimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _kDivider)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: _kTextSecondary,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Text(
              DateFormat('HH:mm').format(time),
              style: GoogleFonts.inter(
                color: _kTextPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.chevron_right, color: _kTextSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}

class _ZenPhaseSlider extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _ZenPhaseSlider({
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
          child: Text(label, style: TextStyle(color: _kTextSecondary, fontSize: 12)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: _kDivider,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 2,
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
      return Center(
        child: Text(
          'Registra tu sueño para ver estadísticas',
          style: TextStyle(color: _kTextSecondary, fontSize: 14),
        ),
      );
    }

    if (analytics == null) {
      return Center(
        child: CircularProgressIndicator(color: _kAccent, strokeWidth: 1.5),
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
      padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Toggle Mes / Todo ──
          Row(
            children: [
              _TogglePill(
                label: 'Mes',
                active: !_allTime,
                onTap: () => setState(() => _allTime = false),
              ),
              SizedBox(width: 10),
              _TogglePill(
                label: 'Todo',
                active: _allTime,
                onTap: () => setState(() => _allTime = true),
              ),
            ],
          ),
          SizedBox(height: 24),

          // ── Métricas resumen ──
          _SectionLabel('RESUMEN'),
          SizedBox(height: 12),
          Row(
            children: [
              _ZenStatMetric(label: 'MEDIA', value: '${avgHours.toStringAsFixed(1)}h'),
              SizedBox(width: 1, height: 40, child: VerticalDivider(color: _kDivider, width: 1)),
              _ZenStatMetric(label: 'CALIDAD', value: avgQuality.toStringAsFixed(1)),
              SizedBox(width: 1, height: 40, child: VerticalDivider(color: _kDivider, width: 1)),
              _ZenStatMetric(label: 'CONSISTENCIA', value: '${(consistency * 100).round()}%'),
            ],
          ),
          SizedBox(height: 32),

          // ── Gráficos ──
          _SectionLabel('FASES MEDIAS'),
          SizedBox(height: 16),
          if (context.isWeb)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PhasePieChart(
                    rem: phases.rem,
                    deep: phases.deep,
                    light: phases.light,
                    remColor: _kRemColor,
                    deepColor: _kDeepColor,
                    lightColor: _kLightColor,
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                        _allTime
                            ? 'HORAS / SEMANA (HISTORIAL)'
                            : 'HORAS / SEMANA (ÚLTIMAS 5)',
                      ),
                      SizedBox(height: 16),
                      SizedBox(height: 200, child: _WeeklyBarChart(data: weeklyData)),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            _PhasePieChart(
              rem: phases.rem,
              deep: phases.deep,
              light: phases.light,
              remColor: _kRemColor,
              deepColor: _kDeepColor,
              lightColor: _kLightColor,
            ),
            SizedBox(height: 32),
            _SectionLabel(
              _allTime
                  ? 'HORAS / SEMANA (HISTORIAL)'
                  : 'HORAS / SEMANA (ÚLTIMAS 5)',
            ),
            SizedBox(height: 16),
            SizedBox(height: 200, child: _WeeklyBarChart(data: weeklyData)),
          ],
          SizedBox(height: 32),

          // ── Mejor / Peor día ──
          if (best != null && worst != null) ...[
            _SectionLabel('NOCHES DESTACADAS'),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _ZenDayBlock(label: 'Mejor noche', log: best, accent: _kAccent)),
                SizedBox(width: 1),
                Expanded(child: _ZenDayBlock(label: 'Peor noche', log: worst, accent: _kDanger)),
              ],
            ),
          ],
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TogglePill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _kTextPrimary : Colors.transparent,
          border: Border.all(color: active ? _kTextPrimary : _kDivider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _kBg : _kTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ZenStatMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ZenStatMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: _kTextPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: _kTextSecondary,
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZenDayBlock extends StatelessWidget {
  final String label;
  final SleepLogEntity log;
  final Color accent;

  const _ZenDayBlock({required this.label, required this.log, required this.accent});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM', 'es').format(log.endTime);
    return Container(
      padding: EdgeInsets.all(16),
      color: _kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: accent,
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '${log.totalHours.toStringAsFixed(1)}h',
            style: GoogleFonts.inter(
              color: _kTextPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(dateStr, style: TextStyle(color: _kTextSecondary, fontSize: 12)),
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
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Sin datos de fases registrados',
            style: TextStyle(color: _kTextSecondary),
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
                  titleStyle: TextStyle(
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
                  titleStyle: TextStyle(
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
                  titleStyle: TextStyle(
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
        SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(remColor, 'REM', rem),
            SizedBox(height: 10),
            _legend(deepColor, 'Profundo', deep),
            SizedBox(height: 10),
            _legend(lightColor, 'Ligero', light),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color color, String label, double value) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        SizedBox(width: 8),
        Text(
          '$label  ${value.round()}%',
          style: TextStyle(color: _kTextSecondary, fontSize: 13),
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
      return Center(
        child: Text('Sin datos suficientes', style: TextStyle(color: _kTextSecondary)),
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
                  ? _kAccent
                  : _kAccent.withValues(alpha: 0.35),
              width: 16,
              borderRadius: BorderRadius.zero,
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
              FlLine(color: _kDivider, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 4,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}h',
                style: TextStyle(color: _kTextSecondary, fontSize: 10),
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
                final label = parts.length >= 2 ? parts.last : '';
                return Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: TextStyle(color: _kTextSecondary, fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 8,
              color: _kAccent.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => '8h',
                style: TextStyle(
                  color: _kAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => _kSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${rod.toY.toStringAsFixed(1)}h',
              TextStyle(
                color: _kAccent,
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
