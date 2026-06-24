/// Entidad pura de Sueño para la capa de dominio.
class SleepLogEntity {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalHours;
  final int? deepSleepPct;
  final int? lightSleepPct;
  final int? remSleepPct;
  final int? qualityRating;
  final String? notes;
  final int? avgHeartRate;

  SleepLogEntity({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.totalHours,
    this.deepSleepPct,
    this.lightSleepPct,
    this.remSleepPct,
    this.qualityRating,
    this.notes,
    this.avgHeartRate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepLogEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          totalHours == other.totalHours &&
          deepSleepPct == other.deepSleepPct &&
          lightSleepPct == other.lightSleepPct &&
          remSleepPct == other.remSleepPct &&
          qualityRating == other.qualityRating &&
          notes == other.notes &&
          avgHeartRate == other.avgHeartRate;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      totalHours.hashCode ^
      deepSleepPct.hashCode ^
      lightSleepPct.hashCode ^
      remSleepPct.hashCode ^
      qualityRating.hashCode ^
      notes.hashCode ^
      avgHeartRate.hashCode;
}
