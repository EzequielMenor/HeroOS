import 'package:flutter/material.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/habit_analytics.dart';
import 'stats_viewmodel.dart';

/// ViewModel de Hábitos.
/// Gestiona CRUD y la integración con el motor RPG via [StatsViewModel].
class HabitsViewModel extends ChangeNotifier {
  final HabitRepository _repo = HabitRepository();
  final StatsViewModel _statsVm;

  List<HabitEntity> _habits = [];
  Set<String> _completedTodayIds = {};
  HabitAnalytics? _analytics;
  bool _isLoading = false;
  String? _error;

  HabitsViewModel(this._statsVm);

  List<HabitEntity> get habits => _habits;
  Set<String> get completedTodayIds => _completedTodayIds;
  HabitAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Hábitos activos para hoy.
  List<HabitEntity> get todayHabits {
    final now = DateTime.now();
    return _habits.where((h) => h.isActiveOn(now)).toList();
  }

  /// Carga todos los hábitos y los completados de hoy.
  Future<void> loadHabits() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _habits = await _repo.getHabits();
      _completedTodayIds = (await _repo.getCompletedHabitIds(
        DateTime.now(),
      )).toSet();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Cargar analíticas en background (no bloquea la UI)
    await loadAnalytics();
  }

  /// Completa un hábito: log + XP gain.
  Future<void> completeHabit(HabitEntity habit) async {
    try {
      await _repo.logHabitCompletion(habit.id, DateTime.now());
      _completedTodayIds.add(habit.id);
      notifyListeners();
      // Integración RPG: ganar XP
      await _statsVm.applyXpGain(
        habit.xpReward,
        description: 'Hábito completado: ${habit.title}',
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Crea un nuevo hábito.
  Future<void> createHabit({
    required String title,
    required String frequencyMask,
    int xpReward = 10,
    int dmgPenalty = 5,
  }) async {
    final userId = _statsVm.profile?.id;
    if (userId == null) return;

    final habit = HabitEntity(
      id: '', // Supabase genera el UUID
      userId: userId,
      title: title,
      frequencyMask: frequencyMask,
      xpReward: xpReward,
      dmgPenalty: dmgPenalty,
    );
    try {
      await _repo.createHabit(habit);
      await loadHabits();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Carga las analíticas de hábitos (últimos 365 días).
  /// No es crítico — si falla, la app sigue funcionando sin stats.
  Future<void> loadAnalytics() async {
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 365));
      final logs = await _repo.getHabitLogsInRange(from, now);
      _analytics = HabitAnalytics(habits: _habits, logs: logs);
      notifyListeners();
    } catch (_) {
      _analytics = null;
    }
  }

  /// Archiva (soft delete) un hábito.
  Future<void> archiveHabit(String habitId) async {
    try {
      await _repo.archiveHabit(habitId);
      _habits.removeWhere((h) => h.id == habitId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool isCompletedToday(String habitId) => _completedTodayIds.contains(habitId);

  /// Actualiza un hábito existente (nombre, frecuencia, etc.).
  Future<void> updateHabit(HabitEntity habit) async {
    try {
      await _repo.updateHabit(habit);
      await loadHabits();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Elimina permanentemente un hábito.
  Future<void> deleteHabit(String habitId) async {
    try {
      await _repo.deleteHabit(habitId);
      _habits.removeWhere((h) => h.id == habitId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Desmarca un hábito completado hoy → revierte XP y streak.
  Future<void> uncompleteHabit(HabitEntity habit) async {
    try {
      await _repo.uncompleteHabitLog(habit.id, DateTime.now());
      _completedTodayIds.remove(habit.id);
      notifyListeners();
      // Revertir XP ganada
      await _statsVm.applyXpLoss(
        habit.xpReward,
        description: 'Hábito desmarcado: ${habit.title}',
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
