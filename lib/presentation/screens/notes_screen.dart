import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/adaptive_modal.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/note_entity.dart';
import '../viewmodels/notes_viewmodel.dart';

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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.sageGreen),
      );
    }

    if (context.isWeb) {
      return _buildWebLayout(vm);
    }
    return _buildMobileLayout(vm);
  }

  Widget _buildWebLayout(NotesViewModel vm) {
    return Scaffold(
      body: Row(
        children: [
          // Left: tag filter + search
          SizedBox(
            width: 280,
            child: _buildSidebar(vm),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          // Right: note list
          Expanded(
            child: _buildNoteList(vm),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_fab', // ponytail: unique tag — IndexedStack keeps all sibling FABs mounted
        backgroundColor: AppColors.sageGreen,
        onPressed: () => _showEditSheet(context, vm, null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMobileLayout(NotesViewModel vm) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Notas',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textPrimary),
            onPressed: () => _showEditSheet(context, vm, null),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(vm),
          if (vm.allTags.isNotEmpty) _buildTagFilter(vm),
          Expanded(child: _buildNoteList(vm)),
        ],
      ),
    );
  }

  Widget _buildSidebar(NotesViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.note_alt_outlined, color: AppColors.sageGreen),
              const SizedBox(width: 8),
              const Text(
                'Notas',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.sageGreen),
                onPressed: () => _showEditSheet(context, vm, null),
              ),
            ],
          ),
        ),
        _buildSearchBar(vm),
        if (vm.allTags.isNotEmpty) _buildTagFilter(vm),
        const Divider(color: AppColors.divider),
        Expanded(child: _buildNoteList(vm)),
      ],
    );
  }

  Widget _buildSearchBar(NotesViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Buscar notas...',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: vm.search,
      ),
    );
  }

  Widget _buildTagFilter(NotesViewModel vm) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _TagChip(
            label: 'Todas',
            isActive: vm.selectedTag == null,
            onTap: () => vm.filterByTag(null),
          ),
          ...vm.allTags.map((tag) => _TagChip(
                label: tag,
                isActive: vm.selectedTag == tag,
                onTap: () => vm.filterByTag(tag),
              )),
        ],
      ),
    );
  }

  Widget _buildNoteList(NotesViewModel vm) {
    if (vm.notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_alt_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              vm.searchQuery.isNotEmpty || vm.selectedTag != null
                  ? 'Sin notas que coincidan'
                  : 'Crea tu primera nota',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: vm.notes.length,
      itemBuilder: (ctx, i) {
        final note = vm.notes[i];
        return _NoteTile(note: note, vm: vm);
      },
    );
  }

  void _showEditSheet(BuildContext context, NotesViewModel vm, NoteEntity? note) {
    showAdaptiveModal<void>(
      context,
      _NoteEditorSheet(
        note: note,
        onSave: (title, content, tags) {
          if (note == null) {
            vm.createNote(title: title, content: content, tags: tags);
          } else {
            vm.updateNote(note.copyWith(title: title, content: content, date: note.date, tags: tags));
          }
        },
      ),
    );
  }
}

class _NoteEditorSheet extends StatelessWidget {
  final NoteEntity? note;
  final void Function(String title, String content, List<String> tags) onSave;

  const _NoteEditorSheet({required this.note, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final isNew = note == null;
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');
    final tagsCtrl = TextEditingController(text: note?.tags.join(', ') ?? '');

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNew ? 'Nueva Nota' : 'Editar Nota',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Título',
                hintStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Contenido',
                hintStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagsCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Tags (separados por coma)',
                hintStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sageGreen,
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
                child: Text(isNew ? 'Crear' : 'Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.sageGreen : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.sageGreen : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final NoteEntity note;
  final NotesViewModel vm;

  const _NoteTile({required this.note, required this.vm});

  void _showEditSheet(BuildContext context) {
    showAdaptiveModal<void>(
      context,
      _NoteEditorSheet(
        note: note,
        onSave: (title, content, tags) {
          vm.updateNote(note.copyWith(title: title, content: content, date: note.date, tags: tags));
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
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => vm.deleteNote(note.id),
      child: ListTile(
        title: Text(
          note.title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.content.isNotEmpty)
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('d MMM', 'es').format(note.date),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.label_outline, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      note.tags.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.sageGreen, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () => _showEditSheet(context),
      ),
    );
  }
}
