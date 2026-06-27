# Proposal: Zettelkasten Notes

## Intent

To evolve the basic note-taking module into a native Zettelkasten (Second Brain) knowledge base. This allows users to bidirectionally link ideas, navigate backlinks, write in a zen-like fullscreen editor, and read chronologically in a clean timeline.

## Scope

### In Scope
- **Timeline Daily View**: Chronological grouping of notes by dates ("HOY", "AYER", formatted dates) with monospaced time prefixes. Smart content truncation via 120px height Fade-Out ShaderMask and tap-to-view.
- **Zen Canvas Editor**: Fullscreen writing mode without AppBar. Real-time Markdown formatting via `ZenMarkdownController`. Silent 1500ms auto-save debounce and swipe-back pop invocation final save.
- **WikiLinks & Backlinks**: Cursor-based predictive search popup triggered on `[[` typing. Autocomplete of note ID/Title on tap. Backlinks Inspector bottom sheet showing referencing notes and allowing jumps.

### Out of Scope
- Graph visualization of note connections.
- Formatting imports/exports from external tools like Obsidian.
- Modifying Supabase table schemas (connections computed dynamically).

## Capabilities

### New Capabilities
- `zettelkasten-notes`: Native Zettelkasten implementation, timelines, WikiLinks, and Zen Canvas editor.

### Modified Capabilities
- None

## Approach

1. **State & Parsing**: Update `NotesViewModel` to parse WikiLinks (`[[Note Title/ID]]`) in note content and dynamically calculate backlinks.
2. **Predictive Autocomplete**: Implement an Overlay-based autocomplete popup in `ZenCanvasScreen` that filters notes matching input after `[[`.
3. **WikiLinks Highlighting**: Enhance `ZenMarkdownController` to syntax-highlight WikiLinks.
4. **Timeline UI**: Update `NotesScreen` to use a `ShaderMask` for a 120px fade-out container on note tiles, adding monospaced time prefixes.
5. **Autosave pop integration**: Leverage `PopScope` to guarantee a final save flush on pop gestures.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/domain/entities/note_entity.dart` | Modified | Add helper to extract linked note titles/IDs from markdown content. |
| `lib/presentation/viewmodels/notes_viewmodel.dart` | Modified | Add autocomplete queries, backlinks computation, and link mapping. |
| `lib/presentation/widgets/zen_markdown_controller.dart` | Modified | Handle syntax highlighting for `[[WikiLinks]]`. |
| `lib/presentation/screens/zen_canvas_screen.dart` | Modified | Overlay popup on `[[`, autocompletion, and pop-to-save integration. |
| `lib/presentation/screens/notes_screen.dart` | Modified | ShaderMask fade-out at 120px, monospaced time prefix, and navigation from backlinks. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Parsing performance of WikiLinks on large note counts | Low | Parse links lazily or cache link mappings in the ViewModel. |
| Overlay autocomplete position mapping | Med | Use Flutter's `CompositedTransformTarget` to anchor to the cursor or text field. |

## Rollback Plan

Discard workspace changes using `git checkout` / `git reset`. No database migrations are needed.

## Dependencies

- None

## Success Criteria

- [ ] Users can type `[[` in Zen Canvas and see a popup list of existing notes to autocomplete.
- [ ] Notes in the timeline display with monospaced times (e.g., `12:34`) and a 120px tall fade-out using a `ShaderMask`.
- [ ] Notes show a bottom sheet listing all other notes referencing them (backlinks), allowing navigation.
- [ ] Swiping back from Zen Canvas triggers a final save flush successfully.
