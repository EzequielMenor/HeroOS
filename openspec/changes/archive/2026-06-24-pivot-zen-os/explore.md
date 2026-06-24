# Explore: pivot-zen-os

RPG → Minimalist AI personal management pivot analysis.

---

## Code Map

Legend: **DELETE** = remove entirely (RPG-only file) | **TRANSFORM** = remove RPG fields/refs, keep structure | **KEEP** = no change needed or trivial rename

### RPG Core (DELETE entirely)

| # | File | Contents | Action |
|---|------|----------|--------|
| 1 | `lib/domain/entities/rpg_event_entity.dart` | `RpgEventType` enum + `RpgEventEntity` with xpGain, xpLoss, hpLoss, levelUp, gameOver | DELETE |
| 2 | `lib/data/repositories/rpg_events_repository.dart` | Supabase CRUD for `rpg_events` table | DELETE |
| 3 | `lib/presentation/widgets/rpg_hud.dart` | 390-line HUD component: XP/HP bars, level badge, gold display, avatar | DELETE |
| 4 | `lib/presentation/viewmodels/stats_viewmodel.dart` | `StatsViewModel`: manages XP, HP, level ups, game over, damage, events | DELETE |

These 4 files contain 100% RPG mechanics — no salvageable business logic for Zen OS.

### Profile Entity — RPG Fields (TRANSFORM)

| # | File | RPG Points of Impact | Action |
|---|------|----------------------|--------|
| 5 | `lib/domain/entities/profile_entity.dart` | Fields: `level`, `currentXp`, `xpNextLevel`, `currentHp`, `maxHp`, `currentGold`. Methods: `gainXp()`, `loseXp()`, `takeDamage()`, `addGold()`, `xpProgress`, `hpProgress`, `isAlive`. 117 lines total. | TRANSFORM → slim to `username`, `avatarUrl`, keep `id`. Remove all RPG stats. Add `apiKey` field for Zen AI. |
| 6 | `lib/data/models/profile_model.dart` | Same RPG fields: `level`, `currentXp`, `xpNextLevel`, `currentHp`, `maxHp`, `currentGold`. Maps to Supabase `profiles` table. 54 lines. | TRANSFORM — mirror entity changes |
| 7 | `lib/data/repositories/profile_repository.dart` | Persists `level`, `current_xp`, `xp_next_level`, `current_hp`, `max_hp`, `current_gold` to Supabase. 58 lines. | TRANSFORM — remove RPG columns from update |

### Habit & Task Entities — RPG Fields (TRANSFORM)

| # | File | RPG Points of Impact | Action |
|---|------|----------------------|--------|
| 8 | `lib/domain/entities/habit_entity.dart` | `xpReward` (default 10), `dmgPenalty` (default 5) fields + copyWith | TRANSFORM — remove `xpReward`, `dmgPenalty`, `currentStreak` |
| 9 | `lib/data/models/habit_model.dart` | `xpReward`, `dmgPenalty` mapped to Supabase columns `xp_reward`, `dmg_penalty` | TRANSFORM — mirror entity |
| 10 | `lib/domain/entities/task_entity.dart` | `xpValue` getter (`difficulty * 10`), `difficulty` field (1-3) | TRANSFORM — remove `xpValue`, keep `difficulty` as priority or remove |
| 11 | `lib/data/models/task_model.dart` | `xpValue` field (from `xp_value` column), `difficulty` | TRANSFORM — remove `xpValue`, keep `difficulty` |

### ViewModels — RPG Integration (TRANSFORM)

| # | File | RPG Points of Impact | Action |
|---|------|----------------------|--------|
| 12 | `lib/presentation/viewmodels/habits_viewmodel.dart` | Imports `StatsViewModel`, calls `applyXpGain()`/`applyXpLoss()`, defaults `xpReward=10`, `dmgPenalty=5` in `createHabit()`. 168 lines. | TRANSFORM — remove RPG integration, remove StatsViewModel dependency |
| 13 | `lib/presentation/viewmodels/tasks_viewmodel.dart` | Imports `StatsViewModel`, calls `applyXpGain()`/`applyXpLoss()`. 130 lines. | TRANSFORM — remove RPG integration, remove StatsViewModel dependency |
| 14 | `lib/presentation/viewmodels/finance_viewmodel.dart` | Imports `StatsViewModel`, calls `loadProfile()` for gold sync. 207 lines. | TRANSFORM — remove StatsViewModel dependency, gold sync is RPG-only |
| 15 | `lib/presentation/viewmodels/sleep_viewmodel.dart` | Imports `StatsViewModel`, calls `applyXpGain(10)` for sleep quality reward. 116 lines. | TRANSFORM — remove RPG integration, remove StatsViewModel dependency |

