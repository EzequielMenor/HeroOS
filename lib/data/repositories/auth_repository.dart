import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementación concreta usando Supabase Auth.
/// Toda la lógica de autenticación pasa por aquí — la UI nunca
/// llama a Supabase directamente.
class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  bool get isAuthenticated => _client.auth.currentUser != null;

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
