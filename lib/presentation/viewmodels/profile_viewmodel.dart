import 'package:flutter/material.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/entities/profile_entity.dart';

/// ViewModel for profile management.
class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repo = ProfileRepository();

  ProfileEntity? _profile;
  bool _isLoading = false;

  ProfileEntity? get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await _repo.getProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(ProfileEntity profile) async {
    await _repo.updateProfile(profile);
    _profile = profile;
    notifyListeners();
  }
}
