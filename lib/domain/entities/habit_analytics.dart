import 'habit_entity.dart';
import 'habit_log_entity.dart';

/// Motor de analíticas de hábitos — clase pura sin dependencias externas.
///
/// Recibe los hábitos y sus logs en un rango de fechas y calcula:
/// - Tasa de completado (por hábito y global).
/// - Historial y mejor racha.
/// - Tendencia mensual.
/// - Heatmap semanal (para la UI tipo GitHub).
class HabitAnalytics {
  final List<HabitEntity> habits;
  final List<HabitLogEntity> logs;

  const HabitAnalytics({required this.habits, required this.logs});

  // ─── Helpers privados ───

  /// Normaliza una fecha a solo año/mes/día (sin hora).
  static DateTime _normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  /// Logs completados filtrados por hábito.
  List<HabitLogEntity> _logsFor(String habitId) => logs
      .where((l) => l.habitId == habitId && l.status == 'completed')
      .toList();

  /// Set de fechas completadas para un hábito.
  Set<DateTime> _completedDatesFor(String habitId) =>
      _logsFor(habitId).map((l) => _normalizeDate(l.date)).toSet();

  /// Busca el HabitEntity por id.
  HabitEntity? _habitById(String habitId) {
    try {
      return habits.firstWhere((h) => h.id == habitId);
    } catch (_) {
      return null;
    }
  }

  // ─── Tasa de completado ───

  /// Tasa de completado de un hábito en los últimos [days] días.
  /// Retorna 0.0 a 1.0.
  /// Solo cuenta los días en los que el hábito estaba programado.
  double completionRate(String habitId, {int days = 30}) {
    final habit = _habitById(habitId);
    if (habit == null) return 0.0;

    final completed = _completedDatesFor(habitId);
    final now = _normalizeDate(DateTime.now());
    int scheduled = 0;
    int done = 0;

    for (int i = 0; i < days; i++) {
      final day = now.subtract(Duration(days: i));
      if (habit.isActiveOn(day)) {
        scheduled++;
        if (completed.contains(day)) done++;
      }
    }

    return scheduled == 0 ? 0.0 : done / scheduled;
  }

  /// Tasa global de completado de todos los hábitos en los últimos [days] días.
  double overallCompletionRate({int days = 30}) {
    if (habits.isEmpty) return 0.0;

    double sum = 0;
    for (final h in habits) {
      sum += completionRate(h.id, days: days);
    }
    return sum / habits.length;
  }

  /// Tendencia mensual global — promedio de la tasa de todos los hábitos por mes.
  /// Retorna un mapa ordenado: {'2026-01': 0.72, ...}
  Map<String, double> overallMonthlyTrend({int months = 6}) {
    if (habits.isEmpty) return {};
    final result = <String, double>{};
    for (final h in habits) {
      monthlyTrend(h.id, months: months).forEach((key, value) {
        result[key] = (result[key] ?? 0) + value;
      });
    }
    return result.map((key, value) => MapEntry(key, value / habits.length));
  }

  // ─── Rachas (Streaks) ───

  /// Historial de rachas consecutivas de un hábito.
  /// Retorna una lista con la longitud de cada racha (de más reciente a más antigua).
  List<int> streakHistory(String habitId) {
    final habit = _habitById(habitId);
    if (habit == null) return [];

    final completed = _completedDatesFor(habitId);
    final now = _normalizeDate(DateTime.now());
    final streaks = <int>[];
    int currentStreak = 0;

    // Recorremos hacia atrás desde hoy hasta 365 días
    for (int i = 0; i < 365; i++) {
      final day = now.subtract(Duration(days: i));
      if (!habit.isActiveOn(day)) continue; // saltar días no programados

      if (completed.contains(day)) {
        currentStreak++;
      } else {
        if (currentStreak > 0) {
          streaks.add(currentStreak);
        }
        currentStreak = 0;
      }
    }
    // Añadir la última racha si existe
    if (currentStreak > 0) streaks.add(currentStreak);

    return streaks;
  }

  /// La racha más larga de la historia (últimos 365 días).
  int bestStreak(String habitId) {
    final history = streakHistory(habitId);
    if (history.isEmpty) return 0;
    return history.reduce((a, b) => a > b ? a : b);
  }

  /// La racha actual (desde hoy hacia atrás).
  int currentStreak(String habitId) {
    final habit = _habitById(habitId);
    if (habit == null) return 0;

    final completed = _completedDatesFor(habitId);
    final now = _normalizeDate(DateTime.now());
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final day = now.subtract(Duration(days: i));
      if (!habit.isActiveOn(day)) continue;

      if (completed.contains(day)) {
        streak++;
      } else {
        break; // la racha se rompió
      }
    }
    return streak;
  }

  // ─── Tendencia mensual ───

  /// Tasa de completado por mes para un hábito.
  /// Retorna un mapa ordenado: {'2026-01': 0.85, '2026-02': 0.72, ...}
  Map<String, double> monthlyTrend(String habitId, {int months = 6}) {
    final habit = _habitById(habitId);
    if (habit == null) return {};

    final completed = _completedDatesFor(habitId);
    final now = DateTime.now();
    final result = <String, double>{};

    for (int m = months - 1; m >= 0; m--) {
      // Primer día del mes
      final month = DateTime(now.year, now.month - m, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0).day;
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';

      int scheduled = 0;
      int done = 0;

      for (int d = 1; d <= lastDay; d++) {
        final day = DateTime(month.year, month.month, d);
        // No contar días futuros
        if (day.isAfter(now)) break;
        if (habit.isActiveOn(day)) {
          scheduled++;
          if (completed.contains(day)) done++;
        }
      }

      result[key] = scheduled == 0 ? 0.0 : done / scheduled;
    }

    return result;
  }

  // ─── Heatmap ───

  /// Mapa de los últimos [days] días para un hábito.
  /// Clave: fecha normalizada. Valor: true si completado, false si programado pero no hecho.
  /// Los días no programados NO aparecen en el mapa.
  Map<DateTime, bool> weeklyHeatmap(String habitId, {int days = 90}) {
    final habit = _habitById(habitId);
    if (habit == null) return {};

    final completed = _completedDatesFor(habitId);
    final now = _normalizeDate(DateTime.now());
    final map = <DateTime, bool>{};

    for (int i = 0; i < days; i++) {
      final day = now.subtract(Duration(days: i));
      if (habit.isActiveOn(day)) {
        map[day] = completed.contains(day);
      }
    }

    return map;
  }
}
