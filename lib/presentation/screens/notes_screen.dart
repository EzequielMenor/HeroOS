import 'package:flutter/material.dart';
import '../widgets/zen_glass.dart';
import '../widgets/zen_card.dart';
import '../widgets/glass_input.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/adaptive_modal.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/note_entity.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../viewmodels/shell_controller.dart';
import 'zen_canvas_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
Color get _kBg => AppColors.scaffold;
Color get _kSurface => AppColors.surface;
Color get _kTextPrimary => AppColors.textPrimary;
Color get _kTextSecondary => AppColors.textSecondary;
Color get _kDivider => AppColors.divider;
Color get _kAccent => AppColors.accent;

/// Pantalla de Notas — lista + editor + filtro por tags.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesViewModel>().loadNotes();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotesViewModel>();

    if (vm.isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: _kAccent, strokeWidth: 1.5),
        ),
      );
    }

    if (context.isWeb) {
      return _buildWebLayout(vm);
    }
    return _buildMobileLayout(vm);
  }

  // ── Web ───────────────────────────────────────────────────────────────────

  Widget _buildWebLayout(NotesViewModel vm) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(width: 300, child: _buildSidebar(vm)),
            VerticalDivider(width: 1, thickness: 1, color: _kDivider),
            Expanded(child: _buildNoteListArea(vm)),
          ],
        ),
      ),
    );
  }

  // ── Mobile ────────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(NotesViewModel vm) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTAS',
                    style: TextStyle(
                      color: _kTextSecondary,
                      fontSize: 9,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Notas',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          color: _kTextPrimary,
                          height: 1.1,
                        ),
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ZenCanvasScreen(),
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: _kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // ── Search ──
            _buildSearchBar(vm),
            if (vm.allTags.isNotEmpty) ...[
              SizedBox(height: 8),
              _buildTagFilter(vm),
            ],
            SizedBox(height: 8),
            Divider(height: 1, thickness: 1, color: _kDivider),
            Expanded(child: _buildNoteList(vm)),
          ],
        ),
      ),
    );
  }

  // ── Sidebar (web) ─────────────────────────────────────────────────────────

  Widget _buildSidebar(NotesViewModel vm) {
    return Container(
      color: _kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOTAS',
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 9,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Notas',
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: _kTextPrimary,
                        height: 1.1,
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ZenCanvasScreen(),
                        ),
                      ),
                      child: Icon(Icons.add, size: 18, color: _kTextSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          _buildSearchBar(vm),
          if (vm.allTags.isNotEmpty) ...[
            SizedBox(height: 8),
            _buildTagFilter(vm),
          ],
          SizedBox(height: 8),
          Divider(height: 1, thickness: 1, color: _kDivider),
          Expanded(child: _buildNoteList(vm)),
        ],
      ),
    );
  }

  Widget _buildNoteListArea(NotesViewModel vm) {
    return _buildNoteList(vm);
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(NotesViewModel vm) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: GlassInput(
        controller: _searchCtrl,
        hint: 'Buscar notas…',
        onChanged: vm.search,
        prefixIcon: Icon(Icons.search, color: _kTextSecondary, size: 18),
      ),
    );
  }

  // ── Tag filter ────────────────────────────────────────────────────────────

  Widget _buildTagFilter(NotesViewModel vm) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        children: [
          _ZenTagChip(
            label: 'Todas',
            isActive: vm.selectedTag == null,
            onTap: () => vm.filterByTag(null),
          ),
          ...vm.allTags.map(
            (tag) => _ZenTagChip(
              label: tag,
              isActive: vm.selectedTag == tag,
              onTap: () => vm.filterByTag(tag),
            ),
          ),
        ],
      ),
    );
  }

  // ── Note list ─────────────────────────────────────────────────────────────

  Widget _buildNoteList(NotesViewModel vm) {
    if (vm.notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 36, color: _kTextSecondary),
            SizedBox(height: 12),
            Text(
              vm.searchQuery.isNotEmpty || vm.selectedTag != null
                  ? 'Sin notas que coincidan'
                  : 'Crea tu primera nota',
              style: TextStyle(color: _kTextSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final elements = _buildTimelineElements(vm.notes);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: elements.length,
      itemBuilder: (ctx, i) {
        final element = elements[i];
        final isFirst = i == 0;
        final isLast = i == elements.length - 1;

        if (element.headerTitle != null) {
          return _buildDayHeader(element.headerTitle!, isFirst, isLast);
        }

        // It is a note
        return _buildNoteTileElement(element.note!, vm, isFirst, isLast);
      },
    );
  }

  List<TimelineElement> _buildTimelineElements(List<NoteEntity> notes) {
    final List<TimelineElement> elements = [];
    final Map<String, List<NoteEntity>> grouped = {};

    for (final note in notes) {
      final dayStr = _formatGroupDate(note.date);
      grouped.putIfAbsent(dayStr, () => []).add(note);
    }

    final Set<String> processedGroups = {};
    for (final note in notes) {
      final dayStr = _formatGroupDate(note.date);
      if (!processedGroups.contains(dayStr)) {
        processedGroups.add(dayStr);
        elements.add(TimelineElement(headerTitle: dayStr));
        for (final n in grouped[dayStr]!) {
          elements.add(TimelineElement(note: n));
        }
      }
    }

    return elements;
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return 'HOY';
    } else if (noteDate == yesterday) {
      return 'AYER';
    } else {
      return DateFormat('d MMMM yyyy', 'es').format(date).toUpperCase();
    }
  }

  Widget _buildDayHeader(String title, bool isFirst, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TimelineLine(
            isFirst: isFirst,
            isLast: isLast,
            indicatorTop: 18,
            indicator: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _kBg,
                shape: BoxShape.circle,
                border: Border.all(color: _kAccent.withOpacity(0.5), width: 2),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Text(
                title,
                style: TextStyle(
                  color: _kAccent,
                  fontSize: 10,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteTileElement(
    NoteEntity note,
    NotesViewModel vm,
    bool isFirst,
    bool isLast,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TimelineLine(
            isFirst: isFirst,
            isLast: isLast,
            indicatorTop: 24,
            indicator: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _kBg,
                shape: BoxShape.circle,
                border: Border.all(color: _kAccent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 16),
              child: _ZenNoteTile(note: note, vm: vm),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline elements helper model ──────────────────────────────────────────

class TimelineElement {
  final String? headerTitle;
  final NoteEntity? note;

  TimelineElement({this.headerTitle, this.note});
}

// ─── Timeline connecting line widget ──────────────────────────────────────────

class _TimelineLine extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final Widget? indicator;
  final double indicatorTop;

  const _TimelineLine({
    required this.isFirst,
    required this.isLast,
    this.indicator,
    this.indicatorTop = 24,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: isFirst ? indicatorTop : 0,
            bottom: isLast ? indicatorTop : 0,
            child: Container(width: 1, color: _kDivider),
          ),
          if (indicator != null)
            Positioned(top: indicatorTop, child: indicator!),
        ],
      ),
    );
  }
}

// ─── Note editor/viewer sheet ──────────────────────────────────────────────────

class NoteEditorSheet extends StatefulWidget {
  final NoteEntity? note;
  final void Function(String title, String content, List<String> tags) onSave;
  final VoidCallback? onDelete;

  const NoteEditorSheet({
    super.key,
    required this.note,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late ShellController _shellController;
  late bool _isEditing;
  late TextEditingController _contentCtrl;
  final FocusNode _editorFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note == null;

    // Backwards compatibility migration for note details
    String initialText = '';
    if (widget.note != null) {
      final title = widget.note!.title;
      final content = widget.note!.content;
      if (title.isNotEmpty && !content.startsWith(title)) {
        initialText = '$title\n$content';
      } else {
        initialText = content;
      }
    }
    _contentCtrl = TextEditingController(text: initialText);
    _editorFocusNode.addListener(_onFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shellController = Provider.of<ShellController>(context, listen: false);
  }

  void _onFocusChange() {
    if (!mounted) return;
    context.read<ShellController>().setWriting(_editorFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _shellController.setWriting(false);
    _editorFocusNode.removeListener(_onFocusChange);
    _editorFocusNode.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  List<String> _extractTags(String text) {
    final tagRegex = RegExp(r'#([a-zA-Z0-9_áéíóúÁÉÍÓÚñÑ]+)');
    final matches = tagRegex.allMatches(text);
    return matches.map((m) => m.group(1)!.toLowerCase()).toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.note == null;

    return ZenGlass(
      padding: EdgeInsets.fromLTRB(
        22,
        20,
        22,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0x28FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Row(
            children: [
              Text(
                isNew
                    ? 'NUEVA NOTA'
                    : (_isEditing ? 'EDITAR NOTA' : 'VISTA PREVIA'),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                ),
              ),
              const Spacer(),
              if (!_isEditing && widget.onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  tooltip: 'Eliminar nota',
                  onPressed: () {
                    widget.onDelete!();
                    Navigator.pop(context);
                  },
                ),
              if (!_isEditing)
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: _kAccent, size: 20),
                  tooltip: 'Editar nota',
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Content Editor/Markdown Render
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _isEditing
                  ? TextField(
                      controller: _contentCtrl,
                      focusNode: _editorFocusNode,
                      maxLines: null,
                      minLines: 5,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      cursorColor: _kAccent,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            'Escribe tu nota aquí...\nUsa #etiquetas inline para categorizar.',
                        hintStyle: TextStyle(
                          color: _kTextSecondary,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: MarkdownBody(
                        data: _contentCtrl.text,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(
                              Theme.of(context),
                            ).copyWith(
                              p: TextStyle(
                                color: _kTextPrimary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                              h1: TextStyle(
                                color: _kTextPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                              ),
                              h2: TextStyle(
                                color: _kTextPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                              ),
                              h3: TextStyle(
                                color: _kTextPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                              ),
                              code: TextStyle(
                                color: _kAccent,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                  width: 1,
                                ),
                              ),
                            ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          // Actions Buttons
          if (_isEditing)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: _kTextSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () {
                      if (isNew) {
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          _isEditing = false;
                          _contentCtrl.text = widget.note!.content;
                        });
                      }
                    },
                    child: Text(
                      'CANCELAR',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () {
                      final fullText = _contentCtrl.text.trim();
                      if (fullText.isEmpty) return;

                      final lines = fullText.split('\n');
                      final title = lines.isNotEmpty ? lines.first.trim() : '';
                      final tags = _extractTags(fullText);

                      widget.onSave(title, fullText, tags);

                      if (isNew) {
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          _isEditing = false;
                        });
                      }
                    },
                    child: Text(
                      isNew ? 'CREAR' : 'GUARDAR',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  foregroundColor: _kTextPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CERRAR',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Tag chip ─────────────────────────────────────────────────────────────────

class _ZenTagChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ZenTagChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isActive ? _kAccent : _kTextSecondary,
                fontSize: 9,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 1,
              width: 16,
              color: isActive ? _kAccent : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Note tile card ───────────────────────────────────────────────────────────

class _ZenNoteTile extends StatelessWidget {
  final NoteEntity note;
  final NotesViewModel vm;

  const _ZenNoteTile({required this.note, required this.vm});

  void _showEditSheet(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => ZenCanvasScreen(note: note)),
    );
  }

  void _showBacklinksSheet(BuildContext context) {
    final backlinks = vm.getBacklinksFor(note);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _BacklinksSheet(
        targetNote: note,
        backlinks: backlinks,
        onTapBacklink: (backlink) {
          Navigator.pop(ctx);
          Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (context) => ZenCanvasScreen(note: backlink),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = note.content.split('\n');
    final titleText = lines.isNotEmpty ? lines[0] : '';
    final bodyText = lines.length > 1 ? lines.sublist(1).join('\n') : '';

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
      ),
      onDismissed: (_) => vm.deleteNote(note.id),
      child: GestureDetector(
        onTap: () => _showEditSheet(context),
        onLongPress: () => _showBacklinksSheet(context),
        child: ZenCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      titleText,
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('HH:mm', 'es').format(note.date),
                    style: TextStyle(
                      color: _kTextSecondary,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              if (bodyText.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  bodyText.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: note.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _kAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              color: _kAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Modal launcher ──────────────────────────────────────────────────────────

void showNoteEditSheet(
  BuildContext context,
  NotesViewModel vm,
  NoteEntity? note,
) {
  showAdaptiveModal<void>(
    context,
    NoteEditorSheet(
      note: note,
      onSave: (title, content, tags) {
        if (note == null) {
          vm.createNote(title: title, content: content, tags: tags);
        } else {
          vm.updateNote(
            note.copyWith(
              title: title,
              content: content,
              date: note.date,
              tags: tags,
            ),
          );
        }
      },
      onDelete: note == null ? null : () => vm.deleteNote(note.id),
    ),
  );
}

// ─── Backlinks bottom sheet ─────────────────────────────────────────────────

class _BacklinksSheet extends StatelessWidget {
  final NoteEntity targetNote;
  final List<NoteEntity> backlinks;
  final void Function(NoteEntity) onTapBacklink;

  const _BacklinksSheet({
    required this.targetNote,
    required this.backlinks,
    required this.onTapBacklink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: Color(0x14FFFFFF), width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        20,
        22,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0x28FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'VINCULOS A',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  targetNote.title.isNotEmpty
                      ? targetNote.title
                      : '(sin título)',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: _kAccent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (backlinks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Sin vínculos entrantes',
                  style: TextStyle(color: _kTextSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: backlinks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final note = backlinks[i];
                  final preview = note.content
                      .split('\n')
                      .skip(1)
                      .take(2)
                      .join(' ')
                      .trim();
                  return InkWell(
                    onTap: () => onTapBacklink(note),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title.isNotEmpty ? note.title : '(sin título)',
                            style: TextStyle(
                              color: _kTextPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (preview.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              preview,
                              style: TextStyle(
                                color: _kTextSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
