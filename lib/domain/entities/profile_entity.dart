/// Domain entity for user profile.
/// Minimal fields: id, username, avatar, and AI configuration.
/// RPG fields removed for Zen OS pivot.
class ProfileEntity {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? aiApiKey;
  final String aiProvider;

  const ProfileEntity({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.aiApiKey,
    this.aiProvider = 'openai',
  });

  ProfileEntity copyWith({
    String? username,
    String? avatarUrl,
    String? aiApiKey,
    String? aiProvider,
  }) {
    return ProfileEntity(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      aiProvider: aiProvider ?? this.aiProvider,
    );
  }
}
