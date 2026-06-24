# Tasks: Pivot to Zen OS

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~1500–2000 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | DB+Entities → UI Cleanup → Notes+AI |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: pending
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Migration + entity/model changes | PR 1 | DB schema, 4 file deletions, Profile/Habit/Task transforms (base: main) |
| 2 | UI rebrand + StatsVM removal | PR 2 | AppColors rename, StatsVM detach, dashboard update (base: main) |
| 3 | Notes module + AI core | PR 3 | Note CRUD, AIService, QuickCapture (base: PR 2 or main) |

## Phase 1: Database Migration

- [x] 1.1 Write `supabase/migrations/001_zen_os_pivot.sql`: DROP rpg_events, ALTER profiles/habits/tasks, CREATE notes
- [x] 1.2 Write `supabase/migrations/rollback.sql` with inverse DDL
- [x] 1.3 Apply on Supabase branch, verify RLS + idempotency

## Phase 2: Delete RPG Files

- [x] 2.1 Delete `lib/domain/entities/rpg_event_entity.dart`
- [x] 2.2 Delete `lib/data/repositories/rpg_events_repository.dart`
- [x] 2.3 Delete `lib/presentation/widgets/rpg_hud.dart`
- [x] 2.4 Delete `lib/presentation/viewmodels/stats_viewmodel.dart`
- [x] 2.5 Remove all dangling imports across codebase
- [x] 2.6 Run `flutter analyze` — confirm zero errors

## Phase 3: Transform Profile

- [x] 3.1 Edit `profile_entity.dart`: drop 7 RPG fields + 5 methods; add `aiApiKey`, `aiProvider`
- [x] 3.2 Edit `profile_model.dart`: mirror field changes in `toMap`/`fromMap`
- [x] 3.3 Edit `profile_repository.dart`: remove RPG column mapping
- [x] 3.4 Edit `profile_screen.dart`: replace RPG stats with API key input + provider dropdown
- [x] 3.5 Store API key in `shared_preferences` (base64 encode), NOT Supabase

## Phase 4: Transform Habit + Task

- [x] 4.1 Edit `habit_entity.dart` + `habit_model.dart`: drop `xpReward`, `dmgPenalty`, `xpValue`
- [x] 4.2 Edit `task_entity.dart`: drop `xpValue`, `difficulty`; add `Energy` enum (low/medium/high)
- [x] 4.3 Edit `task_model.dart`: map `energy` to TEXT column
- [x] 4.4 Replace all `task.difficulty` usage with `task.energy`

## Phase 5: AppColors Bulk Replace

- [x] 5.1 Rename `AppColors.rpg` → `AppColors.sageGreen` (#8FBC8F) in `app_colors.dart`
- [x] 5.2 Bulk replace `AppColors.rpg` → `AppColors.sageGreen` across all 67 sites
- [x] 5.3 Run `flutter analyze` — confirm zero unresolved references

## Phase 6: Detach StatsViewModel

- [x] 6.1 Audit all 6 StatsViewModel consumers (habits/tasks/finance/sleep VMs, dashboard, main)
- [x] 6.2 Remove `_statsVm` from each consumer; replace with direct repo reads
- [x] 6.3 Remove StatsViewModel from Provider tree in `main.dart`
- [x] 6.4 Run `flutter analyze` — confirm clean

## Phase 7: Notes Module

- [x] 7.1 Create `note_entity.dart`: id, title, content, date, tags
- [x] 7.2 Create `note_model.dart` + `note_repository.dart`: CRUD + tag filter + ilike search
- [x] 7.3 Create `notes_viewmodel.dart`: Provider exposing list/search/tags
- [x] 7.4 Create `notes_screen.dart`: list + editor + tag filter
- [x] 7.5 Add notes route to GoRouter

## Phase 8: AI Core

- [x] 8.1 Create `ai_service.dart`: `classify(text)` with embedded system prompt + JSON parse + try/catch
- [x] 8.2 Create `quick_capture_viewmodel.dart`: routes classified text to correct repo by type
- [x] 8.3 Create `quick_capture_input.dart`: TextField with submit handler
- [x] 8.4 Integrate Quick Capture into dashboard

## Phase 9: Final Verify

- [x] 9.1 Run `flutter pub get`
- [x] 9.2 Run `flutter analyze` — zero errors, zero warnings
- [x] 9.3 Run `flutter build apk` or iOS simulator — confirm build succeeds
- [x] 9.4 Manual smoke: Quick Capture 4 inputs, note CRUD
