import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/task_entity.dart';
import '../models/task_model.dart';

/// Implementación Supabase del repositorio de tareas.
class TaskRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<TaskEntity>> getTasks() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .order('is_done')
        .order('due_date', ascending: true);

    return data.map((json) => TaskModel.fromJson(json).toEntity()).toList();
  }

  Future<void> createTask(TaskEntity task) async {
    final model = TaskModel.fromEntity(task);
    await _client.from('tasks').insert(model.toJson());
  }

  Future<void> updateTask(TaskEntity task) async {
    final model = TaskModel.fromEntity(task);
    await _client.from('tasks').update(model.toJson()).eq('id', task.id);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  Future<void> completeTask(String taskId) async {
    await _client.from('tasks').update({'is_done': true}).eq('id', taskId);
  }

  Future<void> uncompleteTask(String taskId) async {
    await _client.from('tasks').update({'is_done': false}).eq('id', taskId);
  }
}
