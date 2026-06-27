import 'sync_status.dart';

/// Domain entity for tasks.
/// Energy enum replaces difficulty for Zen OS pivot.
/// XP mechanics removed.
enum Energy { low, medium, high }

/// Duration for task focus/block time.
enum FocusDuration { micro, short, deep }

/// Domain entity for tasks (missions).
class TaskEntity {
  final String id;
  final String userId;
  final String title;
  final bool isDone;
  final DateTime? dueDate;
  final Energy? energy;
  final SyncStatus? syncStatus;
  final String? noteId;
  final bool isHighlight;
  final FocusDuration? duration;

  TaskEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.isDone = false,
    this.dueDate,
    this.energy,
    this.syncStatus,
    this.noteId,
    this.isHighlight = false,
    this.duration,
  });

  /// Is this task overdue?
  bool get isOverdue =>
      dueDate != null && !isDone && dueDate!.isBefore(DateTime.now());

  TaskEntity copyWith({
    String? title,
    bool? isDone,
    DateTime? dueDate,
    Energy? energy,
    SyncStatus? syncStatus,
    String? noteId,
    bool? isHighlight,
    FocusDuration? duration,
  }) {
    return TaskEntity(
      id: id,
      userId: userId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate ?? this.dueDate,
      energy: energy ?? this.energy,
      syncStatus: syncStatus ?? this.syncStatus,
      noteId: noteId ?? this.noteId,
      isHighlight: isHighlight ?? this.isHighlight,
      duration: duration ?? this.duration,
    );
  }
}
