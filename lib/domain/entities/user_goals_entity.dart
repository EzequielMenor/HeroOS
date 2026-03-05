/// Entidad de dominio pura para los objetivos personales del héroe.
/// Define las metas que alimentan la gamificación de cada módulo:
///   - [sleepHoursTarget]   → XP de sueño
///   - [minHabitsDaily]     → Evaluación diaria de hábitos
///   - [maxMonthlySpending] → Alerta de presupuesto en finanzas
class UserGoalsEntity {
  final String id;
  final String userId;

  /// Horas de sueño objetivo por noche (default: 8).
  final double sleepHoursTarget;

  /// Mínimo de hábitos a completar al día (default: 3).
  final int minHabitsDaily;

  /// Presupuesto mensual máximo en euros (default: 500).
  final double maxMonthlySpending;

  const UserGoalsEntity({
    required this.id,
    required this.userId,
    this.sleepHoursTarget = 8.0,
    this.minHabitsDaily = 3,
    this.maxMonthlySpending = 500.0,
  });

  UserGoalsEntity copyWith({
    double? sleepHoursTarget,
    int? minHabitsDaily,
    double? maxMonthlySpending,
  }) {
    return UserGoalsEntity(
      id: id,
      userId: userId,
      sleepHoursTarget: sleepHoursTarget ?? this.sleepHoursTarget,
      minHabitsDaily: minHabitsDaily ?? this.minHabitsDaily,
      maxMonthlySpending: maxMonthlySpending ?? this.maxMonthlySpending,
    );
  }
}
