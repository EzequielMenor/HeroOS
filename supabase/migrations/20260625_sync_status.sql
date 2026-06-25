-- ═══════════════════════════════════════════════════════════════════
-- HeroOS: sync_status column for AI-assisted quick capture
-- ═══════════════════════════════════════════════════════════════════
-- Adds the sync_status column to transactions and tasks tables.
-- Used by the QuickCaptureViewModel to track:
--   - pendingAi:    awaiting AI classification
--   - completed:    AI classification finished
--   - userModified: user manually edited (invalidates AI response)
-- ═══════════════════════════════════════════════════════════════════

-- 1. Add sync_status to transactions
ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS sync_status text;

-- 2. Add sync_status to tasks
ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS sync_status text;
