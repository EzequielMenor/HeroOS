import 'package:flutter/material.dart';
import '../widgets/zen_glass.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/note_entity.dart';
import '../viewmodels/auth_viewmodel.dart';
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
  bool _isPreviewMode = false; // Toggle between edit and preview mode

  OverlayEntry? _autocompleteOverlay;
  final FocusNode _editorFocusNode = FocusNode();
  final GlobalKey _editorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    context.read<NotesViewModel>().clearLastCreatedNote();
    _title = widget.note?.title ?? '';
    _createdNoteId = widget.note?.id.isNotEmpty == true
        ? widget.note!.id
        : null;
    _controller = ZenMarkdownController(text: widget.note?.content ?? '');
    _controller.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _removeAutocompleteOverlay();
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Offset _getCursorOffset() {
    final renderBox =
        _editorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    return renderBox.localToGlobal(Offset.zero);
  }

  void _onContentChanged() {
    final content = _controller.text;
    final lines = content.split('\n');
    final newTitle = lines.isNotEmpty
        ? lines[0].replaceFirst(RegExp(r'^#+\s*'), '')
        : '';

    if (newTitle != _title) {
      _title = newTitle;
    }

    final vm = context.read<NotesViewModel>();
    if (_createdNoteId == null && vm.lastCreatedNote != null) {
      _createdNoteId = vm.lastCreatedNote!.id;
    }

    // Si ya se creó la nota, usa su id; si no, empty id → ViewModel crea
    final noteId = _createdNoteId ?? '';
    final userId = context.read<AuthViewModel>().currentUserId ?? '';

    final noteToSave = NoteEntity(
      id: noteId,
      userId: userId,
      title: newTitle,
      content: content,
      date: DateTime.now(),
      tags: widget.note?.tags ?? [],
    );
    vm.queueAutosave(noteToSave);

    // Detect [[ trigger for autocomplete
    _checkAutocompleteTrigger();
  }

  void _checkAutocompleteTrigger() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      _removeAutocompleteOverlay();
      return;
    }

    final cursorPos = selection.baseOffset;
    if (cursorPos < 2 || cursorPos > text.length) {
      _removeAutocompleteOverlay();
      return;
    }

    // Look for [[ before cursor
    final beforeCursor = text.substring(0, cursorPos);
    final lastOpen = beforeCursor.lastIndexOf('[[');

    if (lastOpen == -1) {
      _removeAutocompleteOverlay();
      return;
    }

    // Check there's no ]] between [[ and cursor
    final between = beforeCursor.substring(lastOpen);
    if (between.contains(']]')) {
      _removeAutocompleteOverlay();
      return;
    }

    // Extract query after [[
    final query = beforeCursor.substring(lastOpen + 2);

    final vm = context.read<NotesViewModel>();
    final noteId = _createdNoteId ?? widget.note?.id;
    final suggestions = vm.getAutocompleteSuggestions(
      query,
      currentNoteId: noteId,
    );

    if (suggestions.isEmpty) {
      _removeAutocompleteOverlay();
      return;
    }

    _showAutocompleteOverlay(suggestions);
  }

  void _showAutocompleteOverlay(List<NoteEntity> suggestions) {
    _removeAutocompleteOverlay();

    final cursorOffset = _getCursorOffset();
    // Estimate cursor position: use text field position + line height * current line
    // A simpler approach: position just below the text field for now
    final overlayTop = cursorOffset.dy + 40; // approximate line height offset

    _autocompleteOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned(
            left: cursorOffset.dx,
            top: overlayTop,
            width: 240,
            child: Material(
              color: Colors.transparent,
              child: ZenGlass(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: suggestions.length,
                    itemBuilder: (context, i) {
                      final note = suggestions[i];
                      return InkWell(
                        onTap: () => _insertWikiLink(note),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            note.title.isNotEmpty ? note.title : '(sin título)',
                            style: const TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_autocompleteOverlay!);
  }

  void _removeAutocompleteOverlay() {
    _autocompleteOverlay?.remove();
    _autocompleteOverlay = null;
  }

  void _insertWikiLink(NoteEntity targetNote) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPos = selection.baseOffset;

    final beforeCursor = text.substring(0, cursorPos);
    final lastOpen = beforeCursor.lastIndexOf('[[');

    if (lastOpen == -1) return;

    // Replace [[query with [[title]]
    final newText =
        '${text.substring(0, lastOpen)}[[${targetNote.title}]]${text.substring(cursorPos)}';

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: lastOpen + targetNote.title.length + 4,
      ),
    );

    _removeAutocompleteOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _removeAutocompleteOverlay();
          context.read<NotesViewModel>().flushAutosave();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        body: SafeArea(
          child: Column(
            children: [
              // Custom header — full control over sizing
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: back
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Right: share, more, save
                    Row(
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.ios_share, size: 20),
                          onPressed: () {
                            // TODO: share note
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          iconSize: 36,
                          icon: Icon(
                            _isPreviewMode
                                ? Icons.edit_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPreviewMode = !_isPreviewMode;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.more_horiz, size: 20),
                          onPressed: () {
                            // TODO: more options
                          },
                        ),
                        const SizedBox(width: 8),
                        if (MediaQuery.of(context).viewInsets.bottom > 0 &&
                            !_isPreviewMode)
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.check,
                                color: Color(0xFF1C1C1E),
                                size: 20,
                              ),
                              onPressed: () {
                                if (_title.trim().isEmpty &&
                                    _controller.text.trim().isEmpty) {
                                  return;
                                }
                                FocusScope.of(context).unfocus();
                                context.read<NotesViewModel>().flushAutosave();
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Editor
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ZenGlass(
                    padding: const EdgeInsets.all(20),
                    child: _isPreviewMode
                        ? _buildPreviewContent()
                        : _buildEditorContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _isPreviewMode ? null : _buildFormatToolbar(),
      ),
    );
  }

  Widget _buildPreviewContent() {
    final content = _controller.text;
    if (content.trim().isEmpty) {
      return const Center(
        child: Text(
          'Sin contenido',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Markdown(
      data: content,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.6,
        ),
        h1: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        h2: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        h3: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h4: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        h5: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        h6: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        code: TextStyle(
          color: AppColors.textPrimary,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          fontSize: 14,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        a: const TextStyle(color: AppColors.accent),
      ),
      selectable: true,
    );
  }

  Widget _buildEditorContent() {
    return TextField(
      key: _editorKey,
      controller: _controller,
      focusNode: _editorFocusNode,
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
        contentPadding: EdgeInsets.only(top: 12, bottom: 12),
      ),
    );
  }

  Widget _buildFormatToolbar() {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(
        left: 40,
        right: 40,
        bottom: viewInsets.bottom > 0
            ? viewInsets.bottom + 12
            : MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Container(
        child: ZenGlass(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FormatButton(
                icon: Icons.format_bold,
                tooltip: 'Negrita',
                onPressed: () => _wrapSelection('**', '**'),
              ),
              const SizedBox(width: 4),
              _FormatButton(
                icon: Icons.title,
                tooltip: 'Título',
                onPressed: () => _insertAtLineStart('## '),
              ),
              const SizedBox(width: 4),
              _FormatButton(
                icon: Icons.link,
                tooltip: 'Enlace',
                onPressed: _insertWikiLinkSyntax,
              ),
              const SizedBox(width: 4),
              _FormatButton(
                icon: Icons.format_italic,
                tooltip: 'Itálica',
                onPressed: () => _wrapSelection('_', '_'),
              ),
              const SizedBox(width: 4),
              _FormatButton(
                icon: Icons.format_list_bulleted,
                tooltip: 'Lista',
                onPressed: () => _insertAtLineStart('- '),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = _controller.text;
    final selection = _controller.selection;

    // Guard against invalid selection bounds
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);

    if (start == end) {
      // No selection - insert prefix+suffix at cursor, cursor between them
      final insertPos = start.clamp(0, text.length);
      final newText =
          '${text.substring(0, insertPos)}$prefix$suffix${text.substring(insertPos)}';
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: insertPos + prefix.length),
      );
    } else {
      // Wrap selection
      final safeStart = start.clamp(0, text.length);
      final safeEnd = end.clamp(safeStart, text.length);
      final selectedText = text.substring(safeStart, safeEnd);
      final newText =
          '${text.substring(0, safeStart)}$prefix$selectedText$suffix${text.substring(safeEnd)}';
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: safeEnd + prefix.length + suffix.length,
        ),
      );
    }
  }

  void _insertAtLineStart(String prefix) {
    final text = _controller.text;
    final selection = _controller.selection;

    // Clamp selection start to valid range (fixes RangeError when selection.start = -1)
    final cursorPos = selection.start.clamp(0, text.length);

    // Find start of current line
    int lineStart = cursorPos;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    // Clamp lineStart for substring operation
    final safeLineStart = lineStart.clamp(0, text.length);

    final newText =
        '${text.substring(0, safeLineStart)}$prefix${text.substring(safeLineStart)}';
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPos + prefix.length),
    );
  }

  void _insertWikiLinkSyntax() {
    final text = _controller.text;
    final selection = _controller.selection;

    final newText =
        '${text.substring(0, selection.start)}[[${text.substring(selection.start)}';
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + 2),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _FormatButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
