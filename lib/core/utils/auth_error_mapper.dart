/// Traduce los mensajes de error de Supabase Auth al español.
String mapAuthError(String raw) {
  if (raw.contains('Invalid login credentials')) {
    return 'Email o contraseña incorrectos';
  }
  if (raw.contains('User already registered')) {
    return 'Este email ya está registrado';
  }
  if (raw.contains('Email not confirmed')) {
    return 'Verifica tu email antes de iniciar sesión';
  }
  if (raw.contains('Password should be')) {
    return 'La contraseña debe tener al menos 6 caracteres';
  }
  return 'Error inesperado. Inténtalo de nuevo.';
}
