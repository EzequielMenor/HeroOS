import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/adaptive_modal.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/note_entity.dart';
import '../viewmodels/notes_viewmodel.dart';

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
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 1.5)),
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
      backgroundColor: _kBg,
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
      backgroundColor: _kBg,
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
                        onTap: () => showNoteEditSheet(context, vm, null),
                        child: Icon(Icons.add, size: 18, color: _kTextSecondary),
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
                      onTap: () => showNoteEditSheet(context, vm, null),
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
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(color: _kTextPrimary, fontSize: 14),
        cursorColor: _kAccent,
        decoration: InputDecoration(
          hintText: 'Buscar notas…',
          hintStyle: TextStyle(color: _kTextSecondary, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: _kTextSecondary, size: 18),
          prefixIconConstraints: BoxConstraints(minWidth: 36, minHeight: 36),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: _kDivider),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: _kAccent),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: vm.search,
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
          ...vm.allTags.map((tag) => _ZenTagChip(
                label: tag,
                isActive: vm.selectedTag == tag,
                onTap: () => vm.filterByTag(tag),
              )),
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

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 100),
      itemCount: vm.notes.length,
      itemBuilder: (ctx, i) {
        final note = vm.notes[i];
        return _ZenNoteTile(note: note, vm: vm);
      },
    );
  }

  // ── Edit sheet ────────────────────────────────────────────────────────────

}

// ─── Note editor sheet ────────────────────────────────────────────────────────

class NoteEditorSheet extends StatelessWidget {
  final NoteEntity? note;
  final void Function(String title, String content, List<String> tags) onSave;

  const NoteEditorSheet({required this.note, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final isNew = note == null;
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');
    final tagsCtrl = TextEditingController(text: note?.tags.join(', ') ?? '');

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(
          top: BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        26,
        22,
        MediaQuery.of(context).viewInsets.bottom + 44,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 2,
                color: Color(0x28FFFFFF),
              ),
            ),
            SizedBox(height: 22),
            Text(
              isNew ? 'Nueva nota' : 'Editar nota',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary,
              ),
            ),
            SizedBox(height: 20),
            _sheetInput(controller: titleCtrl, hint: 'Título'),
            SizedBox(height: 16),
            _sheetInput(controller: contentCtrl, hint: 'Contenido', maxLines: 4),
            SizedBox(height: 16),
            _sheetInput(controller: tagsCtrl, hint: 'Etiquetas (separadas por coma)'),
            SizedBox(height: 28),
            Row(
              children: [
                // Cancel
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: _kTextSecondary,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCELAR',
                      style: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Save
                Expanded(
                  flex: 2,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      final content = contentCtrl.text.trim();
                      if (title.isEmpty) return;
                      final tags = tagsCtrl.text
                          .split(',')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty)
                          .toList();
                      onSave(title, content, tags);
                      Navigator.pop(context);
                    },
                    child: Text(
                      isNew ? 'CREAR' : 'GUARDAR',
                      style: TextStyle(
                          fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      padding: EdgeInsets.only(right: 16),
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
            SizedBox(height: 4),
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
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

// ─── Note tile ────────────────────────────────────────────────────────────────

class _ZenNoteTile extends StatelessWidget {
  final NoteEntity note;
  final NotesViewModel vm;

  const _ZenNoteTile({required this.note, required this.vm});

  void _showEditSheet(BuildContext context) {
    showAdaptiveModal<void>(
      context,
      NoteEditorSheet(
        note: note,
        onSave: (title, content, tags) {
          vm.updateNote(
              note.copyWith(title: title, content: content, date: note.date, tags: tags));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        color: AppColors.danger,
        child: Icon(Icons.delete_outline, color: Colors.white, size: 18),
      ),
      onDismissed: (_) => vm.deleteNote(note.id),
      child: GestureDetector(
        onTap: () => _showEditSheet(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: _kDivider, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (note.content.isNotEmpty) ...[
                      SizedBox(height: 3),
                      Text(
                        note.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _kTextSecondary, fontSize: 12),
                      ),
                    ],
                    if (note.tags.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        note.tags.map((t) => '#$t').join('  '),
                        style: TextStyle(
                            color: _kAccent, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 16),
              Text(
                DateFormat('d MMM', 'es').format(note.date).toUpperCase(),
                style: TextStyle(color: _kTextSecondary, fontSize: 10, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sheet input helper ───────────────────────────────────────────────────────

Widget _sheetInput({
  required TextEditingController controller,
  required String hint,
  int maxLines = 1,
}) {
  return TextField(
    controller: controller,
    style: TextStyle(color: _kTextPrimary, fontSize: 14),
    maxLines: maxLines,
    cursorColor: _kAccent,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _kTextSecondary, fontSize: 14),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: _kDivider),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: _kAccent),
      ),
      contentPadding: EdgeInsets.only(bottom: 8),
    ),
  );
}


  void showNoteEditSheet(BuildContext context, NotesViewModel vm, NoteEntity? note) {
    showAdaptiveModal<void>(
      context,
      NoteEditorSheet(
        note: note,
        onSave: (title, content, tags) {
          if (note == null) {
            vm.createNote(title: title, content: content, tags: tags);
          } else {
            vm.updateNote(
                note.copyWith(title: title, content: content, date: note.date, tags: tags));
          }
        },
      ),
    );
  }
