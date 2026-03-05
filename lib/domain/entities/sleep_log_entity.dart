import 'package:equatable/equatable.dart';

/// Entidad pura de Sueño para la capa de dominio.
class SleepLogEntity extends Equatable {
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

  const SleepLogEntity({
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
  List<Object?> get props => [
    id,
    userId,
    startTime,
    endTime,
    totalHours,
    deepSleepPct,
    lightSleepPct,
    remSleepPct,
    qualityRating,
    notes,
    avgHeartRate,
  ];
}
