import 'package:flutter/material.dart';
import '../../core/utils/auth_error_mapper.dart';
import '../../data/repositories/auth_repository.dart';

/// ViewModel de autenticación. Gestiona estado de login/register.
/// La UI solo lee propiedades y llama métodos — nunca toca Supabase.
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _repo.isAuthenticated;

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _repo.signIn(email: email, password: password);
      _errorMessage = null;
      return true;
    } on Exception catch (e) {
      _errorMessage = mapAuthError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _repo.signUp(email: email, password: password);
      _errorMessage = null;
      return true;
    } on Exception catch (e) {
      _errorMessage = mapAuthError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _repo.resetPassword(email);
      _errorMessage = null;
      return true;
    } on Exception catch (e) {
      _errorMessage = mapAuthError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _repo.signOut();
      _errorMessage = null;
    } on Exception catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
