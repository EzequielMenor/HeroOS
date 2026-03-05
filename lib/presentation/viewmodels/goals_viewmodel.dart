import 'package:flutter/material.dart';

import '../../data/repositories/goals_repository.dart';
import '../../domain/entities/user_goals_entity.dart';

/// ViewModel de Objetivos del héroe.
/// Gestiona carga y persistencia de [UserGoalsEntity].
class GoalsViewModel extends ChangeNotifier {
  final GoalsRepository _repo = GoalsRepository();

  UserGoalsEntity? _goals;
  bool _isLoading = false;
  String? _error;

  UserGoalsEntity? get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carga los objetivos del usuario autenticado.
  /// Si no existen, crea los valores por defecto en Supabase.
  Future<void> loadGoals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _goals = await _repo.getGoals();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Persiste los objetivos actualizados y notifica a la UI.
  Future<void> updateGoals(UserGoalsEntity goals) async {
    _goals = goals;
    notifyListeners();
    await _repo.updateGoals(goals);
  }
}
