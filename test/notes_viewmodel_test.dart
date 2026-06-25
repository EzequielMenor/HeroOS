import 'package:flutter_test/flutter_test.dart';
import 'package:heroos/data/repositories/auth_repository.dart';
import 'package:heroos/data/repositories/dev_repository.dart';
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
}
