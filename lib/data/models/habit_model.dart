import '../../domain/entities/habit_entity.dart';

/// Modelo de datos para serializar/deserializar hábitos desde Supabase.
class HabitModel {
  final String id;
  final String userId;
  final String title;
  final String frequencyMask;
  final int xpReward;
  final int dmgPenalty;
  final int currentStreak;
  final bool isArchived;

  const HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.frequencyMask,
    required this.xpReward,
    required this.dmgPenalty,
    required this.currentStreak,
    required this.isArchived,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) => HabitModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    frequencyMask: (json['frequency_mask'] as String?) ?? '',
    xpReward: (json['xp_reward'] as int?) ?? 10,
    dmgPenalty: (json['dmg_penalty'] as int?) ?? 5,
    currentStreak: (json['current_streak'] as int?) ?? 0,
    isArchived: (json['is_archived'] as bool?) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'frequency_mask': frequencyMask,
    'xp_reward': xpReward,
    'dmg_penalty': dmgPenalty,
    'current_streak': currentStreak,
    'is_archived': isArchived,
  };

  HabitEntity toEntity() => HabitEntity(
    id: id,
    userId: userId,
    title: title,
    frequencyMask: frequencyMask,
    xpReward: xpReward,
    dmgPenalty: dmgPenalty,
    currentStreak: currentStreak,
    isArchived: isArchived,
  );

  factory HabitModel.fromEntity(HabitEntity e) => HabitModel(
    id: e.id,
    userId: e.userId,
    title: e.title,
    frequencyMask: e.frequencyMask,
    xpReward: e.xpReward,
    dmgPenalty: e.dmgPenalty,
    currentStreak: e.currentStreak,
    isArchived: e.isArchived,
  );
}
