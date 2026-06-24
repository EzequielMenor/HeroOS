# Note Entity Specification

## Purpose

Provide a new "Second Brain" module: a free-form notes system with CRUD, full-text search, and tagging. Notes are independent of tasks, habits, and expenses — they are personal reference material.

## Requirements

### Requirement: Note CRUD

The system MUST support creating, reading, updating, and deleting notes.

#### Scenario: Save a note

- GIVEN user opens the Notes screen
- WHEN user writes a title and content, then taps save
- THEN the note is persisted to Supabase `notes` table
- AND appears in the notes list sorted by most recent first

#### Scenario: Edit an existing note

- GIVEN a note exists in the list
- WHEN user taps it to open the editor
- AND modifies the content and saves
- THEN the note is updated in the database

#### Scenario: Delete a note

- GIVEN a note exists
- WHEN user swipes to delete or taps the delete action
- THEN the note is removed from the database
- AND removed from the in-memory list

### Requirement: Full-Text Search

The system MUST support searching notes by title and content.

#### Scenario: Search across notes

- GIVEN user has 20 notes
- WHEN user types "receta" in the search bar
- THEN only notes whose title OR content contains "receta" are shown

#### Scenario: No search results

- GIVEN no notes match the search query
- WHEN the search completes
- THEN an empty state "No notes found" is displayed

### Requirement: Tag System

The system MUST support tagging notes for organization.

#### Scenario: Tag a note

- GIVEN user creates or edits a note
- WHEN user adds tag "work" to the tags field
- THEN the note's `tags` array includes "work"

#### Scenario: Filter by tag

- GIVEN user has notes tagged "work" and "personal"
- WHEN user selects the "work" tag filter
- THEN only notes with tag "work" are displayed