### Screens — RPG Theming (TRANSFORM)

| # | File | RPG Points of Impact | Action |
|---|------|----------------------|--------|
| 16 | `lib/presentation/screens/dashboard_screen.dart` | Imports `rpg_hud.dart`, `StatsViewModel`. Shows XP/HP toasts, Level Up dialog, Game Over dialog, welcome hero dialog. References `AppColors.rpg` everywhere. 578 lines. | TRANSFORM — remove RPG HUD, dialogs, toasts. Keep tab navigation structure. |
| 17 | `lib/presentation/screens/profile_screen.dart` | `_HeroCard` widget showing level/XP/HP/gold. `_ActivityFeed` using `RpgEventEntity`. References `AppColors.rpg` throughout. 1009 lines. | TRANSFORM — remove hero card, activity feed. Keep settings + goals sections. |
| 18 | `lib/presentation/screens/habits_screen.dart` | Shows `'+${habit.xpReward} XP'` in habit tile subtitle. 1045 lines. | TRANSFORM — remove XP display from habit tiles |
| 19 | `lib/presentation/screens/tasks_screen.dart` | Shows `'+${task.xpValue} XP'` and difficulty labels. Uses "Misiones" terminology, "Pendientes" with ⚔️. 834 lines. | TRANSFORM — remove XP display, rename "Misiones" → "Tareas", remove RPG icons |
| 20 | `lib/presentation/screens/splash_screen.dart` | Uses `AppColors.rpg`, shows "Gamified Life Tracker" subtitle. 55 lines. | TRANSFORM — change subtitle, use new brand color |
| 21 | `lib/presentation/screens/login_screen.dart` | Uses `AppColors.rpg` for logo border, form focus, buttons. Shows "HeroOS" text. 383 lines. | TRANSFORM — rebrand to "Zen OS", use new accent color |

### Theme / Constants — RPG References (TRANSFORM)

| # | File | RPG Points of Impact | Action |
|---|------|----------------------|--------|
| 22 | `lib/core/theme/app_colors.dart` | `static const Color rpg = Color(0xFF9C27B0)` — purple XP color. 24 lines. | TRANSFORM — remove or rename. No direct replacement needed; pick new Zen accent. |
| 23 | `lib/core/constants/app_strings.dart` | `appName = 'HeroOS'`, `moduleTasks = 'Misiones'`. 18 lines. | TRANSFORM — rename to 'Zen OS', change 'Misiones' → 'Tareas' |
| 24 | `lib/core/theme/app_theme.dart` | Comment: "ThemeData centralizado de HeroOS". 52 lines. | TRANSFORM — update comment |
| 25 | `pubspec.yaml` | `description: 'HeroOS - Gamified Life Tracker (RPG-style)'` | TRANSFORM — update description |

### Dev Repository — RPG Events (TRANSFORM)

| # | File | RPG Points of Impact | Action |
|---|------|----------------------|--------|
| 26 | `lib/data/repositories/dev_repository.dart` | `_rpgEvents` list, `RpgEventEntity` import, `log()` RPG event, `getRecentEvents()`, `getProfile()` with RPG defaults (level=1, xp=0, hp=100, gold=0). 385 lines. | TRANSFORM — remove RPG events store. Slim profile defaults to username only. |

### Main Entry — RPG Wiring (TRANSFORM)

| # | File | RPG Points of Impact | Action |
|---|------|----------------------|--------|
| 27 | `lib/main.dart` | Imports `StatsViewModel`, creates `_statsVm` instance, passes to viewmodel constructors. References `HeroOSApp`. 129 lines. | TRANSFORM — remove StatsViewModel, remove RPG wiring from viewmodel constructors. Rename `HeroOSApp`. |

### Widgets — RPG Trivial References (TRANSFORM)

| # | File | RPG Points of Impact | Action |
|---|------|----------------------|--------|
| 28 | `lib/presentation/widgets/install_banner.dart` | References "HeroOS" text, `AppColors.rpg`. 114 lines. | TRANSFORM — rebrand text and color |

### KEEP (with potentially trivial comment updates)

