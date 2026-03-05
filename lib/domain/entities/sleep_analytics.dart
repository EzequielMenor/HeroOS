import 'dart:math';

import 'sleep_log_entity.dart';

/// Motor de analíticas de sueño — clase pura sin dependencias externas.
///
/// Recibe la lista completa de registros y calcula:
/// - Media de horas y calidad.
/// - Distribución media de fases (REM / Profundo / Ligero).
/// - Tendencia semanal de horas (últimas N semanas).
/// - Mejor y peor día.
/// - Puntuación de consistencia del horario de acostarse.
class SleepAnalytics {
  final List<SleepLogEntity> logs;

  const SleepAnalytics({required this.logs});

  // ─── Helpers privados ───

  static DateTime _normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  List<SleepLogEntity> _logsInLastDays(int days) {
    final cutoff = _normalizeDate(
      DateTime.now().subtract(Duration(days: days)),
    );
    return logs
        .where((l) => !_normalizeDate(l.endTime).isBefore(cutoff))
        .toList();
  }

  // ─── Métricas de resumen ───

  /// Media de horas dormidas en los últimos [days] días.
  double averageHours({int days = 30}) {
    final recent = _logsInLastDays(days);
    if (recent.isEmpty) return 0;
    return recent.map((l) => l.totalHours).reduce((a, b) => a + b) /
        recent.length;
  }

  /// Media de calidad (1-5) en los últimos [days] días.
  double averageQuality({int days = 30}) {
    final recent = _logsInLastDays(days)
        .where((l) => l.qualityRating != null)
        .toList();
    if (recent.isEmpty) return 0;
    return recent
            .map((l) => l.qualityRating!.toDouble())
            .reduce((a, b) => a + b) /
        recent.length;
  }

  /// Media de distribución de fases en los últimos [days] días.
  /// Solo considera registros con al menos una fase registrada.
  ({double rem, double deep, double light}) averagePhases({int days = 30}) {
    final recent = _logsInLastDays(days)
        .where(
          (l) =>
              l.remSleepPct != null ||
              l.deepSleepPct != null ||
              l.lightSleepPct != null,
        )
        .toList();
    if (recent.isEmpty) return (rem: 0, deep: 0, light: 0);

    double rem = 0, deep = 0, light = 0;
    for (final l in recent) {
      rem += l.remSleepPct ?? 0;
      deep += l.deepSleepPct ?? 0;
      light += l.lightSleepPct ?? 0;
    }
    final n = recent.length;
    return (rem: rem / n, deep: deep / n, light: light / n);
  }

  // ─── Tendencia semanal ───

  /// Horas medias por semana para las últimas [weeks] semanas.
  /// Clave: 'YYYY-WNN' (año + número de semana ISO).
  Map<String, double> weeklyTrend({int weeks = 8}) {
    final now = DateTime.now();
    final result = <String, double>{};

    for (int w = weeks - 1; w >= 0; w--) {
      final weekStart = _mondayOf(now.subtract(Duration(days: w * 7)));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final key =
          '${weekStart.year}-W${_isoWeekNumber(weekStart).toString().padLeft(2, '0')}';

      final weekLogs = logs.where((l) {
        final d = _normalizeDate(l.endTime);
        return !d.isBefore(weekStart) && d.isBefore(weekEnd);
      }).toList();

      result[key] = weekLogs.isEmpty
          ? 0.0
          : weekLogs.map((l) => l.totalHours).reduce((a, b) => a + b) /
              weekLogs.length;
    }
    return result;
  }

  // ─── Mejor y peor día ───

  /// Registro con más horas dormidas.
  /// Con [days] == null usa todos los registros; si se pasa un valor, filtra.
  SleepLogEntity? bestDay({int? days}) {
    final source = days != null ? _logsInLastDays(days) : logs;
    if (source.isEmpty) return null;
    return source.reduce((a, b) => a.totalHours >= b.totalHours ? a : b);
  }

  /// Registro con menos horas dormidas.
  /// Con [days] == null usa todos los registros; si se pasa un valor, filtra.
  SleepLogEntity? worstDay({int? days}) {
    final source = days != null ? _logsInLastDays(days) : logs;
    if (source.isEmpty) return null;
    return source.reduce((a, b) => a.totalHours <= b.totalHours ? a : b);
  }

  // ─── Consistencia de horario ───

  /// Puntuación de consistencia del horario de acostarse (0.0 a 1.0).
  /// 1.0 = siempre a la misma hora. 0.0 = horario muy irregular.
  double consistencyScore({int days = 30}) {
    final recent = _logsInLastDays(days);
    if (recent.length < 2) return 1.0;

    // Convertir startTime a horas decimales normalizando la ventana nocturna
    // (ej: 01:00 → 25.0 para evitar discontinuidades a medianoche)
    final hours = recent.map((l) {
      double h = l.startTime.hour + l.startTime.minute / 60.0;
      if (h < 12) h += 24;
      return h;
    }).toList();

    final mean = hours.reduce((a, b) => a + b) / hours.length;
    final variance =
        hours.map((h) => pow(h - mean, 2)).reduce((a, b) => a + b) /
        hours.length;
    final stdDev = sqrt(variance);

    // stdDev 0h → 1.0, stdDev ≥4h → 0.0
    return (1 - (stdDev / 4.0)).clamp(0.0, 1.0);
  }

  // ─── Helpers de semana ISO ───

  static DateTime _mondayOf(DateTime d) {
    return DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: d.weekday - 1));
  }

  static int _isoWeekNumber(DateTime d) {
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays + 1;
    return ((dayOfYear - d.weekday + 10) / 7).floor();
  }
}
