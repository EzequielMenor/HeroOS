import 'dart:async';
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

  // Debounced autosave state
  Timer? _debounceTimer;
  bool _isSaving = false;
  NoteEntity? _pendingNoteState;
  NoteEntity? _lastCreatedNote; // Track created notes to avoid duplicate creates
  Future<void>? _activeSaveFuture;

  NotesViewModel({dynamic repository}) : _repo = repository ?? (AuthRepository.devQuickAccess ? DevRepository() : NoteRepository());

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
  bool get isSaving => _isSaving;
  String? get error => _error;
  NoteEntity? get lastCreatedNote => _lastCreatedNote;

  /// Cancels pending debounce and immediately saves any pending note.
  /// Returns true if saved, false if failed, null if nothing to save.
  Future<bool?> flushAutosave() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    if (_pendingNoteState == null && !_isSaving) return null;

    bool hadError = false;
    while (_pendingNoteState != null || _isSaving) {
      if (_isSaving) {
        await _activeSaveFuture;
      } else {
        await _executeSave();
        if (_error != null) {
          hadError = true;
          break;
        }
      }
    }
    return !hadError;
  }

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

  /// Queues an autosave with 1.5s debounce.
  /// Handles create (id empty) vs update (id present) automatically.
  void queueAutosave(NoteEntity updatedNote) {
    _pendingNoteState = updatedNote;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _executeSave();
    });
  }

  Future<void> _executeSave() async {
    if (_isSaving) return;
    _isSaving = true;
    
    final completer = Completer<void>();
    _activeSaveFuture = completer.future;

    try {
      final noteToSave = _pendingNoteState;
      if (noteToSave != null) {
        _error = null;
        if (noteToSave.userId == 'dev-user' && !AuthRepository.devQuickAccess) {
          _error = 'userId inválido: dev-user (necesitas login o devQuickAccess)';
          notifyListeners();
          return;
        }

        if (noteToSave.id.isEmpty) {
          // Nueva nota: crear solo si es contenido nuevo (no duplicar)
          final isDuplicate = _lastCreatedNote != null &&
              _lastCreatedNote!.content == noteToSave.content;
          if (!isDuplicate) {
            await _repo.createNote(noteToSave);
            await loadNotes();
            final created = _notes
                .where((n) => n.content == noteToSave.content && n.title == noteToSave.title)
                .firstOrNull;
            if (created != null) {
              _lastCreatedNote = created;
              // Actualizar el ID en _pendingNoteState para evitar duplicaciones si el usuario sigue editando la misma nota
              if (_pendingNoteState != null && _pendingNoteState!.id.isEmpty) {
                _pendingNoteState = NoteEntity(
                  id: created.id,
                  userId: _pendingNoteState!.userId,
                  title: _pendingNoteState!.title,
                  content: _pendingNoteState!.content,
                  date: _pendingNoteState!.date,
                  tags: _pendingNoteState!.tags,
                );
              }
            }
          }
        } else {
          await _repo.updateNote(noteToSave);
          final idx = _notes.indexWhere((n) => n.id == noteToSave.id);
          if (idx != -1) {
            final updatedNotes = List<NoteEntity>.from(_notes);
            updatedNotes[idx] = noteToSave;
            _notes = updatedNotes;
            notifyListeners();
          }
        }

        if (_pendingNoteState?.content == noteToSave.content && _pendingNoteState?.title == noteToSave.title) {
          _pendingNoteState = null;
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isSaving = false;
      _activeSaveFuture = null;
      completer.complete();
    }
  }
}
