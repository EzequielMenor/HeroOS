import '../../domain/entities/habit_log_entity.dart';

/// Modelo de datos para serializar/deserializar logs de hábitos desde Supabase.
class HabitLogModel {
  final String id;
  final String habitId;
  final DateTime date;
  final String status;

  const HabitLogModel({
    required this.id,
    required this.habitId,
    required this.date,
    required this.status,
  });

  factory HabitLogModel.fromJson(Map<String, dynamic> json) => HabitLogModel(
    id: json['id'] as String,
    habitId: json['habit_id'] as String,
    date: DateTime.parse(json['date'] as String),
    status: (json['status'] as String?) ?? 'completed',
  );

  HabitLogEntity toEntity() =>
      HabitLogEntity(id: id, habitId: habitId, date: date, status: status);
}
