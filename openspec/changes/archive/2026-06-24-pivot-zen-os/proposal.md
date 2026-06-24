# Proposal: Pivot to Zen OS

## Intent

Pivot HeroOS from an RPG-gamified life tracker into **Zen OS**, a minimalist AI-powered personal management system. The RPG layer adds visual noise and false motivation — users don't need XP bars to track habits or expenses. Zen OS strips that away. The user provides their own AI API key; the system classifies free-form input (typed or spoken) into structured data — expense, task, habit, or note — routing it to the right repository automatically.

## Scope

### DELETE (4 files)
- `lib/domain/entities/rpg_event_entity.dart`
- `lib/data/repositories/rpg_events_repository.dart`
- `lib/presentation/widgets/rpg_hud.dart`
- `lib/presentation/viewmodels/stats_viewmodel.dart`

### TRANSFORM (24 files)
- **ProfileEntity**: remove 7 RPG fields (level, currentXp, xpNextLevel, currentHp, maxHp, currentGold, isAlive); add `aiApiKey` (String) + `aiProvider` (String)
- **HabitEntity**: remove xpReward, dmgPenalty, xpValue; keep `currentStreak` (behavioral psychology)
- **TaskEntity**: remove xpValue; replace `difficulty` with `energy` (enum: low/medium/high)
- **AppColors**: replace `#9C27B0` (purple) with `#8FBC8F` (sage green) across ~80 references; dark background `#121212`
- **Dashboard**: repurpose as "Today Overview" — greeting, circular habits-completion %, urgent tasks, sleep indicator
- **All screens**: strip HeroOS/RPG branding, XP/level references, fire/explosion animations

### KEEP (27 files)
Finance, Sleep, Habit, Task, Goal, Auth repositories and screens. Repository pattern, Provider state, GoRouter routing — no structural changes.

### Out of Scope
- New platforms (iOS/Android/Web as-is)
- Authentication overhaul (existing Supabase auth stays)
- Multi-user or team features

## Capabilities

### New Capabilities
- `ai-classification`: receives free-form text, returns JSON classification (`GASTO|TAREA|HABITO|NOTA`) with extracted fields via user-provided AI API key
- `quick-capture`: single text input → AI classification → auto-save to correct repository
- `notes-management`: CRUD for free-form notes entity (title, content, date, tags)

### Modified Capabilities
- `profile`: remove RPG stats fields; add AI configuration fields (apiKey, provider)
- `habits`: remove XP mechanics; streak display refreshed (clean dots, no fire/explosions)
- `tasks`: replace difficulty with energy enum; remove XP
- `dashboard`: replace RPG HUD with Today Overview (greeting + habits % + urgent tasks + sleep)

## Approach

Three phases:
1. **Deep Clean**: Delete 4 RPG files, transform Profile/Habit/Task entities, replace AppColors, rebrand screens
2. **Data/Domain Layer**: Add `note_entity.dart`, `notes_repository.dart`, extend ProfileEntity with AI fields, extend existing repos
3. **AI Core**: `AIService` with system prompt + JSON parser, Quick Capture widget, settings screen for API key input

Supabase schema migration runs in the SAME PR:
- `DROP TABLE rpg_events`
- `ALTER TABLE profiles` (DROP 7 RPG columns, ADD aiApiKey TEXT, aiProvider TEXT)
- `ALTER TABLE habits` (DROP xpReward, dmgPenalty, xpValue)
- `ALTER TABLE tasks` (DROP xpValue, difficulty; ADD energy TEXT)
- `CREATE TABLE notes` (id UUID, title TEXT, content TEXT, date TIMESTAMPTZ, tags TEXT[], profile_id UUID FK)

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/domain/entities/` | Modified | ProfileEntity, HabitEntity, TaskEntity stripped of RPG fields |
| `lib/presentation/theme/` | Modified | AppColors accent + background replacement (~80 refs) |
| `lib/presentation/screens/dashboard/` | Removed/New | RPG HUD deleted; Today Overview built |
| `lib/data/repositories/` | Removed/New | rpg_events removed; notes_repository added |
| `lib/presentation/viewmodels/` | Removed/Modified | StatsViewModel deleted; 5 dependent VMs updated |
| Supabase schema | Modified | rpg_events dropped; profiles/habits/tasks altered; notes created |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| StatsViewModel removal breaks 5 consumers | Medium | Audit all injection points; replace with direct repo calls where needed |
| AppColors.rpg 80+ refs miss some | Low | Global search-replace, then `flutter analyze` catches missing symbols |
| Supabase migration on existing user data | Medium | Migration script tested on staging first; ALTER TABLE preserves data |
| Streak display regression | Low | Keep streak calculation logic untouched; only change presentation layer |

## Rollback Plan

1. Revert commit. All deleted RPG files recovered from git.
2. Supabase: reverse migration script (ADD back dropped columns, DROP new columns) applied if schema already migrated. Maintain a `rollback.sql` alongside `migration.sql`.
3. AppColors: re-run find-replace from sage → purple if needed. 5-minute operation.

## Dependencies

- User must provide their own AI API key (OpenAI or Gemini) — no built-in key
- Existing Supabase project and auth flow remain unchanged

## Success Criteria

- [ ] `flutter analyze` passes with zero errors after ALL transformations
- [ ] Dashboard renders Today Overview without any RPG widgets or XP references
- [ ] Task creation uses energy enum (not difficulty); habit creation excludes XP fields
- [ ] AppColors accent is `#8FBC8F` everywhere; no `#9C27B0` remains
- [ ] Supabase schema migration applies cleanly on fresh and existing databases
- [ ] Quick Capture input accepts free text (Phase 3); note entity CRUD functional (Phase 2)

## Resolved Decisions

1. **Dashboard**: "Today Overview" — greeting, circular habits %, urgent tasks, sleep indicator. No XP.
2. **Accent color**: Sage green `#8FBC8F` on dark `#121212`. Zen, organic, premium.
3. **Tasks**: `Energy` enum (low/medium/high) replaces difficulty. AI can match tasks to user energy state.
4. **Habit streaks**: `currentStreak` kept (behavioral psychology). UI refreshed — clean dots/lines, no fire/explosions.
5. **Schema**: Full migration in same PR — `DROP rpg_events`, `ALTER` profiles/habits/tasks, `CREATE notes`, ADD ai_* columns.
