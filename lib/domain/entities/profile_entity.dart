/// Entidad de dominio pura del héroe.
/// Sin dependencias externas — solo Dart puro.
/// Toda la lógica RPG vive aquí, separada de Supabase y la UI.
class ProfileEntity {
  final String id;
  final String username;
  final int level;
  final int currentXp;
  final int xpNextLevel;
  final int currentHp;
  final int maxHp;
  final double currentGold;
  final String? avatarUrl;

  const ProfileEntity({
    required this.id,
    required this.username,
    required this.level,
    required this.currentXp,
    required this.xpNextLevel,
    required this.currentHp,
    required this.maxHp,
    required this.currentGold,
    this.avatarUrl,
  });

  // --- Getters calculados ---

  /// XP como fracción del nivel actual (0.0 a 1.0).
  double get xpProgress =>
      xpNextLevel > 0 ? (currentXp / xpNextLevel).clamp(0.0, 1.0) : 0.0;

  /// HP como fracción del máximo (0.0 a 1.0).
  double get hpProgress =>
      maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0.0;

  bool get isAlive => currentHp > 0;

  // --- Business Logic Methods ---

  /// Aplica ganancia de XP y procesa Level Up si procede.
  /// Retorna la nueva entidad y si se activó Level Up.
  ({ProfileEntity profile, bool didLevelUp}) gainXp(int amount) {
    final newXp = currentXp + amount;

    if (newXp >= xpNextLevel) {
      // LEVEL UP: incrementar nivel, resetear XP y escalar el objetivo.
      return (
        profile: copyWith(
          level: level + 1,
          currentXp: newXp - xpNextLevel,
          xpNextLevel: (xpNextLevel * 1.5).round(),
          // Level Up bonus: +10 HP máx por nivel
          maxHp: maxHp + 10,
          currentHp: maxHp + 10, // Curación completa al subir nivel
        ),
        didLevelUp: true,
      );
    }

    return (profile: copyWith(currentXp: newXp), didLevelUp: false);
  }

  /// Resta XP sin afectar al HP (corrección de usuario, no penalización).
  ProfileEntity loseXp(int amount) {
    final newXp = (currentXp - amount).clamp(0, xpNextLevel);
    return copyWith(currentXp: newXp);
  }

  /// Aplica daño al HP. Si llega a 0 → Game Over: reset a nivel 1.
  ({ProfileEntity profile, bool isGameOver}) takeDamage(int amount) {
    final newHp = (currentHp - amount).clamp(0, maxHp);

    if (newHp <= 0) {
      // GAME OVER: resetear al nivel 1
      return (
        profile: copyWith(
          level: 1,
          currentXp: 0,
          xpNextLevel: 100,
          currentHp: maxHp,
        ),
        isGameOver: true,
      );
    }

    return (profile: copyWith(currentHp: newHp), isGameOver: false);
  }

  /// Añade oro al balance.
  ProfileEntity addGold(double amount) =>
      copyWith(currentGold: currentGold + amount);

  // --- CopyWith ---
  ProfileEntity copyWith({
    String? username,
    int? level,
    int? currentXp,
    int? xpNextLevel,
    int? currentHp,
    int? maxHp,
    double? currentGold,
    String? avatarUrl,
  }) {
    return ProfileEntity(
      id: id,
      username: username ?? this.username,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      xpNextLevel: xpNextLevel ?? this.xpNextLevel,
      currentHp: currentHp ?? this.currentHp,
      maxHp: maxHp ?? this.maxHp,
      currentGold: currentGold ?? this.currentGold,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
