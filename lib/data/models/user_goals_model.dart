import '../../domain/entities/user_goals_entity.dart';

/// Modelo de datos para la tabla `user_goals` en Supabase.
/// Mapea 1:1 con las columnas de la BD.
class UserGoalsModel {
  final String id;
  final String userId;
  final double sleepHoursTarget;
  final int minHabitsDaily;
  final double maxMonthlySpending;

  const UserGoalsModel({
    required this.id,
    required this.userId,
    required this.sleepHoursTarget,
    required this.minHabitsDaily,
    required this.maxMonthlySpending,
  });

  factory UserGoalsModel.fromJson(Map<String, dynamic> json) {
    return UserGoalsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sleepHoursTarget:
          (json['sleep_hours_target'] as num?)?.toDouble() ?? 8.0,
      minHabitsDaily: json['min_habits_daily'] as int? ?? 3,
      maxMonthlySpending:
          (json['max_monthly_spending'] as num?)?.toDouble() ?? 500.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'sleep_hours_target': sleepHoursTarget,
    'min_habits_daily': minHabitsDaily,
    'max_monthly_spending': maxMonthlySpending,
  };

  UserGoalsEntity toEntity() => UserGoalsEntity(
    id: id,
    userId: userId,
    sleepHoursTarget: sleepHoursTarget,
    minHabitsDaily: minHabitsDaily,
    maxMonthlySpending: maxMonthlySpending,
  );

  static UserGoalsModel fromEntity(UserGoalsEntity e) => UserGoalsModel(
    id: e.id,
    userId: e.userId,
    sleepHoursTarget: e.sleepHoursTarget,
    minHabitsDaily: e.minHabitsDaily,
    maxMonthlySpending: e.maxMonthlySpending,
  );
}
