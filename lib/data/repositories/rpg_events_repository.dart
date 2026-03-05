import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/rpg_event_entity.dart';
import '../../domain/repositories/i_rpg_events_repository.dart';
import '../services/supabase_service.dart';

/// Implementación Supabase del repositorio de eventos RPG.
class RpgEventsRepository implements IRpgEventsRepository {
  final SupabaseClient _client = SupabaseService.client;

  @override
  Future<void> log(RpgEventType type, int amount, String description) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    await _client.from('rpg_events').insert({
      'user_id': userId,
      'event_type': _typeToString(type),
      'amount': amount,
      'description': description,
    });
  }

  @override
  Future<List<RpgEventEntity>> getRecentEvents({int limit = 20}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('rpg_events')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return data.map(_fromJson).toList();
  }

  RpgEventEntity _fromJson(Map<String, dynamic> json) => RpgEventEntity(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: _typeFromString(json['event_type'] as String),
        amount: json['amount'] as int,
        description: json['description'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  String _typeToString(RpgEventType type) => switch (type) {
        RpgEventType.xpGain => 'xp_gain',
        RpgEventType.xpLoss => 'xp_loss',
        RpgEventType.hpLoss => 'hp_loss',
        RpgEventType.levelUp => 'level_up',
        RpgEventType.gameOver => 'game_over',
      };

  RpgEventType _typeFromString(String type) => switch (type) {
        'xp_gain' => RpgEventType.xpGain,
        'xp_loss' => RpgEventType.xpLoss,
        'hp_loss' => RpgEventType.hpLoss,
        'level_up' => RpgEventType.levelUp,
        'game_over' => RpgEventType.gameOver,
        _ => RpgEventType.xpGain,
      };
}