| # | File | Notes |
|---|------|-------|
| 29 | `lib/domain/entities/transaction_entity.dart` | Finance core — KEEP |
| 30 | `lib/domain/entities/category_entity.dart` | Finance core — KEEP |
| 31 | `lib/domain/entities/account_entity.dart` | Finance core — KEEP |
| 32 | `lib/domain/entities/user_goals_entity.dart` | User goals — KEEP |
| 33 | `lib/domain/entities/sleep_log_entity.dart` | Sleep tracking — KEEP |
| 34 | `lib/domain/entities/habit_log_entity.dart` | Habit logs — KEEP |
| 35 | `lib/domain/entities/habit_analytics.dart` | Habit analytics — KEEP |
| 36 | `lib/domain/entities/sleep_analytics.dart` | Sleep analytics — KEEP |
| 37 | `lib/domain/services/sleep_diagnosis_service.dart` | Sleep diagnosis — KEEP |
| 38 | `lib/data/models/transaction_model.dart` | Finance — KEEP |
| 39 | `lib/data/models/category_model.dart` | Finance — KEEP |
| 40 | `lib/data/models/account_model.dart` | Finance — KEEP |
| 41 | `lib/data/models/user_goals_model.dart` | Goals — KEEP |
| 42 | `lib/data/models/sleep_log_model.dart` | Sleep — KEEP |
| 43 | `lib/data/models/habit_log_model.dart` | Habit logs — KEEP (no RPG fields) |
| 44 | `lib/data/repositories/finance_repository.dart` | Finance Supabase — KEEP |
| 45 | `lib/data/repositories/habit_repository.dart` | Habits Supabase — KEEP (will reference transformed model) |
| 46 | `lib/data/repositories/task_repository.dart` | Tasks Supabase — KEEP |
| 47 | `lib/data/repositories/sleep_repository.dart` | Sleep Supabase — KEEP |
| 48 | `lib/data/repositories/goals_repository.dart` | Goals Supabase — KEEP |
| 49 | `lib/presentation/viewmodels/auth_viewmodel.dart` | Auth — KEEP |
| 50 | `lib/presentation/viewmodels/goals_viewmodel.dart` | Goals — KEEP |
| 51 | `lib/presentation/screens/sleep_screen.dart` | Sleep — KEEP (no RPG refs) |
| 52 | `lib/presentation/screens/finance_screen.dart` | Finance — KEEP (no RPG refs) |
| 53 | `lib/presentation/screens/habits_screen.dart` | Habits screen — mostly KEEP, minor XP removal |
| 54 | `lib/presentation/widgets/habit_heatmap.dart` | Heatmap — KEEP |
| 55 | `lib/presentation/widgets/habit_stats_card.dart` | Stats card — KEEP |
| 56 | `lib/presentation/widgets/install_banner_stub.dart` | Stub — KEEP |
| 57 | `lib/presentation/widgets/install_banner_web.dart` | Web install — KEEP |
| 58 | `lib/core/config/secrets.dart` | Config — KEEP (comment update) |
| 59 | `lib/core/config/secrets.example.dart` | Config — KEEP |
| 60 | `lib/core/utils/adaptive_modal.dart` | Utility — KEEP |
| 61 | `lib/core/utils/auth_error_mapper.dart` | Utility — KEEP |
| 62 | `lib/core/utils/responsive.dart` | Utility — KEEP |
| 63 | `lib/core/utils/date_utils.dart` | Utility — KEEP |

---

## Impact Radius

The RPG deletion has a **star-like blast pattern** — `StatsViewModel` is at the center, consumed by 5 viewmodels and 2 screens:

```
StatsViewModel (DELETE)
  ├─ consumed by HabitsViewModel (TRANSFORM — remove dependency)
  ├─ consumed by TasksViewModel (TRANSFORM — remove dependency)
  ├─ consumed by FinanceViewModel (TRANSFORM — remove dependency)
  ├─ consumed by SleepViewModel (TRANSFORM — remove dependency)
  ├─ rendered in DashboardScreen (TRANSFORM — remove HUD/toasts/dialogs)
  └─ rendered in ProfileScreen (TRANSFORM — remove hero card/activity feed)
```

Secondary impact chain:
- `ProfileEntity` RPG fields → `ProfileModel` → `ProfileRepository` → `DevRepository` → all consumers
- `HabitEntity.xpReward` → `HabitModel` → `HabitsViewModel` → `HabitsScreen`
- `TaskEntity.xpValue` → `TaskModel` → `TasksViewModel` → `TasksScreen`
- `RpgEventEntity` → `RpgEventsRepository` → `StatsViewModel` (DELETE all)
- `RpgHud` widget → `DashboardScreen` (DELETE + remove import)

---

## Keepers

What survives the pivot:

### Core Business Logic (fully reusable)
- **Habits** — entity, model, repo, VM, screen, analytics — core Zen OS feature (habit tracking)
- **Tasks** — entity, model, repo, VM, screen — core Zen OS feature (task management)
- **Sleep** — entity, model, repo, VM, screen, analytics, diagnosis service — core Zen OS feature
- **Finance** — entity, model, repo, VM, screen — expense tracking is Zen OS
- **Goals** — entity, model, repo, VM, screen — user goals are Zen OS
- **Auth** — viewmodel, repository — auth stays, no changes needed

