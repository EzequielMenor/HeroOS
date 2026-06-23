# Design: Cleanup Overengineering

## Approach
Pure deletions and mechanical inlines. No behavioral changes.

## Per-change design

### 1. Dead code deletion (Apple + hero_stats_card)
- Remove `lib/data/services/apple_connector_service.dart`
- Remove `lib/data/models/apple_event_model.dart`
- Remove `lib/data/models/apple_reminder_model.dart`
- Remove `lib/presentation/common/hero_stats_card.dart`
- No import cleanup needed (nothing imports them)

### 2. YAGNI interfaces (removal)
- Delete 9 interface files in `lib/domain/repositories/`:
  - `i_auth_repository.dart`, `i_finance_repository.dart`, `i_goals_repository.dart`,
    `i_habit_repository.dart`, `i_obsidian_repository.dart`, `i_profile_repository.dart`,
    `i_rpg_events_repository.dart`, `i_sleep_repository.dart`, `i_task_repository.dart`
- Update concrete repository imports in viewmodels/screens to remove the interface reference
  - Change `implements I{Name}Repository` → remove it
  - Remove import of the interface file
- Keep the concrete implementations as-is

### 3. YAGNI wrappers
- Delete `lib/data/repositories/obsidian_repository.dart`
  - Callers use `ObsidianService` directly (it's already imported)
- Delete `lib/data/services/supabase_service.dart`
  - Callers use `Supabase.instance.client` directly

### 4. API key leak fix
- In `lib/core/secrets.dart`, remove `defaultValue` from `groqApiKey` const
  - Change: throw a descriptive compile-time error if env var is not set
  - Or: leave without default so build fails if missing in CI

### 5. Trivial cleanups
- `isDesktopWeb` → delete getter, replace all 7 usages with `isWeb` in responsive_layout.dart and screens
- `_pad` → inline, delete method
- Duplicate imports in install_banner → remove
- `ProfileModel.createdAt` → remove field
- `_normalizeDate` → extract to shared utility
- `equatable` → replace with manual `==` and `hashCode` override in SleepLogEntity

## Risk
Low. Rollback by reverting the commit. File deletions are safe because nothing imports the removed files.
