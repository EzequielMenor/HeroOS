# Design: Pivot to Zen OS

## Technical Approach

Strip RPG subsystem (entities, repos, viewmodel, HUD), recolor to sage green, swap `difficulty` for `energy`, add notes + AI classification pipeline. Three ordered phases that match the proposal: Deep Clean → Data/Domain → AI Core. Migration runs as the very first step so Flutter code can assume new schema while in flight.

## Architecture Decisions

| Decision | Choice | Alternative | Rationale |
|----------|--------|-------------|-----------|
| System prompt location | Embedded as `const` in `lib/domain/services/ai_service.dart` | Store in Supabase config table | One file, version-controlled, no extra round-trip; user API keys never leave device. |
| API key storage | `shared_preferences` with base64 obfuscation | `flutter_secure_storage` or Supabase userdata | Avoid new native dep (Keychain/Keystore requires platform wiring); shared_preferences already in tree; spec says NOT in Supabase. |
| Energy field type | Dart `enum Energy { low, medium, high }` + `Energy?` on entity | `String` with constants | Type-safe in `TaskEntity`, serializes to TEXT in Supabase via toString. |
| StatsViewModel removal | Delete + inline 4 repo calls | Keep stub VM returning 0s | Spec deletes the file; 6 consumers get audited. No ghost VM. |
| AppColors accent rename | Replace literal `AppColors.rpg` → `AppColors.sageGreen` (keep `AppColors.finance/habits/sleep/danger` intact) | Add `AppColors.sageGreen` as alias, deprecate `rpg` | Aliases hide the rebrand; literal replace surfaces every remaining RPG reference to `flutter analyze`. |
| `xpNextLevel`/`maxHp` etc on ProfileModel | Drop from entity + model + migration | Keep nullable for back-compat | Schema migration drops them; ProfileModel mapper updates; if any read site is missed, `flutter analyze` flags it. |
| NoteRepository ownership | New `lib/data/repositories/note_repository.dart` mirroring existing repo shape | Add notes to ProfileRepository | Single responsibility; mirrors habit/task/finance repos. |

## Data Flow

