/// Entidad de dominio pura para Tareas (Misiones).
/// xpValue se calcula como difficulty × 10 → single source of truth.
class TaskEntity {
  final String id;
  final String userId;
  final String title;
  final bool isDone;
  final DateTime? dueDate;
  final int difficulty; // 1=Easy, 2=Medium, 3=Hard

  const TaskEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.isDone = false,
    this.dueDate,
    this.difficulty = 1,
  });

  /// XP que otorga al completarse (calculado, no almacenado).
  int get xpValue => difficulty * 10;

  /// ¿Está vencida?
  bool get isOverdue =>
      dueDate != null && !isDone && dueDate!.isBefore(DateTime.now());

  TaskEntity copyWith({
    String? title,
    bool? isDone,
    DateTime? dueDate,
    int? difficulty,
  }) {
    return TaskEntity(
      id: id,
      userId: userId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate ?? this.dueDate,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}
