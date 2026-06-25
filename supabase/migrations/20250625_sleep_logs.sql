-- ═══════════════════════════════════════════════════════════════════
-- HeroOS: sleep_logs table
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS sleep_logs (
  id           uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  start_time   timestamptz NOT NULL,
  end_time     timestamptz NOT NULL,
  total_hours  numeric     NOT NULL,
  deep_sleep_pct  integer,
  light_sleep_pct integer,
  rem_sleep_pct   integer,
  quality_rating  integer,
  notes          text,
  avg_heart_rate integer,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- Index para consultas por usuario y ordenamiento
CREATE INDEX IF NOT EXISTS sleep_logs_user_id_idx      ON sleep_logs(user_id);
CREATE INDEX IF NOT EXISTS sleep_logs_start_time_idx   ON sleep_logs(start_time DESC);
CREATE INDEX IF NOT EXISTS sleep_logs_end_time_idx     ON sleep_logs(end_time);

-- RLS: solo el usuario puede ver/insertar/modificar sus propios registros
ALTER TABLE sleep_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own sleep logs"      ON sleep_logs;
CREATE POLICY "Users can view own sleep logs"
  ON sleep_logs FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own sleep logs"   ON sleep_logs;
CREATE POLICY "Users can insert own sleep logs"
  ON sleep_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own sleep logs"   ON sleep_logs;
CREATE POLICY "Users can update own sleep logs"
  ON sleep_logs FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own sleep logs"   ON sleep_logs;
CREATE POLICY "Users can delete own sleep logs"
  ON sleep_logs FOR DELETE
  USING (auth.uid() = user_id);
