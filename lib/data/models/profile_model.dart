/// Modelo de datos para la tabla `profiles` en Supabase.
/// Mapea 1:1 con las columnas de la BD.
class ProfileModel {
  final String id;
  final String username;
  final int level;
  final int currentXp;
  final int xpNextLevel;
  final int currentHp;
  final int maxHp;
  final double currentGold;
  final String? avatarUrl;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.username,
    required this.level,
    required this.currentXp,
    required this.xpNextLevel,
    required this.currentHp,
    required this.maxHp,
    required this.currentGold,
    this.avatarUrl,
    required this.createdAt,
  });

  /// Deserializa desde un Map (respuesta JSON de Supabase).
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'Hero',
      level: json['level'] as int? ?? 1,
      currentXp: json['current_xp'] as int? ?? 0,
      xpNextLevel: json['xp_next_level'] as int? ?? 100,
      currentHp: json['current_hp'] as int? ?? 100,
      maxHp: json['max_hp'] as int? ?? 100,
      currentGold: (json['current_gold'] as num?)?.toDouble() ?? 0.0,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Serializa a Map para enviar a Supabase (sin id ni created_at).
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'level': level,
      'current_xp': currentXp,
      'xp_next_level': xpNextLevel,
      'current_hp': currentHp,
      'max_hp': maxHp,
      'current_gold': currentGold,
      'avatar_url': avatarUrl,
    };
  }
}
