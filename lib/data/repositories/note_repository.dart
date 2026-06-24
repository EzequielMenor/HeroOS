import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/note_entity.dart';
import '../models/note_model.dart';

/// Supabase repository for notes CRUD.
class NoteRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<NoteEntity>> getNotes({String? query, String? tag}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    var q = _client.from('notes').select().eq('user_id', userId);

    if (query != null && query.isNotEmpty) {
      q = q.ilike('title', '%$query%');
    }
    if (tag != null && tag.isNotEmpty) {
      q = q.contains('tags', [tag]);
    }

    final data = await q.order('date', ascending: false);
    return data.map((json) => NoteModel.fromJson(json).toEntity()).toList();
  }

  Future<void> createNote(NoteEntity note) async {
    final model = NoteModel.fromEntity(note);
    await _client.from('notes').insert(model.toJson());
  }

  Future<void> updateNote(NoteEntity note) async {
    final model = NoteModel.fromEntity(note);
    await _client.from('notes').update(model.toJson()).eq('id', note.id);
  }

  Future<void> deleteNote(String noteId) async {
    await _client.from('notes').delete().eq('id', noteId);
  }
}
