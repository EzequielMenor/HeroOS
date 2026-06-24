import '../../domain/entities/note_entity.dart';

/// Data model for Note — Supabase JSON mapping.
class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime date;
  final List<String> tags;

  NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.date,
    this.tags = const [],
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      date: DateTime.parse(json['date'] as String),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'tags': tags,
    };
  }

  factory NoteModel.fromEntity(NoteEntity entity) {
    return NoteModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      content: entity.content,
      date: entity.date,
      tags: entity.tags,
    );
  }

  NoteEntity toEntity() {
    return NoteEntity(
      id: id,
      userId: userId,
      title: title,
      content: content,
      date: date,
      tags: tags,
    );
  }
}
