import '../entities/profile_entity.dart';

/// Interface del repositorio de perfil de héroe.
/// El Domain Layer solo conoce esta abstracción, nunca la implementación Supabase.
abstract interface class IProfileRepository {
  /// Carga el perfil del usuario autenticado actual.
  Future<ProfileEntity?> getProfile();

  /// Persiste el estado actualizado del perfil.
  Future<void> updateProfile(ProfileEntity profile);
}
