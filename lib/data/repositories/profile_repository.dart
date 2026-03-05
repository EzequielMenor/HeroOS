import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../models/profile_model.dart';
import '../services/supabase_service.dart';

/// Implementación concreta de [IProfileRepository] con Supabase.
class ProfileRepository implements IProfileRepository {
  final SupabaseClient _client = SupabaseService.client;

  @override
  Future<ProfileEntity?> getProfile() async {
    final userId = SupabaseService.currentUser?.id;
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

  @override
  Future<void> updateProfile(ProfileEntity profile) async {
    await _client
        .from('profiles')
        .update({
          'username': profile.username,
          'level': profile.level,
          'current_xp': profile.currentXp,
          'xp_next_level': profile.xpNextLevel,
          'current_hp': profile.currentHp,
          'max_hp': profile.maxHp,
          'current_gold': profile.currentGold,
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
    level: m.level,
    currentXp: m.currentXp,
    xpNextLevel: m.xpNextLevel,
    currentHp: m.currentHp,
    maxHp: m.maxHp,
    currentGold: m.currentGold,
    avatarUrl: m.avatarUrl,
  );
}
