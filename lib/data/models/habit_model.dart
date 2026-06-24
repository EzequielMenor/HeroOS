import '../../domain/entities/habit_entity.dart';

/// Data model for serializing/deserializing habits from Supabase.
class HabitModel {
  final String id;
  final String userId;
  final String title;
  final String frequencyMask;
  final int currentStreak;
  final bool isArchived;

  HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.frequencyMask,
    required this.currentStreak,
    required this.isArchived,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) => HabitModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    frequencyMask: (json['frequency_mask'] as String?) ?? '',
    currentStreak: (json['current_streak'] as int?) ?? 0,
    isArchived: (json['is_archived'] as bool?) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'frequency_mask': frequencyMask,
    'current_streak': currentStreak,
    'is_archived': isArchived,
  };

  HabitEntity toEntity() => HabitEntity(
    id: id,
    userId: userId,
    title: title,
    frequencyMask: frequencyMask,
    currentStreak: currentStreak,
    isArchived: isArchived,
  );

  factory HabitModel.fromEntity(HabitEntity e) => HabitModel(
    id: e.id,
    userId: e.userId,
    title: e.title,
    frequencyMask: e.frequencyMask,
    currentStreak: e.currentStreak,
    isArchived: e.isArchived,
  );
}
