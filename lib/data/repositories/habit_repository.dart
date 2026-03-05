import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/habit_log_entity.dart';
import '../../domain/repositories/i_habit_repository.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../services/supabase_service.dart';

/// Implementación Supabase del repositorio de hábitos.
class HabitRepository implements IHabitRepository {
  final SupabaseClient _client = SupabaseService.client;

  @override
  Future<List<HabitEntity>> getHabits() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('habits')
        .select()
        .eq('user_id', userId)
        .eq('is_archived', false)
        .order('title');

    return data.map((json) => HabitModel.fromJson(json).toEntity()).toList();
  }

  @override
  Future<void> createHabit(HabitEntity habit) async {
    final model = HabitModel.fromEntity(habit);
    await _client.from('habits').insert(model.toJson());
  }

  @override
  Future<void> updateHabit(HabitEntity habit) async {
    final model = HabitModel.fromEntity(habit);
    await _client.from('habits').update(model.toJson()).eq('id', habit.id);
  }

  @override
  Future<void> archiveHabit(String habitId) async {
    await _client
        .from('habits')
        .update({'is_archived': true})
        .eq('id', habitId);
  }

  @override
  Future<void> logHabitCompletion(String habitId, DateTime date) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    await _client.from('habit_logs').insert({
      'user_id': userId,
      'habit_id': habitId,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'status': 'completed',
    });

    // Incrementar streak
    await _client.rpc('increment_streak', params: {'habit_id_param': habitId});
  }

  @override
  Future<List<String>> getCompletedHabitIds(DateTime date) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final data = await _client
        .from('habit_logs')
        .select('habit_id')
        .eq('user_id', userId)
        .eq('date', dateStr)
        .eq('status', 'completed');

    return data.map<String>((row) => row['habit_id'] as String).toList();
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await _client.from('habits').delete().eq('id', habitId);
  }

  @override
  Future<void> uncompleteHabitLog(String habitId, DateTime date) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    await _client
        .from('habit_logs')
        .delete()
        .eq('user_id', userId)
        .eq('habit_id', habitId)
        .eq('date', dateStr);

    // Decrementar streak
    await _client.rpc('decrement_streak', params: {'habit_id_param': habitId});
  }

  @override
  Future<List<HabitLogEntity>> getHabitLogsInRange(
    DateTime from,
    DateTime to,
  ) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final fromStr =
        '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
    final toStr =
        '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';

    final data = await _client
        .from('habit_logs')
        .select()
        .eq('user_id', userId)
        .gte('date', fromStr)
        .lte('date', toStr)
        .order('date');

    return data.map((j) => HabitLogModel.fromJson(j).toEntity()).toList();
  }
}
