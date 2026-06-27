# Tasks: Zettelkasten Notes

## Phase 1: Zettelkasten Implementation

- [x] 1.1 Define WikiLinks regex constant `wikiLinkRegex` and add `getLinkedTargets()` to `NoteEntity`
- [x] 1.2 Add `getBacklinksFor(NoteEntity)` and `getAutocompleteSuggestions(String)` to `NotesViewModel`
- [x] 1.3 Add WikiLink syntax highlighting (`[[` / `]]` brackets in purple, target/label underlined) to `ZenMarkdownController`
- [x] 1.4 Integrate autocomplete overlay with `CompositedTransformTarget`/`Follower` in `ZenCanvasScreen`, trigger on `[[`, cleanup on dispose/pop
- [x] 1.5 Truncate note cards at 120px with `ShaderMask` gradient, monospace timestamps, and sliding backlinks bottom sheet in `NotesScreen`
- [x] 1.6 Write unit tests for WikiLinks parsing and autocomplete/backlinks

## Verification

- [x] `flutter analyze` passes (no errors)
- [x] Unit tests pass (15/15)
