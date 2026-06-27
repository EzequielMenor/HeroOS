import '../../domain/entities/sync_status.dart';
import '../../domain/entities/task_entity.dart';

/// Data model for serializing/deserializing tasks from Supabase.
class TaskModel {
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

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.isDone,
    this.dueDate,
    this.energy,
    this.syncStatus,
    this.noteId,
    this.isHighlight = false,
    this.duration,
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
    SyncStatus? syncStatus;
    final syncStatusStr = json['sync_status'] as String?;
    if (syncStatusStr != null) {
      syncStatus = SyncStatus.values.firstWhere(
        (s) => s.name == syncStatusStr,
        orElse: () => SyncStatus.completed,
      );
    }
    final durationStr = json['duration'] as String?;
    FocusDuration? duration;
    if (durationStr != null) {
      duration = FocusDuration.values.firstWhere(
        (d) => d.name == durationStr,
        orElse: () => FocusDuration.short,
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
      syncStatus: syncStatus,
      noteId: json['note_id'] as String?,
      isHighlight: json['is_highlight'] as bool? ?? false,
      duration: duration,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'is_done': isDone,
    'due_date': dueDate?.toIso8601String(),
    'energy': energy?.name,
    if (syncStatus != null) 'sync_status': syncStatus!.name,
    'note_id': noteId,
    'is_highlight': isHighlight,
    'duration': duration?.name,
  };

  TaskEntity toEntity() => TaskEntity(
    id: id,
    userId: userId,
    title: title,
    isDone: isDone,
    dueDate: dueDate,
    energy: energy,
    syncStatus: syncStatus,
    noteId: noteId,
    isHighlight: isHighlight,
    duration: duration,
  );

  factory TaskModel.fromEntity(TaskEntity e) => TaskModel(
    id: e.id,
    userId: e.userId,
    title: e.title,
    isDone: e.isDone,
    dueDate: e.dueDate,
    energy: e.energy,
    syncStatus: e.syncStatus,
    noteId: e.noteId,
    isHighlight: e.isHighlight,
    duration: e.duration,
  );
}
