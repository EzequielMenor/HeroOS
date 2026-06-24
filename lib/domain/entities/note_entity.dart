/// Domain entity for notes.
/// Zen OS pivot: lightweight note-taking with tags.
class NoteEntity {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime date;
  final List<String> tags;

  const NoteEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.date,
    this.tags = const [],
  });

  NoteEntity copyWith({
    String? title,
    String? content,
    DateTime? date,
    List<String>? tags,
  }) {
    return NoteEntity(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      tags: tags ?? this.tags,
    );
  }
}