```
[Quick Capture Input] (Dashboard)
    │  free text
    ▼
[QuickCaptureViewModel]
    │  text, apiKey (shared_prefs), provider
    ▼
[AIService.classify(text)]
    │  POST → OpenAI/Gemini with embedded system prompt
    ▼  JSON: {type, confidence, fields}
[Route by type]
    │  GASTO → FinanceRepository.addTransaction()
    │  TAREA → TaskRepository.add()
    │  HABITO → HabitRepository.add()
    │  NOTA  → NoteRepository.add()
    ▼
[Toast / ConfirmDialog] (confidence ≥0.7 auto-save, <0.6 confirm, 0.6-0.7 silent)
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/domain/entities/rpg_event_entity.dart` | **Delete** | RPG layer removed. |
| `lib/data/repositories/rpg_events_repository.dart` | **Delete** | Used only by stats VM. |
| `lib/presentation/widgets/rpg_hud.dart` | **Delete** | Replaced by dashboard widgets. |
| `lib/presentation/viewmodels/stats_viewmodel.dart` | **Delete** | Last consumer is profile screen; refactor to read ProfileEntity directly. |
| `lib/domain/entities/profile_entity.dart` | Modify | Drop `level/currentXp/xpNextLevel/currentHp/maxHp/currentGold/isAlive`, drop `gainXp/loseXp/takeDamage/addGold/xpProgress/hpProgress`; add `aiApiKey`, `aiProvider`. |
| `lib/data/models/profile_model.dart` | Modify | Same field changes + `toMap`/`fromMap`. |
| `lib/data/repositories/profile_repository.dart` | Modify | Map `aiApiKey`/`aiProvider` columns. |
| `lib/domain/entities/habit_entity.dart` | Modify | Drop `xpReward`, `dmgPenalty`, `xpValue`. Keep `currentStreak`. |
| `lib/data/models/habit_model.dart` | Modify | Drop the 3 columns from `toMap`/`fromMap`. |
| `lib/domain/entities/task_entity.dart` | Modify | Drop `xpValue`, `difficulty`; add `Energy? energy`. |
| `lib/data/models/task_model.dart` | Modify | Map `energy` to TEXT. |
| `lib/core/theme/app_colors.dart` | Modify | Replace `rpg = 0xFF9C27B0` with `sageGreen = 0xFF8FBC8F`. |
| **All screens** with `AppColors.rpg` (67 sites) | Modify | Bulk find-replace `AppColors.rpg` → `AppColors.sageGreen`. Affected: dashboard, profile, tasks, habits, login, splash. |
| `lib/presentation/viewmodels/habits_viewmodel.dart` | Modify | Remove `_statsVm`, drop `gainXp`/`takeDamage` calls. |
| `lib/presentation/viewmodels/tasks_viewmodel.dart` | Modify | Remove `_statsVm`, drop XP rewards. |
| `lib/presentation/viewmodels/finance_viewmodel.dart` | Modify | Remove `_statsVm`, drop gold sync. |
| `lib/presentation/viewmodels/sleep_viewmodel.dart` | Modify | Remove `_statsVm` if present. |
| `lib/presentation/screens/dashboard_screen.dart` | Modify | Remove HUD import, replace with Today Overview (greeting + habit circle + urgent tasks + sleep). Add Quick Capture input. |
| `lib/presentation/screens/profile_screen.dart` | Modify | Remove stats card, add AI config section (provider dropdown + masked key field). |
| `lib/main.dart` | Modify | Remove `StatsViewModel` provider wiring. |
| `lib/presentation/widgets/habit_heatmap.dart`, `habit_stats_card.dart` | Modify | Strip XP/level labels from card chrome. |
| `lib/data/repositories/dev_repository.dart` | Modify | Remove rpg_event seed. |
| `lib/core/constants/app_strings.dart` | Modify | Strip HeroOS RPG copy. |
| `lib/domain/entities/note_entity.dart` | **Create** | `id`, `title`, `content`, `date`, `tags` (List<String>). |
| `lib/data/models/note_model.dart` | **Create** | `toMap`/`fromMap` for `notes` table. |
| `lib/data/repositories/note_repository.dart` | **Create** | CRUD + tag filter + full-text search via Supabase `.ilike()`. |
| `lib/presentation/viewmodels/notes_viewmodel.dart` | **Create** | Provider exposing list/search/tags. |
| `lib/presentation/screens/notes_screen.dart` | **Create** | List + editor + tag filter. |
| `lib/domain/services/ai_service.dart` | **Create** | `AIService.classify(text)` → `Future<AiClassification>`. Embeds system prompt. |
| `lib/presentation/viewmodels/quick_capture_viewmodel.dart` | **Create** | Glues AIService → repositories; handles confidence routing. |
| `lib/presentation/widgets/quick_capture_input.dart` | **Create** | TextField on dashboard with submit handler. |
| `supabase/migrations/001_zen_os_pivot.sql` | **Create** | DROP/ALTER/CREATE statements (see below). |

## SQL Migration (`supabase/migrations/001_zen_os_pivot.sql`)

```sql
-- 1. Drop RPG artifacts
DROP TABLE IF EXISTS rpg_events CASCADE;

-- 2. Profiles: drop RPG, add AI config
ALTER TABLE profiles
  DROP COLUMN IF EXISTS level,
  DROP COLUMN IF EXISTS current_xp,
  DROP COLUMN IF EXISTS xp_next_level,
  DROP COLUMN IF EXISTS current_hp,
  DROP COLUMN IF EXISTS max_hp,
  DROP COLUMN IF EXISTS current_gold,
  DROP COLUMN IF EXISTS is_alive,
  ADD COLUMN IF NOT EXISTS ai_api_key TEXT,
  ADD COLUMN IF NOT EXISTS ai_provider TEXT DEFAULT 'openai';

-- 3. Habits: drop XP
ALTER TABLE habits
  DROP COLUMN IF EXISTS xp_reward,
  DROP COLUMN IF EXISTS dmg_penalty,
  DROP COLUMN IF EXISTS xp_value;

-- 4. Tasks: drop difficulty/xp, add energy
ALTER TABLE tasks
  DROP COLUMN IF EXISTS difficulty,
  DROP COLUMN IF EXISTS xp_value,
  ADD COLUMN IF NOT EXISTS energy TEXT;

-- 5. Notes table
CREATE TABLE notes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  content     TEXT NOT NULL DEFAULT '',
  date        TIMESTAMPTZ NOT NULL DEFAULT now(),
  tags        TEXT[] NOT NULL DEFAULT '{}'
);
CREATE INDEX notes_profile_idx ON notes(profile_id);
CREATE INDEX notes_tags_idx    ON notes USING GIN(tags);

ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notes_owner_all" ON notes
  USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());
```

