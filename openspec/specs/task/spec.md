# Delta for Task Entity

## REMOVED Requirements

### Requirement: Difficulty Field

(Previously: `difficulty` (int 1-3) controlled `xpValue = difficulty × 10`. Used for visual badges and XP rewards.)

(Reason: XP system removed. Difficulty is a gamified proxy; energy better reflects user context.)
(Migration: All references to `task.difficulty` and `task.xpValue` are replaced with `task.energy`. Forms, list UIs, and sorting logic updated.)

## ADDED Requirements

### Requirement: Energy Field

The system MUST provide an `energy` enum field (low / medium / high) representing the energy required to complete a task.

#### Scenario: Default energy on task creation

- GIVEN user opens the task creation form
- WHEN form is rendered with no prior selection
- THEN energy dropdown defaults to "medium"

#### Scenario: AI suggests task based on energy

- GIVEN user types "llamar a mamá" into Quick Capture
- WHEN AI classifies it as a TASK with energy=low
- THEN the created TaskEntity has `energy` set to `low`

#### Scenario: Task list sorted by energy

- GIVEN user views the task list
- WHEN filter/sort option for energy is active
- THEN tasks are grouped or sorted by energy level (low → high or high → low)

#### Scenario: Energy visual indicator

- GIVEN a task with energy = "high"
- WHEN displayed in the task list
- THEN task card shows an energy indicator (icon or label, not numeric)
