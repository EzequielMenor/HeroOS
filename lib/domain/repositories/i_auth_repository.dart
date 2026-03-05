/// Interfaz abstracta del repositorio de autenticación.
/// La implementación concreta (Supabase) irá en data/repositories/ en EZE-95.
/// Esto desacopla el Domain Layer del proveedor externo.
abstract interface class IAuthRepository {
  /// Inicia sesión con email y contraseña.
  Future<void> signIn({required String email, required String password});

  /// Registra un nuevo usuario.
  Future<void> signUp({required String email, required String password});

  /// Cierra la sesión actual.
  Future<void> signOut();

  /// True si hay un usuario autenticado.
  bool get isAuthenticated;

  /// Envía un email de recuperación de contraseña.
  Future<void> resetPassword(String email);
}
