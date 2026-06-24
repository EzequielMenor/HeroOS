# Delta for Habit Entity

## REMOVED Requirements

### Requirement: XP and Damage Fields

(Previously: `xpReward` (int, default 10) and `dmgPenalty` (int, default 5) awarded XP or dealt HP damage on habit completion/miss.)

(Reason: RPG system removed. Habit tracking is behavioral, not gamified.)
(Migration: Habit creation forms drop `xpReward`/`dmgPenalty` inputs. Habit completion callbacks no longer call `profile.gainXp()` or `profile.takeDamage()`.)

## MODIFIED Requirements

### Requirement: Streak Tracking

The system MUST continue tracking `currentStreak` — the number of consecutive days a habit has been completed — but with no RPG visual effects.

(Previously: streak triggered fire animations and XP bonuses on milestone completions.)

#### Scenario: Streak increments on completion

- GIVEN user has a habit with currentStreak = 3
- WHEN user marks habit as done today
- THEN currentStreak becomes 4
- AND streak UI updates with clean dot/label indicator (no fire animation)

#### Scenario: Streak resets on missed day

- GIVEN user has a habit with currentStreak = 5
- WHEN 24 hours pass without the habit being completed on a scheduled day
- THEN currentStreak resets to 0
- AND streak UI shows empty dots

#### Scenario: New habit with no streak

- GIVEN user creates a brand-new habit
- WHEN user views that habit in the list
- THEN UI shows "Start your streak" message
- AND streak indicator shows 0 dots filled
