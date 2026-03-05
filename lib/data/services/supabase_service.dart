import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper del cliente Supabase.
/// Expone el singleton de [SupabaseClient] para uso en repositorios.
/// Nunca llames a Supabase directamente desde la UI.
class SupabaseService {
  SupabaseService._();

  /// Cliente ya inicializado por [Supabase.initialize] en main().
  static SupabaseClient get client => Supabase.instance.client;

  /// Usuario autenticado actual. Nulo si no hay sesión.
  static User? get currentUser => client.auth.currentUser;
}
