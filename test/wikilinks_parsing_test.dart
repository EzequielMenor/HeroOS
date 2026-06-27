import 'package:flutter_test/flutter_test.dart';
import 'package:heroos/domain/entities/note_entity.dart';

void main() {
  group('WikiLinks regex', () {
    test('extracts simple [[Target]] link', () {
      final note = NoteEntity(
        id: '1',
        userId: 'user',
        title: 'Test',
        content: 'See [[Note One]] for details.',
        date: DateTime.now(),
        tags: [],
      );
      expect(note.getLinkedTargets(), ['Note One']);
    });

    test('extracts [[Target|Label]] link with custom label', () {
      final note = NoteEntity(
        id: '2',
        userId: 'user',
        title: 'Test',
        content: 'See [[actual-note|Display Text]] here.',
        date: DateTime.now(),
        tags: [],
      );
      expect(note.getLinkedTargets(), ['actual-note']);
    });

    test('extracts multiple WikiLinks', () {
      final note = NoteEntity(
        id: '3',
        userId: 'user',
        title: 'Test',
        content: '[[First]] and [[Second]] and [[Third|Label]]',
        date: DateTime.now(),
        tags: [],
      );
      expect(note.getLinkedTargets(), ['First', 'Second', 'Third']);
    });

    test('returns empty list when no WikiLinks', () {
      final note = NoteEntity(
        id: '4',
        userId: 'user',
        title: 'Test',
        content: 'Just plain text without any links.',
        date: DateTime.now(),
        tags: [],
      );
      expect(note.getLinkedTargets(), isEmpty);
    });

    test('handles empty content', () {
      final note = NoteEntity(
        id: '5',
        userId: 'user',
        title: 'Test',
        content: '',
        date: DateTime.now(),
        tags: [],
      );
      expect(note.getLinkedTargets(), isEmpty);
    });

    test('strips whitespace around target', () {
      final note = NoteEntity(
        id: '6',
        userId: 'user',
        title: 'Test',
        content: '[[  Spaced Title  ]]',
        date: DateTime.now(),
        tags: [],
      );
      expect(note.getLinkedTargets(), ['Spaced Title']);
    });

    test('ignores ]] inside brackets', () {
      final note = NoteEntity(
        id: '7',
        userId: 'user',
        title: 'Test',
        content: '[[Target]] and more [[Another|With Label]] text',
        date: DateTime.now(),
        tags: [],
      );
      expect(note.getLinkedTargets(), ['Target', 'Another']);
    });
  });
}
