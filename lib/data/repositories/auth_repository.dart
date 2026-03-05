import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../services/supabase_service.dart';

/// Implementación concreta de [IAuthRepository] usando Supabase Auth.
/// Toda la lógica de autenticación pasa por aquí — la UI nunca
/// llama a Supabase directamente.
class AuthRepository implements IAuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  bool get isAuthenticated => _client.auth.currentUser != null;

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
