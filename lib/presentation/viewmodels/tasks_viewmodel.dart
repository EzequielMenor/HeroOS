import 'package:flutter/material.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/entities/task_entity.dart';
import 'stats_viewmodel.dart';

/// ViewModel de Tareas (Misiones).
/// CRUD + integración RPG: completar tarea → XP gain.
class TasksViewModel extends ChangeNotifier {
  final TaskRepository _repo = TaskRepository();
  final StatsViewModel _statsVm;

  List<TaskEntity> _tasks = [];
  bool _isLoading = false;
  String? _error;

  TasksViewModel(this._statsVm);

  List<TaskEntity> get tasks => _tasks;
  List<TaskEntity> get pendingTasks => _tasks.where((t) => !t.isDone).toList();
  List<TaskEntity> get doneTasks => _tasks.where((t) => t.isDone).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carga todas las tareas del usuario.
  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _tasks = await _repo.getTasks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Completa una tarea: marca is_done + XP gain.
  Future<void> completeTask(TaskEntity task) async {
    if (task.isDone) return;
    try {
      await _repo.completeTask(task.id);
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = task.copyWith(isDone: true);
        notifyListeners();
      }
      // Integración RPG
      await _statsVm.applyXpGain(
        task.xpValue,
        description: 'Tarea completada: ${task.title}',
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Crea una nueva tarea.
  Future<void> createTask({
    required String title,
    DateTime? dueDate,
    int difficulty = 1,
  }) async {
    final userId = _statsVm.profile?.id;
    if (userId == null) return;

    final task = TaskEntity(
      id: '',
      userId: userId,
      title: title,
      dueDate: dueDate,
      difficulty: difficulty,
    );
    try {
      await _repo.createTask(task);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Elimina una tarea.
  Future<void> deleteTask(String taskId) async {
    try {
      await _repo.deleteTask(taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Actualiza una tarea (título, dificultad, fecha).
  Future<void> updateTask(TaskEntity task) async {
    try {
      await _repo.updateTask(task);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Desmarca una tarea completada → revierte XP.
  Future<void> uncompleteTask(TaskEntity task) async {
    if (!task.isDone) return;
    try {
      await _repo.uncompleteTask(task.id);
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = task.copyWith(isDone: false);
        notifyListeners();
      }
      // Revertir XP
      await _statsVm.applyXpLoss(
        task.xpValue,
        description: 'Tarea desmarcada: ${task.title}',
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
