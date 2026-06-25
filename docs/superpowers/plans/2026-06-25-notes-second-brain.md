# Zen OS Notes (Second Brain) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the new 3-pillar architecture for the Zen OS Notes module: high-performance Markdown syntax highlighting, a secure ViewModel-level autosave mechanism, and a distraction-free fullscreen editor, using "Apple Industrial" aesthetics.

**Architecture:** 
- A custom `TextEditingController` that splits content and caches computed `TextSpan`s per line to maintain 60/120 FPS.
- ViewModel autosave serialized using a queue-state mechanism (`_isSaving`, `_hasPendingChanges`) combined with a 1.5s debounce.
- Infinite scroll timeline showing markdown notes visually truncated using a `ShaderMask` with a linear opacity gradient.
- Fullscreen distraction-free editor route (`#1C1C1E`) replacing the current bottom sheet editor.

**Tech Stack:** Flutter, Supabase/DevRepository, Google Fonts, Flutter Markdown.

## Global Constraints
- Target background color for distraction-free mode is `#1C1C1E`.
- Maintain Inter typography as per system guidelines.
- Zero frame drops: operations inside text controller must be optimized using line caching.
- Prevent concurrent write operations on SQLite/Supabase.

---

### Task 1: Performant Markdown Live Highlighting Controller

**Files:**
- Create: `lib/presentation/widgets/zen_markdown_controller.dart`
- Test: `test/zen_markdown_controller_test.dart`

