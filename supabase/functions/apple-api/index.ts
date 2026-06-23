// @ts-nocheck — Deno global types
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "supabase-js";

// ─── Tipos ───────────────────────────────────────────────────────────────────

interface CreateReminderPayload {
  title: string;
  notes?: string;
  /** ISO 8601 — ej. "2026-04-15T09:00:00Z" */
  due_date?: string;
  list_name?: string;
}

interface CreateEventPayload {
  title: string;
  notes?: string;
  /** ISO 8601 start */
  start_date: string;
  /** ISO 8601 end */
  end_date?: string;
  all_day?: boolean;
  calendar_name?: string;
  location?: string;
}

interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
}

// ─── Constantes ───────────────────────────────────────────────────────────────

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_JWT_SECRET = Deno.env.get("SUPABASE_JWT_SECRET") ?? "";

// ─── CORS ─────────────────────────────────────────────────────────────────────

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ─── Handler principal ────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  // Pre-flight CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  const url = new URL(req.url);
  const path = url.pathname.replace(/^\/apple-api/, "").replace(/\/$/, "");

  // 1. Verificación JWT (Supabase Auth)
  const authHeader = req.headers.get("Authorization");
  const userId = await verifyJwt(authHeader);
  if (!userId) {
    return jsonResponse({ success: false, error: "Unauthorized — JWT inválido o expirado" }, 401);
  }

  if (req.method !== "POST") {
    return jsonResponse({ success: false, error: "Method Not Allowed" }, 405);
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ success: false, error: "Bad Request — JSON inválido" }, 400);
  }

  // 2. Routing por path
  switch (path) {
    case "/create-reminder":
      return handleCreateReminder(userId, body as CreateReminderPayload);

    case "/create-event":
      return handleCreateEvent(userId, body as CreateEventPayload);

    default:
      return jsonResponse(
        { success: false, error: `Endpoint desconocido: ${path}` },
        404,
      );
  }
});

// ─── Handlers ────────────────────────────────────────────────────────────────

/**
 * POST /create-reminder
 *
 * Guarda un recordatorio pendiente en Supabase.
 * Apple Shortcuts consulta esta tabla periódicamente y crea el recordatorio
 * en Apple Reminders via Shortcut automation.
 *
 * Body: { title, notes?, due_date?, list_name? }
 */
async function handleCreateReminder(
  userId: string,
  payload: CreateReminderPayload,
): Promise<Response> {
  const { title, notes, due_date, list_name } = payload;

  if (!title?.trim()) {
    return jsonResponse(
      { success: false, error: "El campo 'title' es requerido" },
      400,
    );
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  const { data, error } = await supabase
    .from("pending_reminders")
    .insert({
      user_id: userId,
      title: title.trim(),
      notes: notes?.trim() ?? null,
      due_date: due_date ?? null,
      list_name: list_name?.trim() ?? "HeroOS",
      status: "pending",
      created_at: new Date().toISOString(),
    })
    .select("id, title, due_date, status")
    .single();

  if (error) {
    console.error("[apple-api/create-reminder] DB error:", error);
    return jsonResponse(
      { success: false, error: "Error al guardar el recordatorio" },
      500,
    );
  }

  return jsonResponse<ApiResponse>({
    success: true,
    data: {
      id: data.id,
      title: data.title,
      due_date: data.due_date,
      status: data.status,
      message: `Recordatorio "${data.title}" programado. ` +
        "Apple Shortcuts lo creará en Reminders en el próximo ciclo.",
    },
  });
}

/**
 * POST /create-event
 *
 * Guarda un evento pendiente en Supabase para que Apple Shortcuts
 * lo cree en Apple Calendar.
 *
 * Body: { title, start_date, end_date?, all_day?, calendar_name?, notes?, location? }
 */
async function handleCreateEvent(
  userId: string,
  payload: CreateEventPayload,
): Promise<Response> {
  const { title, start_date, end_date, all_day, calendar_name, notes, location } = payload;

  if (!title?.trim()) {
    return jsonResponse(
      { success: false, error: "El campo 'title' es requerido" },
      400,
    );
  }

  if (!start_date) {
    return jsonResponse(
      { success: false, error: "El campo 'start_date' es requerido (ISO 8601)" },
      400,
    );
  }

  // Validar formato ISO 8601 básico
  if (isNaN(Date.parse(start_date))) {
    return jsonResponse(
      { success: false, error: "start_date no es una fecha ISO 8601 válida" },
      400,
    );
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  const { data, error } = await supabase
    .from("pending_events")
    .insert({
      user_id: userId,
      title: title.trim(),
      notes: notes?.trim() ?? null,
      start_date: start_date,
      end_date: end_date ?? null,
      all_day: all_day ?? false,
      calendar_name: calendar_name?.trim() ?? "HeroOS",
      location: location?.trim() ?? null,
      status: "pending",
      created_at: new Date().toISOString(),
    })
    .select("id, title, start_date, end_date, status")
    .single();

  if (error) {
    console.error("[apple-api/create-event] DB error:", error);
    return jsonResponse(
      { success: false, error: "Error al guardar el evento" },
      500,
    );
  }

  return jsonResponse<ApiResponse>({
    success: true,
    data: {
      id: data.id,
      title: data.title,
      start_date: data.start_date,
      end_date: data.end_date,
      status: data.status,
      message: `Evento "${data.title}" programado para ${data.start_date}. ` +
        "Apple Shortcuts lo creará en Calendar en el próximo ciclo.",
    },
  });
}

// ─── Auth helper ──────────────────────────────────────────────────────────────

/**
 * Verifica el JWT de Supabase Auth y retorna el user_id (sub) si es válido.
 * Retorna null si el token es inválido, expirado o ausente.
 *
 * Usa la verificación nativa de Supabase (llama a /auth/v1/user con el token).
 */
async function verifyJwt(authHeader: string | null): Promise<string | null> {
  if (!authHeader?.startsWith("Bearer ")) return null;

  const token = authHeader.slice(7);

  try {
    // Verificar via Supabase Auth API — más robusto que parsear el JWT manualmente.
    const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: {
        Authorization: `Bearer ${token}`,
        apikey: SUPABASE_ANON_KEY,
      },
    });

    if (!res.ok) return null;

    const user = await res.json();
    return (user?.id as string) ?? null;
  } catch {
    return null;
  }
}

// ─── Response helper ──────────────────────────────────────────────────────────

function jsonResponse<T>(body: T, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...CORS_HEADERS,
      "Content-Type": "application/json",
    },
  });
}
