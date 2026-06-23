# Tasks: Cleanup Overengineering

## [1] Delete dead Apple connector code
- [x] Delete `lib/data/services/apple_connector_service.dart`
- [x] Delete `lib/data/models/apple_event_model.dart`
- [x] Delete `lib/data/models/apple_reminder_model.dart`
- [x] Remove unused apple_connector import from `main.dart` (not present in main.dart)

## [2] Delete unused hero_stats_card widget
- [x] Delete `lib/presentation/common/hero_stats_card.dart`

## [3] Remove YAGNI repository interfaces (9 files)
- [x] Delete `lib/domain/repositories/i_auth_repository.dart`
- [x] Delete `lib/domain/repositories/i_finance_repository.dart`
- [x] Delete `lib/domain/repositories/i_goals_repository.dart`
- [x] Delete `lib/domain/repositories/i_habit_repository.dart`
- [x] Delete `lib/domain/repositories/i_obsidian_repository.dart`
- [x] Delete `lib/domain/repositories/i_profile_repository.dart`
- [x] Delete `lib/domain/repositories/i_rpg_events_repository.dart`
- [x] Delete `lib/domain/repositories/i_sleep_repository.dart`
- [x] Delete `lib/domain/repositories/i_task_repository.dart`
- [x] Update each concrete repository to remove `implements I{Name}Repository`
- [x] Remove interface imports from concrete repositories

## [4] Remove ObsidianRepository wrapper
- [x] Delete `lib/data/repositories/obsidian_repository.dart`
- [x] Update callers to use `ObsidianService` directly (no callers found)

## [5] Remove SupabaseService wrapper
- [x] Delete `lib/data/services/supabase_service.dart`
- [x] Update callers to use `Supabase.instance.client` directly

## [6] Fix API key leak
- [x] Remove `defaultValue` from `Secrets.groqApiKey` in `lib/core/config/secrets.dart`

## [7] Remove isDesktopWeb alias
- [x] Delete `isDesktopWeb` getter from responsive.dart
- [x] Replace all 7 usages of `isDesktopWeb` with `isWeb`

## [8] Inline _pad method
- [x] Remove `_pad` method from `obsidian_service.dart`
- [x] Replace its 3 usages with `.toString().padLeft(2, '0')` inline

## [9] Clean duplicate imports
- [x] Remove duplicate imports in `install_banner.dart`

## [10] Remove unused ProfileModel.createdAt
- [x] Remove `createdAt` field from `ProfileModel` and its `fromJson`

## [11] Extract _normalizeDate to shared utility
- [x] Create shared utility `lib/core/utils/date_utils.dart`
- [x] Update `habit_analytics.dart` and `sleep_analytics.dart` to use it

## [12] Replace equatable with manual override
- [x] Remove `Equatable` import from `sleep_log_entity.dart`
- [x] Add manual `==` operator and `hashCode` override
- [x] Remove `equatable` from pubspec.yaml dependencies

(End of file - total 65 lines)
