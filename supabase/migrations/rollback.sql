-- Rollback for Zen OS Pivot Migration
-- Inverse operations to restore RPG layer and remove AI/notes additions

-- 1. Drop notes table
DROP TABLE IF EXISTS notes CASCADE;

-- 2. Tasks: drop energy, restore difficulty/xp
ALTER TABLE tasks
  DROP COLUMN IF EXISTS energy,
  ADD COLUMN IF NOT EXISTS difficulty INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS xp_value INTEGER DEFAULT 10;

-- 3. Habits: restore XP mechanics
ALTER TABLE habits
  ADD COLUMN IF NOT EXISTS xp_reward INTEGER DEFAULT 10,
  ADD COLUMN IF NOT EXISTS dmg_penalty INTEGER DEFAULT 5,
  ADD COLUMN IF NOT EXISTS xp_value INTEGER DEFAULT 10;

-- 4. Profiles: drop AI config, restore RPG columns
ALTER TABLE profiles
  DROP COLUMN IF EXISTS ai_api_key,
  DROP COLUMN IF EXISTS ai_provider,
  ADD COLUMN IF NOT EXISTS level INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS current_xp INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS xp_next_level INTEGER DEFAULT 100,
  ADD COLUMN IF NOT EXISTS current_hp INTEGER DEFAULT 100,
  ADD COLUMN IF NOT EXISTS max_hp INTEGER DEFAULT 100,
  ADD COLUMN IF NOT EXISTS current_gold NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_alive BOOLEAN DEFAULT true;

-- 5. Recreate rpg_events table
CREATE TABLE IF NOT EXISTS rpg_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  event_type  TEXT NOT NULL,
  amount      INTEGER NOT NULL DEFAULT 0,
  description TEXT NOT NULL DEFAULT '',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS rpg_events_user_idx ON rpg_events(user_id);
CREATE INDEX IF NOT EXISTS rpg_events_created_idx ON rpg_events(created_at DESC);

ALTER TABLE rpg_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rpg_events_owner_all" ON rpg_events;
CREATE POLICY "rpg_events_owner_all" ON rpg_events
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
