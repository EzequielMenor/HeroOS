-- Tabla de eventos RPG (feed de actividad)
-- Ejecutar en el SQL Editor de Supabase

CREATE TABLE rpg_events (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type  text        NOT NULL CHECK (event_type IN ('xp_gain','xp_loss','hp_loss','level_up','game_over')),
  amount      int         NOT NULL DEFAULT 0,
  description text        NOT NULL DEFAULT '',
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Índice para acelerar consultas por usuario ordenadas por fecha
CREATE INDEX rpg_events_user_created ON rpg_events (user_id, created_at DESC);

-- Row Level Security
ALTER TABLE rpg_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own events"
  ON rpg_events
  FOR ALL
  USING (auth.uid() = user_id);