## AIService Contract

```dart
class AiClassification {
  final String type;          // 'GASTO'|'TAREA'|'HABITO'|'NOTA'
  final double confidence;    // 0.0..1.0
  final String? title;
  final double? amount;
  final String? description;
  final Energy? energy;
  final String? content;
  final String? frequency;
  final List<String>? tags;
}

class AIService {
  const AIService(this._http, this._prefs);  // injected, testable
  Future<AiClassification> classify(String text);
}
```

System prompt embedded as `const _systemPrompt` in same file. Provider switch reads `aiProvider` from prefs; defaults to `'openai'`. JSON parse wrapped in `try/catch` → returns `confidence: 0.0` so caller falls back to confirmation dialog.

## Testing Strategy

| Layer | Coverage | Approach |
|-------|----------|----------|
| Static | Compile correctness after each phase | `flutter analyze` zero-error gate per phase. |
| Manual smoke | Dashboard render, Quick Capture classify on 4 sample inputs, note CRUD | Run dev build, exercise. |
| SQL | Migration idempotent + RLS correct | Apply on local Supabase branch + staging; verify RLS blocks cross-profile read. |

No unit tests in this change (matches `config.yaml: tdd: false`).

## Risks

| Change | Risk | Mitigation |
|--------|------|-----------|
| StatsViewModel deletion | **MEDIUM** — 6 consumers (habits/tasks/finance/sleep VMs + dashboard + profile + main) | Phase-order removal: delete VM last, audit `_statsVm` injection sites before delete; replace `gainXp` callers with no-op or remove. |
| AppColors bulk rename (67 sites) | **LOW** | Literal sed `AppColors.rpg` → `AppColors.sageGreen`; `flutter analyze` flags any leftover reference. |
| Supabase migration | **HIGH** — alters production schema; data loss for RPG stats (acceptable per spec) | Apply on Supabase branch first; ship `rollback.sql` (re-ADD columns + DROP notes) per proposal; run on staging before prod. |
| AIService JSON parsing | **MEDIUM** — AI may return malformed JSON or non-JSON | `try { jsonDecode } catch → return confidence 0.0`; QuickCaptureViewModel routes low confidence to confirm dialog. |
| NoteRepository full-text search | **LOW** | Use Postgres `ilike` on title+content for v1; add FTS5/`tsvector` index later if needed. |
| Energy enum ↔ TEXT mapping | **LOW** | Store `energy.name` ('low'/'medium'/'high'); reject null in mapper to keep type safe. |

## Migration / Rollout

Single PR, single deploy. Order enforced by phases below — each phase compiles and analyzes clean before moving on.

```markdown
1. supabase/migrations/001_zen_os_pivot.sql + rollback.sql   ← DB first
2. Delete 4 RPG files; fix import chains                      ← compile break surfaces consumers
3. Transform ProfileEntity/Model/Repository                  ← profile surfaces old VM deps
4. Transform HabitEntity, TaskEntity (+Energy enum)           ← VMs stop calling gainXp
5. AppColors.rpg → AppColors.sageGreen bulk replace          ← branding
6. Delete StatsViewModel; refactor 4 VMs + dashboard + profile ← HUD gone
7. Add NoteEntity + NoteRepository + NotesScreen + ViewModel  ← new feature
8. Add AIService + QuickCaptureViewModel + QuickCaptureInput ← AI core
9. flutter pub get && flutter analyze                          ← final gate
```

## Open Questions

- None blocking. Provider dropdown default (`'openai'` per spec; Gemini also supported) is documented in `ProfileEntity.aiProvider` default value.