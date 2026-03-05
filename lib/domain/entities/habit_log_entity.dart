/// Entidad de dominio pura para un registro individual de completado de hábito.
class HabitLogEntity {
  final String id;
  final String habitId;
  final DateTime date;
  final String status;

  const HabitLogEntity({
    required this.id,
    required this.habitId,
    required this.date,
    required this.status,
  });
}
