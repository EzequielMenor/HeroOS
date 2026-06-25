import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _title = widget.note?.title ?? '';
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
    final newTitle = lines.isNotEmpty ? lines[0] : '';

    if (newTitle != _title) {
      _title = newTitle;
    }

    if (widget.note != null) {
      // Queue autosave on content change
      final updatedNote = widget.note!.copyWith(
        title: _title,
        content: content,
        date: DateTime.now(),
      );
      context.read<NotesViewModel>().queueAutosave(updatedNote);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onPressed: () => Navigator.pop(context),
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
                  const SizedBox(width: 48), // Balance the back button
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
    );
  }
}
