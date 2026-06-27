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

  group('NotesViewModel getAutocompleteSuggestions', () {
    test('returns all notes when query is empty', () async {
      final vm = NotesViewModel();
      await vm.loadNotes();

      await vm.createNote(title: 'Alpha', content: 'Content A', tags: []);
      await vm.createNote(title: 'Beta', content: 'Content B', tags: []);
      await vm.createNote(title: 'Gamma', content: 'Content C', tags: []);

      final suggestions = vm.getAutocompleteSuggestions('');
      expect(suggestions.length, 3);
    });

    test('filters notes by title match (case-insensitive)', () async {
      final vm = NotesViewModel();
      await vm.loadNotes();

      await vm.createNote(title: 'Flutter Guide', content: 'Content', tags: []);
      await vm.createNote(title: 'Dart Tips', content: 'Content', tags: []);
      await vm.createNote(title: 'Flutter Advanced', content: 'Content', tags: []);

      final suggestions = vm.getAutocompleteSuggestions('flutter');
      expect(suggestions.length, 2);
      expect(suggestions.map((n) => n.title), containsAll(['Flutter Guide', 'Flutter Advanced']));
    });

    test('returns empty list when no match', () async {
      final vm = NotesViewModel();
      await vm.loadNotes();

      await vm.createNote(title: 'Alpha', content: 'Content', tags: []);

      final suggestions = vm.getAutocompleteSuggestions('xyz');
      expect(suggestions, isEmpty);
    });
  });

  group('NotesViewModel getBacklinksFor', () {
    test('returns empty list when no notes link to target', () async {
      final vm = NotesViewModel();
      await vm.loadNotes();

      await vm.createNote(title: 'Note A', content: 'Plain content', tags: []);
      await vm.createNote(title: 'Note B', content: 'More plain content', tags: []);

      final target = vm.notes.first;
      final backlinks = vm.getBacklinksFor(target);
      expect(backlinks, isEmpty);
    });

    test('finds backlinks by title match', () async {
      final vm = NotesViewModel();
      await vm.loadNotes();

      await vm.createNote(title: 'Main Note', content: 'This is the main topic', tags: []);
      await vm.createNote(title: 'Secondary', content: 'See [[Main Note]] for details', tags: []);

      final target = vm.notes.firstWhere((n) => n.title == 'Main Note');
      final backlinks = vm.getBacklinksFor(target);

      expect(backlinks.length, 1);
      expect(backlinks.first.title, 'Secondary');
    });

    test('finds backlinks by ID match', () async {
      final vm = NotesViewModel();
      await vm.loadNotes();

      await vm.createNote(title: 'My Note', content: 'Content', tags: []);
      final target = vm.notes.firstWhere((n) => n.title == 'My Note');

      await vm.createNote(
        title: 'Referencing Note',
        content: 'Link to [[${target.id}]] using ID',
        tags: [],
      );

      final backlinks = vm.getBacklinksFor(target);
      expect(backlinks.length, 1);
      expect(backlinks.first.title, 'Referencing Note');
    });

    test('does not include target note itself as backlink', () async {
      final vm = NotesViewModel();
      await vm.loadNotes();

      await vm.createNote(
        title: 'Self Reference',
        content: 'See [[Self Reference]] inside itself',
        tags: [],
      );

      final target = vm.notes.first;
      final backlinks = vm.getBacklinksFor(target);
      expect(backlinks, isEmpty);
    });

    test('handles [[Target|Label]] syntax for backlink detection', () async {
      final vm = NotesViewModel();
      await vm.loadNotes();

      await vm.createNote(title: 'Detailed Topic', content: 'Detailed content', tags: []);
      await vm.createNote(
        title: 'Linking Note',
        content: 'Check [[Detailed Topic|Custom Label]]',
        tags: [],
      );

      final target = vm.notes.firstWhere((n) => n.title == 'Detailed Topic');
      final backlinks = vm.getBacklinksFor(target);

      expect(backlinks.length, 1);
      expect(backlinks.first.title, 'Linking Note');
    });
  });
}
