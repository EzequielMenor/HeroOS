import '../entities/task_entity.dart';

/// Contrato del repositorio de tareas (misiones).
abstract interface class ITaskRepository {
  Future<List<TaskEntity>> getTasks();
  Future<void> createTask(TaskEntity task);
  Future<void> updateTask(TaskEntity task);
  Future<void> deleteTask(String taskId);
  Future<void> completeTask(String taskId);
  Future<void> uncompleteTask(String taskId);
}
