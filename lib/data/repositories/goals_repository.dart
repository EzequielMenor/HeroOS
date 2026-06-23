import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_goals_entity.dart';
import '../models/user_goals_model.dart';

/// Implementación concreta con Supabase.
class GoalsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserGoalsEntity> getGoals() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay usuario autenticado');

    final response = await _client
        .from('user_goals')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      return UserGoalsModel.fromJson(response).toEntity();
    }

    // Primera vez: insertar objetivos por defecto
    return _createDefaultGoals(userId);
  }

  Future<UserGoalsEntity> _createDefaultGoals(String userId) async {
    final response = await _client
        .from('user_goals')
        .insert({'user_id': userId})
        .select()
        .single();

    return UserGoalsModel.fromJson(response).toEntity();
  }

  Future<void> updateGoals(UserGoalsEntity goals) async {
    await _client
        .from('user_goals')
        .update({
          'sleep_hours_target': goals.sleepHoursTarget,
          'min_habits_daily': goals.minHabitsDaily,
          'max_monthly_spending': goals.maxMonthlySpending,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', goals.id);
  }
}
