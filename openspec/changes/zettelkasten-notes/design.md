# Design: Zettelkasten Notes

## Technical Approach

We will evolve the note-taking module into a Zettelkasten system by introducing:
1. **Dynamic WikiLink Parsing**: Parse incoming references using a standardized regular expression.
2. **Dynamic Backlinks Retrieval**: Scan the active notes list in memory to resolve backlinks dynamically.
3. **WikiLinks Highlighting**: Customize the `ZenMarkdownController` syntax highlighter to render double-brackets and custom-labeled links (`[[Target|Label]]`) using distinctive styles.
4. **Autocomplete Overlay**: Detect `[[` triggers, project an IDE-style autocomplete list below the text field using Flutter's `CompositedTransformFollower`, and insert the selected link.
5. **Timeline Layout Polish**: Standardize timeline daily grouping, format times in a monospaced font, and enforce a 120px tall fade-out list container with tap-to-view/backlink inspector options.

## Architecture Decisions

| Decision | Choice | Alternatives | Rationale | Risks & Mitigation |
|----------|--------|--------------|-----------|--------------------|
| **WikiLink Parsing** | Regular expression splitting in entity layer: `\[\[([^\]|]+)(?:\|([^\]]+))?\]\]` | Full AST markdown tokenizer | Simple, high performance, directly supports the custom label requirement without dependency bloat. | **Risk**: Complex/broken nested syntax. <br>**Mitigation**: Strict regex match rules and unit testing. |
| **Backlinks Resolution** | In-memory evaluation on demand in `NotesViewModel` | Database-level foreign keys | Fits the serverless Supabase architecture without breaking changes to database schemas. | **Risk**: Performance degradation on 1000+ notes. <br>**Mitigation**: Lazily compute or memoize results. |
| **Autocomplete UI** | `OverlayEntry` anchored via `LayerLink` | Inline dropdown sheet or navigation page | Provides a seamless, non-intrusive desktop/Zen editor feel. | **Risk**: Overlay orphaned on page pop or resize. <br>**Mitigation**: Clean up overlay entry in `dispose` / `deactivate`. |

## Data Flow

```
[User Input: "[["] -> (Scan Text Cursor) -> Trigger Suggestion Box
                                                 |
                                         (Filter notes by Title)
                                                 |
                                    [Overlay Display / Tap Suggestion]
                                                 |
                                     (Insert "[[Target|Label]]")
                                                 |
                                     (Debounced Auto-Save)
                                                 |
[Notes List] <----- (Calculate Backlinks) <--- [State Update]
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| [note_entity.dart](file:///Users/ezequielmenor/2DAM/HeroOS/heroos/lib/domain/entities/note_entity.dart) | Modify | Add `getLinkedTargets()` using the WikiLink parsing regex. |
| [notes_viewmodel.dart](file:///Users/ezequielmenor/2DAM/HeroOS/heroos/lib/presentation/viewmodels/notes_viewmodel.dart) | Modify | Add `getBacklinksFor(NoteEntity)` and `getAutocompleteSuggestions(String)`. |
| [zen_markdown_controller.dart](file:///Users/ezequielmenor/2DAM/HeroOS/heroos/lib/presentation/widgets/zen_markdown_controller.dart) | Modify | Highlight WikiLinks (`[[` and `]]` in secondary/muted color, label or target in underline accent). |
| [zen_canvas_screen.dart](file:///Users/ezequielmenor/2DAM/HeroOS/heroos/lib/presentation/screens/zen_canvas_screen.dart) | Modify | Integrate `CompositedTransformTarget`, monitor input for `[[`, handle autocompletion popup overlays. |
| [notes_screen.dart](file:///Users/ezequielmenor/2DAM/HeroOS/heroos/lib/presentation/screens/notes_screen.dart) | Modify | Standardize daily grouping header styles, apply monospaced prefix font to note times, and add Backlinks bottom sheet picker. |

## Interfaces / Contracts

### 1. Note Entity WikiLink Extraction
```dart
// lib/domain/entities/note_entity.dart
List<String> getLinkedTargets() {
  final regex = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');
  return regex.allMatches(content).map((m) => m.group(1)!.trim()).toList();
}
```

### 2. ViewModel Backlink and Query APIs
```dart
// lib/presentation/viewmodels/notes_viewmodel.dart
List<NoteEntity> getBacklinksFor(NoteEntity targetNote) {
  final targetId = targetNote.id.toLowerCase();
  final targetTitle = targetNote.title.toLowerCase();
  return _notes.where((n) {
    if (n.id == targetNote.id) return false;
    return n.getLinkedTargets().any((link) {
      final clean = link.toLowerCase();
      return clean == targetId || clean == targetTitle;
    });
  }).toList();
}

List<NoteEntity> getAutocompleteSuggestions(String query) {
  if (query.isEmpty) return _notes;
  final lowerQuery = query.toLowerCase();
  return _notes.where((n) => n.title.toLowerCase().contains(lowerQuery)).toList();
}
```

### 3. Controller Inline Rendering (WikiLink Parsing)
```dart
// lib/presentation/widgets/zen_markdown_controller.dart
final wikiLinkRegex = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');
// inside buildTextSpan loop matching:
// group(1) -> target ID/title
// group(2) -> display label (if any)
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| **Unit** | WikiLink regex matching | Validate targets extraction with `[[ID]]` and `[[ID\|Text]]`. |
| **Unit** | Backlinks retrieval | Verify VM correctly connects referencing and referenced notes. |
| **Widget** | Markdown rendering | Assert WikiLink brackets/text are formatted with target colors. |
| **Widget** | Suggestions Popup | Test Overlay appears on typing `[[` and autocompletes content on tap. |

## Migration / Rollout

No migration required.
