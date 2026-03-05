import '../../domain/entities/task_entity.dart';

/// Modelo de datos para serializar/deserializar tareas desde Supabase.
class TaskModel {
  final String id;
  final String userId;
  final String title;
  final bool isDone;
  final DateTime? dueDate;
  final int difficulty;
  final int xpValue;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.isDone,
    this.dueDate,
    required this.difficulty,
    required this.xpValue,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    isDone: (json['is_done'] as bool?) ?? false,
    dueDate: json['due_date'] != null
        ? DateTime.parse(json['due_date'] as String)
        : null,
    difficulty: (json['difficulty'] as int?) ?? 1,
    xpValue: (json['xp_value'] as int?) ?? 10,
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'is_done': isDone,
    'due_date': dueDate?.toIso8601String(),
    'difficulty': difficulty,
    // xp_value es GENERATED ALWAYS en Supabase → no se inserta
  };

  TaskEntity toEntity() => TaskEntity(
    id: id,
    userId: userId,
    title: title,
    isDone: isDone,
    dueDate: dueDate,
    difficulty: difficulty,
  );

  factory TaskModel.fromEntity(TaskEntity e) => TaskModel(
    id: e.id,
    userId: e.userId,
    title: e.title,
    isDone: e.isDone,
    dueDate: e.dueDate,
    difficulty: e.difficulty,
    xpValue: e.xpValue,
  );
}