### Architecture Patterns (keep the structure)
- Clean architecture layers (`core/`, `data/`, `domain/`, `presentation/`)
- Repository pattern with DevRepository/Supabase switch
- Provider-based state management
- GoRouter navigation
- Theme system (just remove RPG color)

### What Needs a New Home
- The `profile` entity → becomes Zen OS **user config** (username, avatar, API key for AI)
- The `DevRepository` → stays as dev mode, just remove RPG events from it
- The `install_banner` → stays, but rebrand to "Zen OS"

---

## Open Questions

1. **What replaces the RPG "home" screen?** Dashboard currently shows the HUD + 5 tabs. Without RPG stats, do we put a "Today's overview" summary card (habits progress, tasks due, sleep quality)? Or keep the current tab layout and just remove the HUD?

2. **What is the "Profile" screen strategy?** Currently shows hero card + goals + activity feed. Without RPG stats, does it become a settings/config screen (API key input, display name, prefrences) only? Or should goals move here permanently?

3. **What is the Zen OS accent color?** RPG used purple (`#9C27B0`). Need a new primary/module accent for the brand. Options: a calm blue, a green, or keep dark theme with a different accent. The current `AppColors.rpg` is referenced in ~15 files as button/focus/indicator color — needs a universal replacement.

4. **Difficulty system in tasks — keep or remove?** `TaskEntity.difficulty` (1-3) maps to XP values. Without RPG, difficulty is just metadata. Does Zen OS want priority-based tasks (High/Med/Low) instead of difficulty? Or remove it entirely and keep tasks as simple todo items?

5. **Habit streaks — RPG or behavior tracking?** `habit.currentStreak` is arguably behavior psychology, not RPG. Keep it as motivational metric? Or remove since it was originally tied to XP reward display?

6. **Supabase schema migration strategy?** The `profiles` table has RPG columns (`level`, `current_xp`, `xp_next_level`, `current_hp`, `max_hp`, `current_gold`). The `habits` table has `xp_reward`, `dmg_penalty`. The `tasks` table has `xp_value`. The `rpg_events` table exists. Need a migration plan — drop columns? Drop tables? Existing user data?

---

## Effort Estimate

### File Count Summary
| Action | Count | Notes |
|--------|-------|-------|
| **DELETE** | 4 | Entire files, no salvage |
| **TRANSFORM (heavy)** | ~12 | Entity+model+repo+VM changes, RPG removal |
| **TRANSFORM (trivial)** | ~12 | Color swaps, string renames, comment updates |
| **KEEP** | ~27 | No changes needed |
| **Total** | ~55 | All `.dart` files in `lib/` |

### Effort: 2-3 sessions

**Session 1 — Core removal (~45 min)**
- Delete 4 RPG files: `rpg_event_entity.dart`, `rpg_events_repository.dart`, `rpg_hud.dart`, `stats_viewmodel.dart`
- Transform `profile_entity.dart` + `profile_model.dart` + `profile_repository.dart` (remove RPG fields)
- Transform `habit_entity.dart` + `habit_model.dart` (remove xpReward, dmgPenalty)
- Transform `task_entity.dart` + `task_model.dart` (remove xpValue)

**Session 2 — ViewModel wiring & screens (~60 min)**
- Detach StatsViewModel from HabitsViewModel, TasksViewModel, FinanceViewModel, SleepViewModel
- Transform DashboardScreen (remove HUD, dialogs, toasts)
- Transform ProfileScreen (remove hero card, activity feed)
- Transform HabitsScreen + TasksScreen (remove XP display)

**Session 3 — Rebrand & polish (~30 min)**
- Rename strings (HeroOS → Zen OS)
- Replace AppColors.rpg refs with new accent
- Update splash/login screens
- Update pubspec description
- Run `flutter analyze` and fix issues

### Risk Level: **Medium**
- The `StatsViewModel` dependency is injected into 5 viewmodels and the main.dart. Removing it requires detaching all 5 consumers cleanly.
- High confidence on DELETE files (no regressions since nothing else depends on them except their consumers).
- Profile entity RPG fields are referenced across data layer — need coordinated removal.
- `AppColors.rpg` is scattered across ~15 files — grep-and-replace but need a replacement color.
- No test suite, so all verification is via `flutter analyze`.

---

## Ready for Proposal
**Yes** — code map is clear, blast radius is well-understood. Questions above should go into the proposal's question round before design starts.
