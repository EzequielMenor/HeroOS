# Cleanup Overengineering

## Intent
Remove ~679 lines of dead code, speculative abstractions, and unnecessary wrappers from the HeroOS codebase. Fix one critical API key leak.

## Scope
- Delete AppleConnectorService and related models (dead code)
- Delete hero_stats_card.dart (unused widget)
- Remove 9 repository interfaces with single implementations (YAGNI)
- Remove ObsidianRepository (wrapper that only delegates)
- Remove SupabaseService (wrapper that only delegates)
- Fix API key leak in Secrets.groqApiKey
- Inline _pad utility method
- Remove isDesktopWeb alias (duplicate of isWeb)
- Remove unused ProfileModel.createdAt field
- Deduplicate _normalizeDate utility
- Remove equatable dependency from SleepLogEntity
- Clean duplicate imports in install_banner.dart

## Non-goals
- No architecture refactors (ViewModels, Entity/Model consolidation)
- No new features or dependencies
- No behavior changes

## Risk
Low. All changes are deletions or trivial inlines. Rollback by reverting commits.
