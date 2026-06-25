import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/note_entity.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../widgets/zen_markdown_controller.dart';

/// Fullscreen distraction-free note editor (ZenCanvas).
/// Background: #1C1C1E, no AppBar, minimal header.
class ZenCanvasScreen extends StatefulWidget {
  final NoteEntity? note;

  const ZenCanvasScreen({super.key, this.note});

  @override
  State<ZenCanvasScreen> createState() => _ZenCanvasScreenState();
}

class _ZenCanvasScreenState extends State<ZenCanvasScreen> {
  late final ZenMarkdownController _controller;
  late String _title;
  String? _createdNoteId; // Tracks the note id after first create

  @override
  void initState() {
    super.initState();
    _title = widget.note?.title ?? '';
    _createdNoteId = widget.note?.id.isNotEmpty == true ? widget.note!.id : null;
    _controller = ZenMarkdownController(text: widget.note?.content ?? '');
    _controller.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final content = _controller.text;
    final lines = content.split('\n');
    final newTitle = lines.isNotEmpty ? lines[0].replaceFirst(RegExp(r'^#+\s*'), '') : '';

    if (newTitle != _title) {
      _title = newTitle;
    }

    final vm = context.read<NotesViewModel>();

    // Si ya se creó la nota, usa su id; si no, empty id → ViewModel crea
    final noteId = _createdNoteId ?? '';
    final userId = AuthRepository.devQuickAccess
        ? 'dev-user'
        : Supabase.instance.client.auth.currentUser?.id ?? '';

    final noteToSave = NoteEntity(
      id: noteId,
      userId: userId,
      title: newTitle,
      content: content,
      date: DateTime.now(),
      tags: widget.note?.tags ?? [],
    );
    vm.queueAutosave(noteToSave);

    // After first create, update _createdNoteId so subsequent saves use update
    if (_createdNoteId == null && vm.lastCreatedNote != null) {
      _createdNoteId = vm.lastCreatedNote!.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<NotesViewModel>().flushAutosave();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Minimal header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 20),
                      onPressed: () {
                        context.read<NotesViewModel>().flushAutosave();
                        Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'LIENZO ZEN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.accent, size: 20),
                      onPressed: () async {
                        final vm = context.read<NotesViewModel>();
                        final saved = await vm.flushAutosave();
                        if (context.mounted) {
                          if (saved == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nota guardada'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          } else if (saved == false) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(vm.error ?? 'Error al guardar la nota'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Editor
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      height: 1.6,
                    ),
                    cursorColor: AppColors.accent,
                    decoration: const InputDecoration(
                      hintText: 'Escribe sin distracciones…',
                      hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
