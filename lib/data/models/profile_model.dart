/// Data model for the `profiles` table in Supabase.
class ProfileModel {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? aiApiKey;
  final String aiProvider;

  ProfileModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.aiApiKey,
    this.aiProvider = 'openai',
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'User',
      avatarUrl: json['avatar_url'] as String?,
      aiApiKey: json['ai_api_key'] as String?,
      aiProvider: json['ai_provider'] as String? ?? 'openai',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'avatar_url': avatarUrl,
      'ai_api_key': aiApiKey,
      'ai_provider': aiProvider,
    };
  }
}
