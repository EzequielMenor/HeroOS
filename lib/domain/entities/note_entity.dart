/// WikiLink regex: [[Target]] or [[Target|Label]]
final wikiLinkRegex = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');

/// Domain entity for notes.
/// Zen OS pivot: lightweight note-taking with tags.
class NoteEntity {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime date;
  final List<String> tags;

  NoteEntity({
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

  /// Extracts all WikiLink targets from note content.
  /// Matches [[Target]] and [[Target|Label]] patterns.
  List<String> getLinkedTargets() {
    return wikiLinkRegex
        .allMatches(content)
        .map((m) => m.group(1)!.trim())
        .toList();
  }
}
