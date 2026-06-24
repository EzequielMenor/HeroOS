-- Zen OS Pivot Migration
-- Drops RPG layer, adds AI config to profiles, strips XP from habits/tasks, creates notes table

-- 1. Drop RPG artifacts
DROP TABLE IF EXISTS rpg_events CASCADE;

-- 2. Profiles: drop RPG columns, add AI config
ALTER TABLE profiles
  DROP COLUMN IF EXISTS level,
  DROP COLUMN IF EXISTS current_xp,
  DROP COLUMN IF EXISTS xp_next_level,
  DROP COLUMN IF EXISTS current_hp,
  DROP COLUMN IF EXISTS max_hp,
  DROP COLUMN IF EXISTS current_gold,
  DROP COLUMN IF EXISTS is_alive,
  ADD COLUMN IF NOT EXISTS ai_api_key TEXT,
  ADD COLUMN IF NOT EXISTS ai_provider TEXT DEFAULT 'openai';

-- 3. Habits: drop XP mechanics
ALTER TABLE habits
  DROP COLUMN IF EXISTS xp_reward,
  DROP COLUMN IF EXISTS dmg_penalty,
  DROP COLUMN IF EXISTS xp_value;

-- 4. Tasks: drop difficulty/xp, add energy
ALTER TABLE tasks
  DROP COLUMN IF EXISTS difficulty,
  DROP COLUMN IF EXISTS xp_value,
  ADD COLUMN IF NOT EXISTS energy TEXT;

-- 5. Notes table
CREATE TABLE notes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  content     TEXT NOT NULL DEFAULT '',
  date        TIMESTAMPTZ NOT NULL DEFAULT now(),
  tags        TEXT[] NOT NULL DEFAULT '{}'
);

CREATE INDEX notes_user_idx ON notes(user_id);
CREATE INDEX notes_tags_idx    ON notes USING GIN(tags);

ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notes_owner_all" ON notes
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
