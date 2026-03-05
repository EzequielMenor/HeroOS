import 'package:flutter/material.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/rpg_events_repository.dart';
import '../../data/services/storage_service.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/rpg_event_entity.dart';

/// ViewModel de Stats RPG.
/// Gestiona carga/persistencia del perfil y expone eventos de Level Up / Game Over.
class StatsViewModel extends ChangeNotifier {
  final ProfileRepository _repo = ProfileRepository();
  final RpgEventsRepository _eventsRepo = RpgEventsRepository();
  final StorageService _storage = StorageService();

  ProfileEntity? _profile;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _didLevelUp = false;
  bool _isGameOver = false;
  List<RpgEventEntity> _recentEvents = [];
  int? _lastXpGain;
  int? _lastHpLoss;

  ProfileEntity? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  bool get didLevelUp => _didLevelUp;
  bool get isGameOver => _isGameOver;
  List<RpgEventEntity> get recentEvents => _recentEvents;
  int? get lastXpGain => _lastXpGain;
  int? get lastHpLoss => _lastHpLoss;

  /// Carga el perfil del usuario autenticado.
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

  /// Carga los últimos 20 eventos RPG del usuario.
  Future<void> loadRecentEvents() async {
    try {
      _recentEvents = await _eventsRepo.getRecentEvents();
      notifyListeners();
    } catch (_) {}
  }

  /// Aplica ganancia de XP y persiste. Activa Level Up si corresponde.
  Future<void> applyXpGain(int xp, {String description = ''}) async {
    if (_profile == null) return;
    final result = _profile!.gainXp(xp);
    _profile = result.profile;
    _didLevelUp = result.didLevelUp;
    _lastXpGain = xp;
    notifyListeners();
    await _repo.updateProfile(_profile!);
    await _eventsRepo.log(RpgEventType.xpGain, xp, description);
    if (result.didLevelUp) {
      await _eventsRepo.log(
        RpgEventType.levelUp,
        _profile!.level,
        '¡Subiste al nivel ${_profile!.level}!',
      );
    }
  }

  /// Aplica daño al HP y persiste. Activa Game Over si HP <= 0.
  Future<void> applyDamage(int dmg, {String description = ''}) async {
    if (_profile == null) return;
    final result = _profile!.takeDamage(dmg);
    _profile = result.profile;
    _isGameOver = result.isGameOver;
    _lastHpLoss = dmg;
    notifyListeners();
    await _repo.updateProfile(_profile!);
    await _eventsRepo.log(RpgEventType.hpLoss, dmg, description);
    if (result.isGameOver) {
      await _eventsRepo.log(RpgEventType.gameOver, 0, 'Game Over — HP a 0');
    }
  }

  /// Resta XP sin tocar HP (para desmarcar tareas/hábitos).
  Future<void> applyXpLoss(int xp, {String description = ''}) async {
    if (_profile == null) return;
    _profile = _profile!.loseXp(xp);
    notifyListeners();
    await _repo.updateProfile(_profile!);
    await _eventsRepo.log(RpgEventType.xpLoss, xp, description);
  }

  /// Actualiza el nombre del héroe y persiste.
  Future<void> updateUsername(String newName) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(username: newName);
    notifyListeners();
    await _repo.updateProfile(_profile!);
  }

  /// Abre la galería, sube la imagen a Supabase Storage y actualiza avatar_url en BD.
  /// Devuelve false si el usuario cancela el picker.
  Future<bool> uploadAvatar() async {
    if (_profile == null) return false;
    final file = await _storage.pickImage();
    if (file == null) return false;

    _isUploading = true;
    notifyListeners();
    try {
      final url = await _storage.uploadAvatar(file);
      await _repo.updateAvatarUrl(_profile!.id, url);
      _profile = _profile!.copyWith(avatarUrl: url);
      return true;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Resetea los flags de eventos después de que la UI los muestre.
  void clearEvents() {
    _didLevelUp = false;
    _isGameOver = false;
    notifyListeners();
  }

  /// Resetea los datos de toast sin provocar rebuild.
  void clearToast() {
    _lastXpGain = null;
    _lastHpLoss = null;
  }
}
