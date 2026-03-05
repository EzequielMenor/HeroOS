import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/i_task_repository.dart';
import '../models/task_model.dart';
import '../services/supabase_service.dart';

/// Implementación Supabase del repositorio de tareas.
class TaskRepository implements ITaskRepository {
  final SupabaseClient _client = SupabaseService.client;

  @override
  Future<List<TaskEntity>> getTasks() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .order('is_done')
        .order('due_date', ascending: true);

    return data.map((json) => TaskModel.fromJson(json).toEntity()).toList();
  }

  @override
  Future<void> createTask(TaskEntity task) async {
    final model = TaskModel.fromEntity(task);
    await _client.from('tasks').insert(model.toJson());
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final model = TaskModel.fromEntity(task);
    await _client.from('tasks').update(model.toJson()).eq('id', task.id);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  @override
  Future<void> completeTask(String taskId) async {
    await _client.from('tasks').update({'is_done': true}).eq('id', taskId);
  }

  @override
  Future<void> uncompleteTask(String taskId) async {
    await _client.from('tasks').update({'is_done': false}).eq('id', taskId);
  }
}
