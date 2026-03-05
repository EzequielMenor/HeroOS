import '../entities/rpg_event_entity.dart';

abstract class IRpgEventsRepository {
  /// Registra un evento RPG para el usuario autenticado.
  Future<void> log(RpgEventType type, int amount, String description);

  /// Devuelve los últimos [limit] eventos ordenados por fecha descendente.
  Future<List<RpgEventEntity>> getRecentEvents({int limit = 20});
}
