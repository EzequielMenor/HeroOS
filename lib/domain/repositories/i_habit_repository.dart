import '../entities/habit_entity.dart';
import '../entities/habit_log_entity.dart';

/// Contrato del repositorio de hábitos.
abstract interface class IHabitRepository {
  Future<List<HabitEntity>> getHabits();
  Future<void> createHabit(HabitEntity habit);
  Future<void> updateHabit(HabitEntity habit);
  Future<void> archiveHabit(String habitId);
  Future<void> deleteHabit(String habitId);
  Future<void> logHabitCompletion(String habitId, DateTime date);
  Future<void> uncompleteHabitLog(String habitId, DateTime date);
  Future<List<String>> getCompletedHabitIds(DateTime date);
  Future<List<HabitLogEntity>> getHabitLogsInRange(DateTime from, DateTime to);
}
