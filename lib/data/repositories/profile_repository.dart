import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/profile_entity.dart';
import '../models/profile_model.dart';

/// Concrete implementation using Supabase.
class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<ProfileEntity?> getProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;

    final model = ProfileModel.fromJson(response);
    return _modelToEntity(model);
  }

  Future<void> updateProfile(ProfileEntity profile) async {
    await _client
        .from('profiles')
        .update({
          'username': profile.username,
          'ai_api_key': profile.aiApiKey,
          'ai_provider': profile.aiProvider,
        })
        .eq('id', profile.id);
  }

  Future<void> updateAvatarUrl(String userId, String url) async {
    await _client
        .from('profiles')
        .update({'avatar_url': url})
        .eq('id', userId);
  }

  ProfileEntity _modelToEntity(ProfileModel m) => ProfileEntity(
    id: m.id,
    username: m.username,
    avatarUrl: m.avatarUrl,
    aiApiKey: m.aiApiKey,
    aiProvider: m.aiProvider,
  );
}
