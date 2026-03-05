import '../entities/user_goals_entity.dart';

/// Interface del repositorio de objetivos del héroe.
/// El Domain Layer solo conoce esta abstracción, nunca la implementación Supabase.
abstract interface class IGoalsRepository {
  /// Obtiene los objetivos del usuario autenticado.
  /// Si no existen, crea y devuelve los valores por defecto.
  Future<UserGoalsEntity> getGoals();

  /// Persiste los objetivos actualizados.
  Future<void> updateGoals(UserGoalsEntity goals);
}
