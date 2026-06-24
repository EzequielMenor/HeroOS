import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementación concreta usando Supabase Auth.
/// Toda la lógica de autenticación pasa por aquí — la UI nunca
/// llama a Supabase directamente.
///
/// Modo desarrollador: cuando [devQuickAccess] está activo, se salta Supabase
/// y permite acceso instantáneo sin credenciales. Ideal para desarrollo
/// cuando no hay usuarios configurados o Supabase no responde.
class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Modo desarrollador: acceso rápido sin Supabase
  static const bool devQuickAccess = kDebugMode;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  bool get isAuthenticated {
    if (devQuickAccess && _devSessionActive) return true;
    return _client.auth.currentUser != null;
  }

  // Sesión local en modo developer
  bool _devSessionActive = false;

  /// Acceso rápido sin Supabase — solo en modo desarrollador.
  Future<void> devQuickLogin() async {
    if (!devQuickAccess) return;
    _devSessionActive = true;
  }

  /// Cerrar sesión developer.
  Future<void> devQuickLogout() async {
    _devSessionActive = false;
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
