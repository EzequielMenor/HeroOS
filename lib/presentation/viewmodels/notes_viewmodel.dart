import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/dev_repository.dart';
import '../../domain/entities/note_entity.dart';

/// ViewModel de Notas.
/// CRUD + búsqueda + filtro por tags.
class NotesViewModel extends ChangeNotifier {
  final dynamic _repo;

  List<NoteEntity> _notes = const [];
  Set<String> _allTags = {};
  String _searchQuery = '';
  String? _selectedTag;
  bool _isLoading = false;
  String? _error;

  NotesViewModel() : _repo = AuthRepository.devQuickAccess ? DevRepository() : NoteRepository();

  List<NoteEntity> get notes {
    var result = _notes;
    if (_searchQuery.isNotEmpty) {
      result = result.where((n) =>
          n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_selectedTag != null) {
      result = result.where((n) => n.tags.contains(_selectedTag)).toList();
    }
    return result;
  }

  Set<String> get allTags => _allTags;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carga todas las notas del usuario.
  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notes = await _repo.getNotes();
      _allTags = _notes.expand((n) => n.tags).toSet();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea una nueva nota.
  Future<void> createNote({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final userId = AuthRepository.devQuickAccess ? 'dev-user' : Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final note = NoteEntity(
      id: '',
      userId: userId,
      title: title,
      content: content,
      date: DateTime.now(),
      tags: tags,
    );
    try {
      await _repo.createNote(note);
      await loadNotes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Actualiza una nota existente.
  Future<void> updateNote(NoteEntity note) async {
    try {
      await _repo.updateNote(note);
      await loadNotes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Elimina una nota.
  Future<void> deleteNote(String noteId) async {
    try {
      await _repo.deleteNote(noteId);
      _notes.removeWhere((n) => n.id == noteId);
      _allTags = _notes.expand((n) => n.tags).toSet();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Busca notas por título.
  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Filtra notas por tag.
  void filterByTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }
}
