# Delta for Profile Entity

## REMOVED Requirements

### Requirement: RPG Stats Fields

(Previously: ProfileEntity carried `level`, `currentXp`, `xpNextLevel`, `currentHp`, `maxHp`, `currentGold`, `isAlive`.)

(Reason: RPG gamification layer removed — Zen OS uses behavioral psychology, not numeric rewards.)
(Migration: All consumers of these fields (StatsViewModel, RPG HUD, level-up animations) are deleted or updated. Profile screen shows AI config instead.)

### Requirement: RPG Business Logic Methods

(Previously: `gainXp()`, `loseXp()`, `takeDamage()`, `addGold()`, `xpProgress`, `hpProgress`.)

(Reason: No XP or HP system remains. Level-up and damage logic has no domain purpose.)
(Migration: Callers that triggered `gainXp()` on habit/task completion are updated to remove those calls.)

## ADDED Requirements

### Requirement: AI API Key Field

The system MUST store a user-provided AI API key locally, NOT in Supabase.

#### Scenario: API key saved locally

- GIVEN user opens Profile/Settings screen
- WHEN user enters an API key and taps save
- THEN the key is stored in `shared_preferences` on-device
- AND the key input field displays as masked text (••••••••)

#### Scenario: No API key configured

- GIVEN user has never saved an API key
- WHEN any AI-powered feature is invoked
- THEN the system shows "Configure API key" prompt
- AND navigation to Settings is offered

### Requirement: AI Provider Selection

The system MUST allow users to select their AI provider from a dropdown.

#### Scenario: Provider selection

- GIVEN user opens Profile/Settings screen
- WHEN user selects "Gemini" from provider dropdown
- THEN `aiProvider` field is set to `"gemini"`
- AND subsequent AI calls use the Gemini API endpoint

#### Scenario: Default provider

- GIVEN no provider has been selected
- WHEN AI classification is invoked
- THEN the system defaults to `"openai"` or prompts selection
