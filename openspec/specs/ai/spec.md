# AI Classification Specification

## Purpose

Accept free-form text input from the user, send it to an AI model via the user's own API key, and return a structured classification that routes the input to the correct repository (expense, task, habit, or note).

## Requirements

### Requirement: Text Classification

The system MUST send user text to the configured AI provider and return a JSON classification.

#### Scenario: Expense classification

- GIVEN user types "compré panell 12 euros"
- WHEN AIService processes the text
- THEN response includes { "type": "GASTO", "amount": 12.0, "description": "panell" }

#### Scenario: Task classification

- GIVEN user types "llamar a mamá mañana"
- WHEN AIService processes the text
- THEN response includes { "type": "TAREA", "title": "Llamar a mamá", "energy": "low" }

#### Scenario: Habit classification

- GIVEN user types "meditar 10 min todos los días"
- WHEN AIService processes the text
- THEN response includes { "type": "HABITO", "title": "Meditar", "frequency": "daily" }

#### Scenario: Note classification

- GIVEN user types "nota: idea para app de recetas"
- WHEN AIService processes the text
- THEN response includes { "type": "NOTA", "title": "Idea para app de recetas" }

### Requirement: Confidence Threshold

The system MUST include a confidence score (0.0–1.0) in every classification response.

#### Scenario: High confidence — auto-save

- GIVEN AI returns confidence ≥ 0.7
- WHEN classification result is received
- THEN the item is saved automatically to the correct repository
- AND a brief success toast is shown

#### Scenario: Low confidence — confirmation dialog

- GIVEN AI returns confidence < 0.6
- WHEN classification result is received
- THEN a "Did you mean...?" confirmation dialog is shown
- AND user must confirm before the item is saved

### Requirement: Missing API Key

The system MUST handle the case where no API key is configured.

#### Scenario: No API key configured

- GIVEN user has not saved an API key
- WHEN Quick Capture or AI classification is invoked
- THEN the system shows "Configure API key in Settings"
- AND no network call is attempted

### Requirement: Quick Capture Integration

The system SHALL provide a single text input that accepts free-form text and triggers AI classification.

#### Scenario: Quick Capture flow

- GIVEN user is on the dashboard
- WHEN user taps the Quick Capture input
- AND types "gasté 25 en taxi"
- THEN text is sent to AIService
- AND the result auto-saves as an expense (assuming confidence ≥ 0.7)
- AND a toast confirms "Expense saved: taxi — $25.00"
