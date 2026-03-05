/// Tipos de evento RPG registrables en el feed de actividad.
enum RpgEventType { xpGain, xpLoss, hpLoss, levelUp, gameOver }

/// Entidad de dominio para un evento RPG cronológico.
class RpgEventEntity {
  final String id;
  final String userId;
  final RpgEventType type;
  final int amount;
  final String description;
  final DateTime createdAt;

  const RpgEventEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
  });
}
