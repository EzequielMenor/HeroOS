import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/sleep_log_entity.dart';
import '../../domain/repositories/i_sleep_repository.dart';
import '../models/sleep_log_model.dart';
import '../services/supabase_service.dart';

class SleepRepository implements ISleepRepository {
  final SupabaseClient _client = SupabaseService.client;

  @override
  Future<List<SleepLogEntity>> getSleepLogs() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('sleep_logs')
        .select()
        .eq('user_id', userId)
        .order('start_time', ascending: false);

    return data.map((j) => SleepLogModel.fromJson(j).toEntity()).toList();
  }

  @override
  Future<SleepLogEntity?> getTodayLog() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final data = await _client
        .from('sleep_logs')
        .select()
        .eq('user_id', userId)
        .gte('end_time', startOfDay.toIso8601String())
        .lt('end_time', endOfDay.toIso8601String())
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return SleepLogModel.fromJson(data).toEntity();
  }

  @override
  Future<void> createSleepLog(SleepLogEntity log) async {
    final model = SleepLogModel.fromEntity(log);
    final json = model.toJson();
    // El ID lo genera Supabase si es nuevo
    await _client.from('sleep_logs').insert(json);
  }

  @override
  Future<void> updateSleepLog(SleepLogEntity log) async {
    final model = SleepLogModel.fromEntity(log);
    await _client.from('sleep_logs').update(model.toJson()).eq('id', log.id);
  }

  @override
  Future<void> deleteSleepLog(String logId) async {
    await _client.from('sleep_logs').delete().eq('id', logId);
  }
}
