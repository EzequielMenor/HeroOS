import '../../domain/entities/task_entity.dart';

/// Data model for serializing/deserializing tasks from Supabase.
class TaskModel {
  final String id;
  final String userId;
  final String title;
  final bool isDone;
  final DateTime? dueDate;
  final Energy? energy;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.isDone,
    this.dueDate,
    this.energy,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final energyStr = json['energy'] as String?;
    Energy? energy;
    if (energyStr != null) {
      energy = Energy.values.firstWhere(
        (e) => e.name == energyStr,
        orElse: () => Energy.medium,
      );
    }
    return TaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      isDone: (json['is_done'] as bool?) ?? false,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      energy: energy,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'is_done': isDone,
    'due_date': dueDate?.toIso8601String(),
    'energy': energy?.name,
  };

  TaskEntity toEntity() => TaskEntity(
    id: id,
    userId: userId,
    title: title,
    isDone: isDone,
    dueDate: dueDate,
    energy: energy,
  );

  factory TaskModel.fromEntity(TaskEntity e) => TaskModel(
    id: e.id,
    userId: e.userId,
    title: e.title,
    isDone: e.isDone,
    dueDate: e.dueDate,
    energy: e.energy,
  );
}
