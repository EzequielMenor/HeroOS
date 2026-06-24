# Dashboard Today Overview Specification

## Purpose

Replace the RPG-heavy dashboard HUD with a calm "Today Overview" screen focused on the user's real data: greeting, habit completion %, urgent tasks, and sleep quality.

## Requirements

### Requirement: Time-Based Greeting

The system MUST display a greeting that varies by time of day.

#### Scenario: Morning greeting

- GIVEN the current time is between 5:00 and 11:59
- WHEN the user opens the app
- THEN greeting shows "Good morning, {username}"

#### Scenario: Afternoon greeting

- GIVEN the current time is between 12:00 and 17:59
- WHEN the user opens the app
- THEN greeting shows "Good afternoon, {username}"

#### Scenario: Evening greeting

- GIVEN the current time is between 18:00 and 4:59
- WHEN the user opens the app
- THEN greeting shows "Good evening, {username}"

### Requirement: Habit Completion Circle

The system MUST display today's habit completion as a percentage in a circular widget using sage green (#8FBC8F).

#### Scenario: Partial completion

- GIVEN user has 5 active habits for today
- AND 3 of them are marked as done
- WHEN user views the dashboard
- THEN a circle widget shows "60%" filled in sage green

#### Scenario: All habits completed

- GIVEN user has completed all habits for today
- WHEN user views the dashboard
- THEN the circle is fully filled (100%) with a subtle checkmark

#### Scenario: No habits tracked

- GIVEN user has no habits configured
- WHEN user views the dashboard
- THEN empty state shows "Add your first habit to get started"
- AND the circle shows 0%

### Requirement: Urgent Tasks Section

The system MUST show the top 3 pending tasks sorted by proximity to due date, each with its energy indicator.

#### Scenario: Tasks pending

- GIVEN user has 5 tasks, 2 overdue and 3 due later
- WHEN dashboard renders
- THEN top 3 most urgent tasks are displayed
- AND each task shows its energy level (low/medium/high)

#### Scenario: No tasks

- GIVEN user has zero pending tasks
- WHEN dashboard renders
- THEN tasks section shows "No tasks — enjoy your day"

### Requirement: Sleep Quality Indicator

The system MUST display last night's sleep quality if logged.

#### Scenario: Sleep logged

- GIVEN user logged sleep last night with quality "good"
- WHEN dashboard renders
- THEN a small moon icon appears with a "good" label
- AND color is sage green

#### Scenario: Sleep not logged

- GIVEN user has not logged sleep today or last night
- WHEN dashboard renders
- THEN sleep indicator shows "Log your sleep" prompt or is hidden entirely
