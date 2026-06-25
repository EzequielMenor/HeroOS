import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:heroos/data/repositories/auth_repository.dart';
import 'package:heroos/data/repositories/dev_repository.dart';
import 'package:heroos/domain/entities/note_entity.dart';
import 'package:heroos/presentation/viewmodels/notes_viewmodel.dart';

void main() {
  setUpAll(() {
    AuthRepository.devQuickAccess = true;
  });

  setUp(() {
    DevRepository().clearAll();
  });

  test('queueAutosave debounces and saves once after delay', () async {
    final vm = NotesViewModel();
    await vm.loadNotes();

    // Create a note and get the actual note with generated ID
    await vm.createNote(
      title: 'Test Note',
      content: 'Original content',
      tags: [],
    );

    final originalNote = vm.notes.first;
    final updatedNote = originalNote.copyWith(content: 'New content 2');
    vm.queueAutosave(updatedNote);

    // During debounce, isLoading should be false
    expect(vm.isLoading, false);

    // Wait for debounce + save
    await Future.delayed(const Duration(milliseconds: 1700));

    // Verify the note was saved with new content
    final savedNote = vm.notes.firstWhere((n) => n.id == originalNote.id);
    expect(savedNote.content, 'New content 2');
  });

  test('queueAutosave coalesces rapid updates into one save', () async {
    final vm = NotesViewModel();
    await vm.loadNotes();

    // Create a note
    await vm.createNote(title: 'Coalesce Test', content: 'Start');
    final originalNote = vm.notes.first;

    // Queue multiple rapid updates
    vm.queueAutosave(originalNote.copyWith(content: 'Update 1'));
    vm.queueAutosave(originalNote.copyWith(content: 'Update 2'));
    vm.queueAutosave(originalNote.copyWith(content: 'Update 3'));

    // Wait for debounce + save
    await Future.delayed(const Duration(milliseconds: 1700));

    // Should have saved only the last content
    final savedNote = vm.notes.firstWhere((n) => n.id == originalNote.id);
    expect(savedNote.content, 'Update 3');
  });

  test('flushAutosave followed by debounced autosave does not throw StateError', () async {
    final vm = NotesViewModel();
    await vm.loadNotes();

    await vm.createNote(title: 'Flush Test', content: 'Start');
    final originalNote = vm.notes.first;

    // Queue update and flush
    vm.queueAutosave(originalNote.copyWith(content: 'Flush Content'));
    final saved = await vm.flushAutosave();
    expect(saved, true);

    // Queue another update immediately and wait for debounce
    vm.queueAutosave(originalNote.copyWith(content: 'Debounced Content'));
    await Future.delayed(const Duration(milliseconds: 1700));

    final finalNote = vm.notes.firstWhere((n) => n.id == originalNote.id);
    expect(finalNote.content, 'Debounced Content');
  });

  test('flushAutosave called during an active save awaits the second save and finishes successfully', () async {
    final mockRepo = MockDelayedRepository();
    final note = NoteEntity(
      id: 'mock_id',
      userId: 'dev-user',
      title: 'Original Title',
      content: 'Original Content',
      date: DateTime.now(),
      tags: [],
    );
    mockRepo._notes.add(note);

    final vm = NotesViewModel(repository: mockRepo);
    await vm.loadNotes();

    // Start a delayed save
    mockRepo.saveCompleter = Completer<void>();
    vm.queueAutosave(note.copyWith(content: 'First Update'));
    
    // Trigger save execution
    await Future.delayed(const Duration(milliseconds: 1600));
    expect(vm.isSaving, true);

    // Queue a second update and immediately call flushAutosave
    vm.queueAutosave(note.copyWith(content: 'Second Update'));
    final flushFuture = vm.flushAutosave();

    // Complete the first save
    mockRepo.saveCompleter!.complete();

    // The flush future should complete successfully
    final flushResult = await flushFuture;
    expect(flushResult, true);
    
    // Verify the second update was saved
    expect(mockRepo._notes.first.content, 'Second Update');
  });
}

class MockDelayedRepository {
  final List<NoteEntity> _notes = [];
  Completer<void>? saveCompleter;

  Future<List<NoteEntity>> getNotes() async => _notes;

  Future<void> createNote(NoteEntity note) async {
    if (saveCompleter != null) {
      await saveCompleter!.future;
    }
    _notes.add(NoteEntity(
      id: 'mock_id',
      userId: note.userId,
      title: note.title,
      content: note.content,
      date: note.date,
      tags: note.tags,
    ));
  }

  Future<void> updateNote(NoteEntity note) async {
    if (saveCompleter != null) {
      await saveCompleter!.future;
    }
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      _notes[idx] = note;
    }
  }
}
