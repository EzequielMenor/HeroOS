# Delta for Supabase Schema

## REMOVED Requirements

### Requirement: RPG Events Table

(Previously: `rpg_events` table stored XP gains, damage taken, gold earned, and level-ups with timestamps.)

(Reason: Entire RPG subsystem removed. No events to log.)
(Migration: `DROP TABLE rpg_events;` — data is non-recoverable after migration. Ensure migration runs after backup if needed.)

## MODIFIED Requirements

### Requirement: Profiles Table — RPG Columns Removed

(Previously: `profiles` table held `level`, `currentXp`, `xpNextLevel`, `currentHp`, `maxHp`, `currentGold`, `isAlive`.)

(Reason: RPG stats no longer stored. Profile now stores identity and AI config only.)

#### Scenario: Migration preserves user identity

- GIVEN a running database with existing profiles
- WHEN the migration runs
- THEN RPG columns are dropped
- AND `id`, `username`, `avatarUrl` columns remain intact with their data

### Requirement: Habits Table — XP Columns Removed

(Previously: `habits` table had `xpReward`, `dmgPenalty`, `xpValue` columns.)

(Reason: Habits no longer produce XP rewards or damage penalties.)

#### Scenario: Habit migration preserves streaks

- GIVEN existing habits with active streaks
- WHEN migration drops `xpReward`, `dmgPenalty`, `xpValue` columns
- THEN `currentStreak`, `title`, `frequencyMask`, `userId` columns are unaffected

### Requirement: Tasks Table — Difficulty/XP Removed, Energy Added

(Previously: `tasks` had `difficulty` (int 1-3) and `xpValue` (computed).)

#### Scenario: Task migration adds energy column

- GIVEN the migration runs
- WHEN `difficulty` column is dropped and `xpValue` is dropped
- THEN `energy` column (TEXT, nullable) is added
- AND existing task rows get `energy = NULL` (no default mapping from old difficulty)

### Requirement: Profiles Table — AI Columns Added

The `profiles` table MUST accept two new nullable TEXT columns for AI configuration.

#### Scenario: Migration adds AI columns

- GIVEN the migration runs
- WHEN `ALTER TABLE profiles` executes
- THEN `aiApiKey` (TEXT, nullable) and `aiProvider` (TEXT, nullable) columns are added
- AND existing profile rows default to NULL for both

## ADDED Requirements

### Requirement: Notes Table

The system MUST create a new `notes` table for the Second Brain module.

#### Scenario: Notes table created

- GIVEN the migration runs
- WHEN `CREATE TABLE notes` executes
- THEN table has columns: `id` (UUID PK), `title` (TEXT), `content` (TEXT), `date` (TIMESTAMPTZ), `tags` (TEXT[]), `profile_id` (UUID FK → profiles.id)
- AND RLS policies allow CRUD only for the owning profile

#### Scenario: Notes table on fresh install

- GIVEN a brand-new database with no prior schema
- WHEN app starts for the first time
- THEN `notes` table exists and accepts inserts immediately