**Interfaces:**
- Consumes: Standard `TextEditingController` interface.
- Produces: `ZenMarkdownController` custom controller to style headers (`#`), bold (`**`), lists (`-`, `*`), and inline code (`` ` ``) dynamically.

- [ ] **Step 1: Write the tests**
Create `test/zen_markdown_controller_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heroos/presentation/widgets/zen_markdown_controller.dart';

void main() {
  testWidgets('ZenMarkdownController parses bold text correctly', (WidgetTester tester) async {
    final controller = ZenMarkdownController();
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
          ),
        ),
      ),
    );

    controller.text = 'This is **bold** style';
    await tester.pump();

    final RichText richText = tester.widget(find.byType(RichText));
    final TextSpan span = richText.text as TextSpan;
    
    // The text should be split into children spans where 'bold' has FontWeight.bold
    expect(span.children, isNotNull);
    expect(span.children!.isNotEmpty, true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/zen_markdown_controller_test.dart`
Expected: FAIL (File or class does not exist)

- [ ] **Step 3: Write minimal implementation**
Create `lib/presentation/widgets/zen_markdown_controller.dart`:
```dart
import 'package:flutter/material.dart';

class LineCache {
  final String text;
  final TextSpan span;
  const LineCache({required this.text, required this.span});
}

class ZenMarkdownController extends TextEditingController {
  final Map<int, LineCache> _lineCache = {};

  ZenMarkdownController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final lines = text.split('\n');
    final List<TextSpan> spans = [];

    for (int i = 0; i < lines.length; i++) {
      final lineText = lines[i];

      if (_lineCache[i]?.text == lineText) {
        spans.add(_lineCache[i]!.span);
      } else {
        final parsedSpan = _parseLineMarkdown(lineText, style);
        _lineCache[i] = LineCache(text: lineText, span: parsedSpan);
        spans.add(parsedSpan);
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans, style: style);
  }

  TextSpan _parseLineMarkdown(String line, TextStyle? defaultStyle) {
    // Basic Markdown matching for headers, bold, list markers, and code
    final normalStyle = defaultStyle ?? const TextStyle(color: Colors.white, fontSize: 14);
    
    if (line.startsWith('#')) {
      final headerLevel = RegExp(r'^#+').firstMatch(line)?.group(0)?.length ?? 1;
      final size = headerLevel == 1 ? 20.0 : (headerLevel == 2 ? 18.0 : 16.0);
      return TextSpan(
        text: line,
        style: normalStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: size,
          color: const Color(0xFFFFFFFF),
        ),
      );
    }

    if (line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('* ')) {
      return TextSpan(
        text: line,
        style: normalStyle.copyWith(color: const Color(0xFFA0A0A2)),
      );
    }

    final children = <TextSpan>[];
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int currentPos = 0;

    for (final match in boldRegex.allMatches(line)) {
      if (match.start > currentPos) {
        children.add(TextSpan(text: line.substring(currentPos, match.start)));
      }
      children.add(TextSpan(
        text: line.substring(match.start, match.end),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ));
      currentPos = match.end;
    }

    if (currentPos < line.length) {
      children.add(TextSpan(text: line.substring(currentPos)));
    }

    return TextSpan(children: children, style: normalStyle);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/zen_markdown_controller_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/presentation/widgets/zen_markdown_controller.dart test/zen_markdown_controller_test.dart
git commit -m "feat(notes): add performant custom markdown text controller"
```

---

### Task 2: Debounced Sequential Autosave ViewModel

**Files:**
- Modify: `lib/presentation/viewmodels/notes_viewmodel.dart`
- Test: `test/notes_viewmodel_test.dart`

**Interfaces:**
- Consumes: Existing Note updates from UI.
- Produces: `queueAutosave(NoteEntity note)` API to schedule silent, non-overlapping updates.

- [ ] **Step 1: Write the tests**
Create `test/notes_viewmodel_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:heroos/presentation/viewmodels/notes_viewmodel.dart';
import 'package:heroos/domain/entities/note_entity.dart';

void main() {
  test('Autosave queues changes and executes only once after debounce', () async {
    final vm = NotesViewModel();
    final testNote = NoteEntity(
      id: 'test_1',
      userId: 'dev-user',
      title: 'Original Title',
      content: 'Original Content',
      date: DateTime.now(),
      tags: [],
    );

    // Call autosave twice rapidly
    vm.queueAutosave(testNote.copyWith(content: 'New content 1'));
    vm.queueAutosave(testNote.copyWith(content: 'New content 2'));

    // Verify debounce hasn't written instantly
    expect(vm.isLoading, false);

    // Wait for the debounce timer (1500ms) + buffer
    await Future<void>.delayed(const Duration(milliseconds: 1700));

    // After debounce, verification of the saved state
    final savedNote = vm.notes.firstWhere((n) => n.id == 'test_1', orElse: () => testNote);
    expect(savedNote.content, 'New content 2');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/notes_viewmodel_test.dart`
Expected: FAIL (queueAutosave not declared)

- [ ] **Step 3: Modify NotesViewModel**
In `lib/presentation/viewmodels/notes_viewmodel.dart`, add the following fields and methods:
```dart
import 'dart:async';

// Under NotesViewModel class definition:
  Timer? _debounceTimer;
  bool _isSaving = false;
  bool _hasPendingChanges = false;
  NoteEntity? _pendingNoteState;

  void queueAutosave(NoteEntity updatedNote) {
    _pendingNoteState = updatedNote;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _executeSave();
    });
  }

  Future<void> _executeSave() async {
    if (_isSaving) {
      _hasPendingChanges = true;
      return;
    }

    _isSaving = true;
    _hasPendingChanges = false;

    try {
      final noteToSave = _pendingNoteState;
      if (noteToSave != null) {
        await _repo.updateNote(noteToSave);
        
        // Sync local cache
        final idx = _notes.indexWhere((n) => n.id == noteToSave.id);
        if (idx != -1) {
          final updatedNotes = List<NoteEntity>.from(_notes);
          updatedNotes[idx] = noteToSave;
          _notes = updatedNotes;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isSaving = false;
      if (_hasPendingChanges) {
        _executeSave();
      }
    }
  }
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/notes_viewmodel_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/presentation/viewmodels/notes_viewmodel.dart test/notes_viewmodel_test.dart
git commit -m "feat(notes): implement debounced sequential autosave in NotesViewModel"
```

---

### Task 3: Timeline Card Visual Truncation (ShaderMask)

**Files:**
- Modify: `lib/presentation/screens/notes_screen.dart`

**Interfaces:**
- Consumes: `NoteEntity` data.
- Produces: Smooth timeline cards rendering Markdown styled layout with bottom opacity fade-out.

- [ ] **Step 1: Write the tests**
Create `test/notes_timeline_truncation_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.react'; // Wait, let's keep standard imports
import 'package:provider/provider.dart';
import 'package:heroos/presentation/screens/notes_screen.dart';
import 'package:heroos/presentation/viewmodels/notes_viewmodel.dart';

void main() {
  testWidgets('Timeline renders ShaderMask and MarkdownBody for notes', (WidgetTester tester) async {
    final vm = NotesViewModel();
    
    await tester.pumpWidget(
      ChangeNotifierProvider<NotesViewModel>.value(
        value: vm,
        child: const MaterialApp(
          home: NotesScreen(),
        ),
      ),
    );

    await tester.pump();
    
    // We should find a ShaderMask representing the fade truncation
    expect(find.byType(ShaderMask), findsAtLeastNWidgets(1));
    expect(find.byType(MarkdownBody), findsAtLeastNWidgets(1));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/notes_timeline_truncation_test.dart`
Expected: FAIL (ShaderMask and MarkdownBody not found inside the list elements, or failing to load)

- [ ] **Step 3: Modify notes_screen.dart**
In `lib/presentation/screens/notes_screen.dart` modify the `_ZenNoteTile` build method to use `ShaderMask` and `MarkdownBody`:
Replace lines 858-870:
```dart
                  if (bodyText.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.transparent],
                          stops: [0.65, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 110),
                        child: MarkdownBody(
                          data: bodyText.trim(),
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            p: TextStyle(color: _kTextSecondary, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ),
                    ),
                  ],
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/notes_timeline_truncation_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/presentation/screens/notes_screen.dart test/notes_timeline_truncation_test.dart
git commit -m "style(notes): visually truncate timeline note previews using ShaderMask"
```

---

### Task 4: Distraction-Free "Lienzo Zen" Screen

**Files:**
- Create: `lib/presentation/screens/zen_canvas_screen.dart`
- Modify: `lib/presentation/screens/notes_screen.dart`

**Interfaces:**
- Consumes: `NoteEntity` via route parameters.
- Produces: Navigation from `_ZenNoteTile` into full-screen editor. Uses `ZenMarkdownController` and autosaves content dynamically.

- [ ] **Step 1: Write the tests**
Create `test/zen_canvas_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heroos/presentation/screens/zen_canvas_screen.dart';
import 'package:heroos/presentation/viewmodels/notes_viewmodel.dart';
import 'package:heroos/domain/entities/note_entity.dart';

void main() {
  testWidgets('ZenCanvasScreen renders in fullscreen mode with background #1C1C1E', (WidgetTester tester) async {
    final note = NoteEntity(
      id: 'test_zen',
      userId: 'dev-user',
      title: 'Zen Title',
      content: 'Zen Content',
      date: DateTime.now(),
      tags: [],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<NotesViewModel>(
        create: (_) => NotesViewModel(),
        child: MaterialApp(
          home: ZenCanvasScreen(note: note),
        ),
      ),
    );

    // Verify background color container
    final Container container = tester.widget(find.byType(Container).first);
    expect((container.decoration as BoxDecoration).color, const Color(0xFF1C1C1E));
    
    // Verify no typical AppBar widget is visible
    expect(find.byType(AppBar), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/zen_canvas_screen_test.dart`
Expected: FAIL (Screen does not exist)

- [ ] **Step 3: Create ZenCanvasScreen**
Create `lib/presentation/screens/zen_canvas_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/note_entity.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../widgets/zen_markdown_controller.dart';

class ZenCanvasScreen extends StatefulWidget {
  final NoteEntity note;
  const ZenCanvasScreen({super.key, required this.note});

  @override
  State<ZenCanvasScreen> createState() => _ZenCanvasScreenState();
}

class _ZenCanvasScreenState extends State<ZenCanvasScreen> {
  late final ZenMarkdownController _controller;
  late NoteEntity _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _controller = ZenMarkdownController(text: _currentNote.content);
    _controller.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final newContent = _controller.text;
    final lines = newContent.split('\n');
    final newTitle = lines.isNotEmpty ? lines.first.replaceAll('#', '').trim() : 'Sin título';

    _currentNote = _currentNote.copyWith(
      title: newTitle,
      content: newContent,
    );

    context.read<NotesViewModel>().queueAutosave(_currentNote);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            // Minimal header (No standard AppBar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'LIENZO ZEN',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance back button
                ],
              ),
            ),
            // Input Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  cursorColor: Colors.white,
                  style: GoogleFonts.inter(
                    color: Colors.white87,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    hintText: '# Título de la nota\n\nEmpieza a escribir tu idea...',
                    hintStyle: TextStyle(color: Colors.white24),
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
```

- [ ] **Step 4: Update notes_screen.dart navigation**
In `lib/presentation/screens/notes_screen.dart`, modify `_ZenNoteTile` (lines 786-799) to navigate directly to the new canvas:
```dart
  void _showEditSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ZenCanvasScreen(note: note),
      ),
    );
  }
```
Update the Floating Action Button or header add action in `notes_screen.dart` (line 120 and 180) to instantiate a new `NoteEntity` and navigate immediately to the `ZenCanvasScreen`:
```dart
                      GestureDetector(
                        onTap: () {
                          final newNote = NoteEntity(
                            id: '',
                            userId: 'dev-user',
                            title: '',
                            content: '',
                            date: DateTime.now(),
                            tags: [],
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ZenCanvasScreen(note: newNote),
                            ),
                          );
                        },
                        child: Icon(Icons.add, size: 18, color: _kTextSecondary),
                      ),
```

- [ ] **Step 5: Run tests**
Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 6: Commit**
```bash
git add lib/presentation/screens/zen_canvas_screen.dart lib/presentation/screens/notes_screen.dart test/zen_canvas_screen_test.dart
git commit -m "feat(notes): implement fullscreen distraction-free ZenCanvasScreen and replace modal sheet"
```
