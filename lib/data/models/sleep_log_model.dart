import '../../domain/entities/sleep_log_entity.dart';

/// Modelo de datos para serializar/deserializar registros de sueño desde Supabase.
class SleepLogModel {
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

  const SleepLogModel({
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

  factory SleepLogModel.fromJson(Map<String, dynamic> json) => SleepLogModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    startTime: DateTime.parse(json['start_time'] as String),
    endTime: DateTime.parse(json['end_time'] as String),
    totalHours: (json['total_hours'] as num).toDouble(),
    deepSleepPct: json['deep_sleep_pct'] as int?,
    lightSleepPct: json['light_sleep_pct'] as int?,
    remSleepPct: json['rem_sleep_pct'] as int?,
    qualityRating: json['quality_rating'] as int?,
    notes: json['notes'] as String?,
    avgHeartRate: json['avg_heart_rate'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'total_hours': totalHours,
    'deep_sleep_pct': deepSleepPct,
    'light_sleep_pct': lightSleepPct,
    'rem_sleep_pct': remSleepPct,
    'quality_rating': qualityRating,
    'notes': notes,
    'avg_heart_rate': avgHeartRate,
  };

  SleepLogEntity toEntity() => SleepLogEntity(
    id: id,
    userId: userId,
    startTime: startTime,
    endTime: endTime,
    totalHours: totalHours,
    deepSleepPct: deepSleepPct,
    lightSleepPct: lightSleepPct,
    remSleepPct: remSleepPct,
    qualityRating: qualityRating,
    notes: notes,
    avgHeartRate: avgHeartRate,
  );

  factory SleepLogModel.fromEntity(SleepLogEntity e) => SleepLogModel(
    id: e.id,
    userId: e.userId,
    startTime: e.startTime,
    endTime: e.endTime,
    totalHours: e.totalHours,
    deepSleepPct: e.deepSleepPct,
    lightSleepPct: e.lightSleepPct,
    remSleepPct: e.remSleepPct,
    qualityRating: e.qualityRating,
    notes: e.notes,
    avgHeartRate: e.avgHeartRate,
  );
}
