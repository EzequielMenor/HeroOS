-- Tabla de objetivos personales del héroe.
-- Los valores aquí configurados alimentan la gamificación de cada módulo:
--   sleep_hours_target  → XP de sueño (EZE-114)
--   min_habits_daily    → Evaluación diaria de hábitos
--   max_monthly_spending→ Alerta de presupuesto en finanzas

CREATE TABLE user_goals (
  id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sleep_hours_target    numeric     DEFAULT 8,
  min_habits_daily      int         DEFAULT 3,
  max_monthly_spending  numeric     DEFAULT 500,
  created_at            timestamptz DEFAULT now(),
  updated_at            timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

ALTER TABLE user_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own goals" ON user_goals
  FOR ALL USING (auth.uid() = user_id);
