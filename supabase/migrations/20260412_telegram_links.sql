-- Tabla de vinculación Telegram ↔ usuario de HeroOS.
-- Permite al bot de Telegram identificar a qué user_id de Supabase
-- corresponde un telegram_id entrante.
--
-- Flujo:
--   1. Usuario abre HeroOS app → genera link_token (UUID).
--   2. Envía /start <link_token> al bot de Telegram.
--   3. Edge Function verifica el token y crea el registro aquí.
--   4. A partir de ese momento el bot reconoce al usuario por telegram_id.

CREATE TABLE IF NOT EXISTS telegram_links (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- ID numérico único del usuario en Telegram (nunca cambia).
  telegram_id   bigint      NOT NULL,

  -- Username de Telegram (@handle) — puede ser NULL si el user no lo tiene.
  telegram_username text,

  -- Token de vinculación generado desde la app (usado una sola vez).
  -- Se pone a NULL después de usarse para evitar re-uso.
  link_token    uuid        UNIQUE,

  -- ¿El vínculo fue confirmado por el usuario? (double opt-in)
  is_active     boolean     NOT NULL DEFAULT false,

  -- Preferencia de idioma del usuario para las respuestas del bot.
  locale        text        NOT NULL DEFAULT 'es',

  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),

  -- Un usuario sólo puede vincular un Telegram (y viceversa)
  UNIQUE(user_id),
  UNIQUE(telegram_id)
);

-- ─── RLS ────────────────────────────────────────────────────────────────────

ALTER TABLE telegram_links ENABLE ROW LEVEL SECURITY;

-- El usuario autenticado puede leer y actualizar su propio vínculo.
CREATE POLICY "Users manage own telegram link"
  ON telegram_links
  FOR ALL
  USING (auth.uid() = user_id);

-- Las Edge Functions acceden con service_role (bypass RLS) — no se necesita
-- policy adicional para ellas.

-- ─── Índice ──────────────────────────────────────────────────────────────────

-- Búsqueda frecuente: dado telegram_id → obtener user_id.
CREATE INDEX idx_telegram_links_telegram_id ON telegram_links (telegram_id);

-- ─── Trigger updated_at ──────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Sólo crea el trigger si no existe ya (safe en re-runs).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'telegram_links_updated_at'
  ) THEN
    CREATE TRIGGER telegram_links_updated_at
      BEFORE UPDATE ON telegram_links
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;
END;
$$;
