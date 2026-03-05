import 'package:flutter/material.dart';

import '../../data/repositories/sleep_repository.dart';
import '../../domain/entities/sleep_analytics.dart';
import '../../domain/entities/sleep_log_entity.dart';
import 'stats_viewmodel.dart';

class SleepViewModel extends ChangeNotifier {
  final SleepRepository _repo = SleepRepository();
  final StatsViewModel _statsVm;

  List<SleepLogEntity> _logs = [];
  SleepLogEntity? _todayLog;
  SleepAnalytics? _analytics;
  bool _isLoading = false;
  String? _error;

  SleepViewModel(this._statsVm);

  List<SleepLogEntity> get logs => _logs;
  SleepLogEntity? get todayLog => _todayLog;
  SleepAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carga todos los registros + el log de hoy + analíticas.
  Future<void> loadLogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _logs = await _repo.getSleepLogs();
      _todayLog = await _repo.getTodayLog();
      _analytics = SleepAnalytics(logs: _logs);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Guarda un registro de sueño (upsert: crea o actualiza).
  /// Si se pasa [existingId], actualiza ese registro específico (editar historial).
  /// Si no, hace upsert del log de hoy.
  Future<void> saveSleepLog({
    String? existingId,
    required DateTime startTime,
    required DateTime endTime,
    int? deepSleepPct,
    int? lightSleepPct,
    int? remSleepPct,
    int? qualityRating,
    String? notes,
    int? avgHeartRate,
  }) async {
    final userId = _statsVm.profile?.id;
    if (userId == null) return;

    // Si la hora de despertar es anterior a la de acostarse, el usuario
    // durmió pasando la medianoche: retrocedemos startTime al día anterior
    // para que el registro quede en el día en que se despertó (endTime).
    final adjustedStart =
        endTime.isBefore(startTime) ? startTime.subtract(const Duration(days: 1)) : startTime;
    final duration = endTime.difference(adjustedStart);
    final totalHours = duration.inMinutes / 60.0;

    // Decidir si es update o create
    final idToUpdate = existingId ?? _todayLog?.id;

    final log = SleepLogEntity(
      id: idToUpdate ?? '',
      userId: userId,
      startTime: adjustedStart,
      endTime: endTime,
      totalHours: totalHours,
      deepSleepPct: deepSleepPct,
      lightSleepPct: lightSleepPct,
      remSleepPct: remSleepPct,
      qualityRating: qualityRating,
      notes: notes,
      avgHeartRate: avgHeartRate,
    );

    try {
      if (idToUpdate != null && idToUpdate.isNotEmpty) {
        await _repo.updateSleepLog(log);
      } else {
        await _repo.createSleepLog(log);
      }

      await loadLogs();

      // Gamificación: +10 XP por dormir bien (≥7h + calidad ≥4)
      if (totalHours >= 7 && (qualityRating ?? 0) >= 4) {
        await _statsVm.applyXpGain(10);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Elimina un registro de sueño.
  Future<void> deleteSleepLog(String logId) async {
    try {
      await _repo.deleteSleepLog(logId);
      await loadLogs();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
