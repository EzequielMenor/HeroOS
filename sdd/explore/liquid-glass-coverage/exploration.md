## Exploration: Liquid Glass Coverage — Full Audit and Plan for 100% Package-Native Glass

### Current State
The HeroOS Flutter app uses `liquid_glass_widgets: ^0.18.4` with partial integration: 3 thin package wrappers (`glass_card.dart`, `glass_sheet.dart`, `glass_input.dart`), 2 DIY glass surfaces (`glass_action_button.dart`, `liquid_glass_indicator.dart`), and scattered glass on ~5 of 11 screens (dashboard AppBar + nav, zen_canvas toolbar, some notes tiles, sleep cards). **6 screens have zero glass**: splash, login, finance, habits, tasks, profile. No global `GlassThemeData` is configured in `main.dart`. The upstream repo's canonical iOS 26 look (two-pass blur + chromatic refraction, upper-left 135° lighting, Fresnel rim highlights) is not matched.

### Affected Areas
- `lib/main.dart` — missing `theme:` parameter in `LiquidGlassWidgets.wrap()`
- `lib/presentation/screens/dashboard_screen.dart` — DIY `_LiquidNavBar` + capsule indicator
- `lib/presentation/screens/finance_screen.dart` — 1703 LOC, entirely solid surfaces
- `lib/presentation/screens/habits_screen.dart` — 1432 LOC, all surfaces solid
- `lib/presentation/screens/tasks_screen.dart` — 1423 LOC, all surfaces solid
- `lib/presentation/screens/notes_screen.dart` — DIY `_ZenNoteTile` BackdropFilter + ShaderMask
- `lib/presentation/screens/sleep_screen.dart` — hybrid (some GlassCard, mostly solid)
- `lib/presentation/screens/profile_screen.dart` — all solid, many plain TextFields
- `lib/presentation/screens/login_screen.dart` — all solid, critical UX path
- `lib/presentation/screens/splash_screen.dart` — all solid, transient
- `lib/presentation/widgets/glass_action_button.dart` — 139 LOC DIY BackdropFilter
- `lib/presentation/widgets/liquid_glass_indicator.dart` — 68 LOC DIY capsule
- `lib/presentation/widgets/quick_capture_input.dart` — solid AIVoiceSheet + FABs
- `lib/presentation/widgets/habit_stats_card.dart` — Material Card, no glass
- `lib/presentation/widgets/responsive_shell.dart` — DIY BackdropFilter in DesktopOmniboxDialog
- `lib/presentation/widgets/zen_sidebar.dart` — solid #1C1C1E background

### Approaches
1. **Full glass everywhere (user request)** — Apply `GlassCard`/`GlassListTile`/`GlassSheet`/`GlassButton` to every surface across all 11 screens.
   - Pros: Matches "100% liquid glass como en el repo" exactly; consistent look
   - Cons: Upstream philosophy says glass = navigation chrome, not content lists; GPU cost on dense scrollable lists; ~+300 LOC; 7 chained PRs
   - Effort: High

2. **Phase-and-surface approach (recommended)** — Apply glass with tiered depth: full glass on navigation/chrome, selective glass on content cards, minimal on dense lists.
   - Pros: Performance-balanced; respects upstream patterns while matching user request; clear PR boundaries
   - Cons: More decision points per surface; needs a style guide to ensure consistency
   - Effort: Medium

3. **Foundation + widget layer only** — Set global GlassTheme + rewrite DIY widgets only; defer per-screen surfaces.
   - Pros: Fastest path to "deliverable"; fixes the most technical debt first
   - Cons: User gets no visible change on 6 screens; anti-climactic
   - Effort: Low

### Recommendation
**Approach 2 (Phase-and-surface)**. Break into 7 chained PRs:

| Phase | Scope | PR Size |
|-------|-------|---------|
| 0: Foundation | Global GlassTheme + adaptiveQuality in `main.dart` | ~20 LOC |
| 1: Widget Layer | Rewrite `glass_action_button.dart`/`liquid_glass_indicator.dart`; wrap `habit_stats_card.dart` | ~100 LOC |
| 2: Navigation Chrome | Dashboard nav bar → `GlassTabBar.bottom()`; remove DIY indicator; sidebar glass | ~150 LOC |
| 3: Screen Batch 1 | Dashboard cards, notes tiles/sheets, habits surfaces | ~200 LOC |
| 4: Screen Batch 2 | Finance tiles/sheets, tasks tiles/sheets, sleep tiles | ~200 LOC |
| 5: Screen Batch 3 | Login, splash, profile, zen_canvas overlay | ~150 LOC |
| 6: Polish | Settings consistency, BackdropFilter+IndexedStack safety, contrast check | ~50 LOC |

PRs 0-1 are prerequisites. PRs 3-6 are independent of each other (can reorder).

### Risks
- **BackdropFilter + IndexedStack GPU hang on iOS** — web layout uses IndexedStack for dashboard tabs; glass widgets in offstage children can trigger Metal GPU hangs. Mitigate with `ClipRect` wrapping or conditional glass-on-visible.
- **Local `GlassCard` class shadows package `GlassCard`** — solved by `import ... as pkg` prefix, already in use by wrappers
- **Text contrast over glass** — Zen OS `textSecondary` at 45% opacity may drop below WCAG AA on glass surfaces with 8-15% white tint
- **Font rendering artifacts** — Inter font may show baseline jitter over blurred glass on some Android GPUs
- **Package upgrade risk** — on v0.18.4, latest is 0.19.1; upgrade AFTER this apply cycle to avoid breaking changes mid-stream
- **Performance on dense lists** — every transaction/habit/task tile with GlassListTile = O(n) blur operations; recommend standard quality for scrollable, premium for static

### Ready for Proposal
**Yes.** Full audit is complete. Each of the 11 screens has a per-surface status table. The 7-phase PR plan avoids the 400-line review budget. Recommendation is to start with Phase 0 (Foundation) — add `GlassThemeData` to `LiquidGlassWidgets.wrap()` — which unblocks all downstream phases.
