// @ts-nocheck — Deno global types
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "supabase-js";

// ─── Tipos ───────────────────────────────────────────────────────────────────

interface TelegramUpdate {
  update_id: number;
  message?: TelegramMessage;
}

interface TelegramMessage {
  message_id: number;
  from: TelegramUser;
  chat: { id: number; type: string };
  text?: string;
  date: number;
}

interface TelegramUser {
  id: number;
  is_bot: boolean;
  first_name: string;
  username?: string;
  language_code?: string;
}

interface TelegramLink {
  user_id: string;
  telegram_id: number;
  is_active: boolean;
  locale: string;
}

// ─── Constantes ───────────────────────────────────────────────────────────────

const BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN") ?? "";
const WEBHOOK_SECRET = Deno.env.get("TELEGRAM_WEBHOOK_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const TELEGRAM_API = `https://api.telegram.org/bot${BOT_TOKEN}`;

// ─── Handler principal ────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  // 1. Verificación del secret token de Telegram
  const incomingSecret = req.headers.get("X-Telegram-Bot-Api-Secret-Token");
  if (WEBHOOK_SECRET && incomingSecret !== WEBHOOK_SECRET) {
    return new Response("Unauthorized", { status: 401 });
  }

  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  let update: TelegramUpdate;
  try {
    update = await req.json();
  } catch {
    return new Response("Bad Request: invalid JSON", { status: 400 });
  }

  const message = update.message;
  if (!message?.text || !message.from) {
    // Ignorar updates sin mensaje de texto (inline queries, etc.)
    return new Response("OK", { status: 200 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  const chatId = message.chat.id;
  const telegramId = message.from.id;
  const text = message.text.trim();

  try {
    // 2. Resolver user_id desde telegram_id
    const { data: link } = await supabase
      .from("telegram_links")
      .select("user_id, telegram_id, is_active, locale")
      .eq("telegram_id", telegramId)
      .eq("is_active", true)
      .maybeSingle<TelegramLink>();

    // 3. Manejo de /start <token> (vinculación)
    if (text.startsWith("/start")) {
      await handleStart(supabase, message, chatId, text, link);
      return new Response("OK", { status: 200 });
    }

    // 4. Si no está vinculado, pedir vinculación
    if (!link) {
      await sendMessage(
        chatId,
        "⚔️ *Héroe desconocido*\n\n" +
          "No encontré tu cuenta HeroOS vinculada a este Telegram.\n" +
          "Abrí la app, tocá tu perfil y seleccioná *Vincular Telegram* para empezar.",
      );
      return new Response("OK", { status: 200 });
    }

    // 5. Routing de comandos
    await routeCommand(supabase, link, chatId, text, message.from);
  } catch (err) {
    console.error("[telegram-bot] Error:", err);
    await sendMessage(
      chatId,
      "⚡ Algo salió mal en el servidor. Intentá de nuevo en unos segundos.",
    );
  }

  return new Response("OK", { status: 200 });
});

// ─── Vinculación ─────────────────────────────────────────────────────────────

async function handleStart(
  supabase: ReturnType<typeof createClient>,
  message: TelegramMessage,
  chatId: number,
  text: string,
  existingLink: TelegramLink | null,
): Promise<void> {
  // Si ya está vinculado
  if (existingLink) {
    await sendMessage(
      chatId,
      "✅ *¡Ya estás vinculado, héroe!*\n\nTu cuenta HeroOS ya está conectada. " +
        "Usá /help para ver los comandos disponibles.",
    );
    return;
  }

  const parts = text.split(" ");
  const token = parts[1]?.trim();

  if (!token) {
    await sendMessage(
      chatId,
      "⚔️ *Bienvenido a HeroOS Bot*\n\n" +
        "Para vincular tu cuenta, abrí la app HeroOS, tocá tu perfil " +
        "y seleccioná *Vincular Telegram*.",
    );
    return;
  }

  // Verificar token en telegram_links
  const { data: pendingLink, error } = await supabase
    .from("telegram_links")
    .select("id, user_id, link_token")
    .eq("link_token", token)
    .eq("is_active", false)
    .maybeSingle();

  if (error || !pendingLink) {
    await sendMessage(
      chatId,
      "❌ *Token inválido o expirado.*\n\nGenerá uno nuevo desde la app HeroOS.",
    );
    return;
  }

  // Activar vínculo
  const { error: updateError } = await supabase
    .from("telegram_links")
    .update({
      telegram_id: message.from.id,
      telegram_username: message.from.username ?? null,
      is_active: true,
      link_token: null, // consumido, no re-usable
    })
    .eq("id", pendingLink.id);

  if (updateError) {
    await sendMessage(chatId, "❌ Error al vincular la cuenta. Intentá de nuevo.");
    return;
  }

  await sendMessage(
    chatId,
    "🎉 *¡Cuenta vinculada exitosamente, Héroe!*\n\n" +
      "Ahora podés gestionar tus finanzas y hábitos directamente desde Telegram.\n\n" +
      "Usá /help para ver todos los comandos disponibles.",
  );
}

// ─── Routing de comandos ──────────────────────────────────────────────────────

async function routeCommand(
  supabase: ReturnType<typeof createClient>,
  link: TelegramLink,
  chatId: number,
  text: string,
  from: TelegramUser,
): Promise<void> {
  // Comandos exactos
  if (text === "/help") {
    await handleHelp(chatId);
    return;
  }

  if (text === "/status") {
    await handleStatus(supabase, link, chatId);
    return;
  }

  if (text === "/habitos") {
    await handleHabitos(supabase, link, chatId);
    return;
  }

  // Comandos con argumentos
  if (text.startsWith("/gasto")) {
    await handleGasto(supabase, link, chatId, text);
    return;
  }

  if (text.startsWith("/ingreso")) {
    await handleIngreso(supabase, link, chatId, text);
    return;
  }

  if (text.startsWith("/habito")) {
    await handleHabito(supabase, link, chatId, text);
    return;
  }

  // Texto libre → OpenCode Zen via función interna
  await handleFreeText(supabase, link, chatId, text, from);
}

// ─── Handlers de comandos ─────────────────────────────────────────────────────

async function handleHelp(chatId: number): Promise<void> {
  const helpText =
    "⚔️ *Comandos de HeroOS Bot*\n\n" +
    "💰 *Finanzas*\n" +
    "`/gasto <monto> <categoría>` — Registrar un gasto\n" +
    "`/ingreso <monto> <fuente>` — Registrar un ingreso\n\n" +
    "🏃 *Hábitos*\n" +
    "`/habito <nombre>` — Completar un hábito hoy\n" +
    "`/habitos` — Ver hábitos de hoy\n\n" +
    "🛡️ *Estado*\n" +
    "`/status` — Ver tu estado RPG actual\n\n" +
    "💬 *Texto libre*\n" +
    "Podés escribir directamente: _\"gasté \$50 en comida\"_ o _\"completé ejercicio\"_";

  await sendMessage(chatId, helpText);
}

async function handleStatus(
  supabase: ReturnType<typeof createClient>,
  link: TelegramLink,
  chatId: number,
): Promise<void> {
  const { data: profile } = await supabase
    .from("profiles")
    .select("level, current_xp, current_hp, max_hp, current_gold")
    .eq("id", link.user_id)
    .maybeSingle();

  if (!profile) {
    await sendMessage(chatId, "❌ No se encontró tu perfil de héroe.");
    return;
  }

  const hpBar = buildBar(profile.current_hp, profile.max_hp, 10, "❤️", "🖤");
  const xpNext = profile.level * 100; // Simple formula, debe sincronizarse con la app
  const xpBar = buildBar(profile.current_xp, xpNext, 10, "⭐", "⬜");

  await sendMessage(
    chatId,
    `🛡️ *Estado del Héroe — Nivel ${profile.level}*\n\n` +
      `❤️ HP: ${profile.current_hp}/${profile.max_hp}\n${hpBar}\n\n` +
      `⭐ XP: ${profile.current_xp}/${xpNext}\n${xpBar}\n\n` +
      `💰 Oro: $${Number(profile.current_gold).toFixed(2)}`,
  );
}

async function handleHabitos(
  supabase: ReturnType<typeof createClient>,
  link: TelegramLink,
  chatId: number,
): Promise<void> {
  const { data: habits } = await supabase
    .from("habits")
    .select("id, title, frequency_mask")
    .eq("user_id", link.user_id)
    .eq("is_archived", false);

  if (!habits || habits.length === 0) {
    await sendMessage(chatId, "📋 No tenés hábitos activos. Creá uno desde la app.");
    return;
  }

  const today = new Date();
  const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  const todayStr = dayNames[today.getDay()];

  const todayHabits = habits.filter((h: { frequency_mask: string }) => {
    if (!h.frequency_mask) return true; // sin máscara = siempre activo
    return h.frequency_mask.includes(todayStr);
  });

  if (todayHabits.length === 0) {
    await sendMessage(chatId, "🎉 ¡No tenés hábitos programados para hoy! Descansá, héroe.");
    return;
  }

  // Obtener completados hoy
  const todayDate = today.toISOString().split("T")[0];
  const { data: logs } = await supabase
    .from("habit_logs")
    .select("habit_id")
    .eq("user_id", link.user_id)
    .gte("completed_at", `${todayDate}T00:00:00Z`)
    .lte("completed_at", `${todayDate}T23:59:59Z`);

  const completedIds = new Set((logs ?? []).map((l: { habit_id: string }) => l.habit_id));

  const lines = todayHabits.map((h: { id: string; title: string }) => {
    const done = completedIds.has(h.id);
    const icon = done ? "✅" : "⬜";
    return `${icon} ${h.title}`;
  });

  await sendMessage(
    chatId,
    `🏃 *Hábitos de hoy (${todayDate})*\n\n${lines.join("\n")}\n\n` +
      `_Usá /habito <nombre> para completar uno_`,
  );
}

async function handleGasto(
  supabase: ReturnType<typeof createClient>,
  link: TelegramLink,
  chatId: number,
  text: string,
): Promise<void> {
  // Formato: /gasto <monto> [categoría]
  const args = text.replace("/gasto", "").trim();
  const parsed = parseAmountAndCategory(args);

  if (!parsed) {
    await sendMessage(
      chatId,
      "❌ Formato incorrecto.\nEjemplo: `/gasto 50 Comida` o `/gasto 150.50 Transporte`",
    );
    return;
  }

  const { amount, category } = parsed;
  const accountId = await getDefaultAccountId(supabase, link.user_id);

  if (!accountId) {
    await sendMessage(chatId, "❌ No encontré tu cuenta principal. Creá una desde la app.");
    return;
  }

  const { error } = await supabase.from("transactions").insert({
    user_id: link.user_id,
    account_id: accountId,
    amount: -Math.abs(amount),
    category: category,
    type: "expense",
    note: "Registrado via Telegram Bot",
    date: new Date().toISOString(),
  });

  if (error) {
    await sendMessage(chatId, "❌ Error al registrar el gasto. Intentá de nuevo.");
    return;
  }

  await sendMessage(
    chatId,
    `⚔️ *Gasto registrado*\n\n` +
      `💸 -$${amount.toFixed(2)} en *${category}*\n` +
      `_¡El oro del inventario se redujo, héroe!_`,
  );
}

async function handleIngreso(
  supabase: ReturnType<typeof createClient>,
  link: TelegramLink,
  chatId: number,
  text: string,
): Promise<void> {
  // Formato: /ingreso <monto> [fuente]
  const args = text.replace("/ingreso", "").trim();
  const parsed = parseAmountAndCategory(args);

  if (!parsed) {
    await sendMessage(
      chatId,
      "❌ Formato incorrecto.\nEjemplo: `/ingreso 1500 Nómina` o `/ingreso 300 Freelance`",
    );
    return;
  }

  const { amount, category } = parsed;
  const accountId = await getDefaultAccountId(supabase, link.user_id);

  if (!accountId) {
    await sendMessage(chatId, "❌ No encontré tu cuenta principal. Creá una desde la app.");
    return;
  }

  const { error } = await supabase.from("transactions").insert({
    user_id: link.user_id,
    account_id: accountId,
    amount: Math.abs(amount),
    category: category,
    type: "income",
    note: "Registrado via Telegram Bot",
    date: new Date().toISOString(),
  });

  if (error) {
    await sendMessage(chatId, "❌ Error al registrar el ingreso. Intentá de nuevo.");
    return;
  }

  await sendMessage(
    chatId,
    `✨ *Ingreso registrado*\n\n` +
      `💰 +$${amount.toFixed(2)} de *${category}*\n` +
      `_¡El oro del inventario creció, héroe!_`,
  );
}

async function handleHabito(
  supabase: ReturnType<typeof createClient>,
  link: TelegramLink,
  chatId: number,
  text: string,
): Promise<void> {
  // Formato: /habito <nombre>
  const habitName = text.replace("/habito", "").trim();

  if (!habitName) {
    await sendMessage(
      chatId,
      "❌ Indicá el nombre del hábito.\nEjemplo: `/habito ejercicio`",
    );
    return;
  }

  const { data: habits } = await supabase
    .from("habits")
    .select("id, title")
    .eq("user_id", link.user_id)
    .eq("is_archived", false)
    .ilike("title", `%${habitName}%`);

  if (!habits || habits.length === 0) {
    await sendMessage(
      chatId,
      `🔍 No encontré ningún hábito con el nombre *"${habitName}"*.\n` +
        `Usá /habitos para ver tu lista.`,
    );
    return;
  }

  const habit = habits[0];
  const today = new Date().toISOString();

  const { error } = await supabase.from("habit_logs").insert({
    habit_id: habit.id,
    user_id: link.user_id,
    completed_at: today,
  });

  if (error) {
    if (error.code === "23505") {
      // Unique violation — ya completado hoy
      await sendMessage(
        chatId,
        `✅ *"${habit.title}"* ya fue completado hoy.\n_¡Mantené ese ritmo, héroe!_`,
      );
      return;
    }
    await sendMessage(chatId, "❌ Error al registrar el hábito. Intentá de nuevo.");
    return;
  }

  await sendMessage(
    chatId,
    `🏆 *¡Hábito completado!*\n\n` +
      `⚡ *${habit.title}*\n\n` +
      `_¡Mantené ese ritmo, héroe!_`,
  );
}

async function handleFreeText(
  supabase: ReturnType<typeof createClient>,
  link: TelegramLink,
  chatId: number,
  text: string,
  from: TelegramUser,
): Promise<void> {
  // Texto libre → llama a la función agent-chat de Supabase (si existe)
  // o aplica heurística local simple antes del LLM fallback.

  // Heurística: detectar patrones simples sin LLM
  const expenseMatch = text.match(
    /(?:gast[eé]|pagu[eé]|compr[eé])\s+\$?(\d+(?:[.,]\d{1,2})?)\s*(?:en\s+(.+))?/i,
  );
  if (expenseMatch) {
    const fakeText = `/gasto ${expenseMatch[1]} ${expenseMatch[2] ?? "General"}`;
    await handleGasto(supabase, link, chatId, fakeText);
    return;
  }

  const incomeMatch = text.match(
    /(?:gan[eé]|cobr[eé]|recib[ií])\s+\$?(\d+(?:[.,]\d{1,2})?)\s*(?:de\s+(.+))?/i,
  );
  if (incomeMatch) {
    const fakeText = `/ingreso ${incomeMatch[1]} ${incomeMatch[2] ?? "Ingresos"}`;
    await handleIngreso(supabase, link, chatId, fakeText);
    return;
  }

  const habitMatch = text.match(
    /(?:complet[eé]|hic[ei]|termin[eé])\s+(?:mi\s+h[aá]bito\s+de\s+)?(.+)/i,
  );
  if (habitMatch) {
    const fakeText = `/habito ${habitMatch[1]}`;
    await handleHabito(supabase, link, chatId, fakeText);
    return;
  }

  // Fallback: indicar al usuario que use comandos
  await sendMessage(
    chatId,
    `🤔 No entendí ese mensaje, *${from.first_name}*.\n\n` +
      `Podés usar comandos como:\n` +
      `• \`/gasto 50 Comida\`\n` +
      `• \`/ingreso 1500 Nómina\`\n` +
      `• \`/habito ejercicio\`\n\n` +
      `O escribí /help para ver todos los comandos.`,
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Envía un mensaje a un chat de Telegram con Markdown V2 simplificado. */
async function sendMessage(chatId: number, text: string): Promise<void> {
  await fetch(`${TELEGRAM_API}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      chat_id: chatId,
      text: text,
      parse_mode: "Markdown",
    }),
  });
}

/** Parsea "<monto> [categoría]" de los argumentos de un comando. */
function parseAmountAndCategory(
  args: string,
): { amount: number; category: string } | null {
  const parts = args.split(/\s+/);
  if (!parts[0]) return null;

  const amountStr = parts[0].replace(",", ".");
  const amount = parseFloat(amountStr);
  if (isNaN(amount) || amount <= 0) return null;

  const category = parts.slice(1).join(" ").trim() || "General";
  return { amount, category };
}

/** Obtiene el account_id por defecto del usuario (primera cuenta activa). */
async function getDefaultAccountId(
  supabase: ReturnType<typeof createClient>,
  userId: string,
): Promise<string | null> {
  const { data } = await supabase
    .from("accounts")
    .select("id")
    .eq("user_id", userId)
    .limit(1)
    .maybeSingle();

  return data?.id ?? null;
}

/** Construye una barra de progreso con emoji. */
function buildBar(
  current: number,
  max: number,
  length: number,
  filled: string,
  empty: string,
): string {
  const ratio = Math.min(current / max, 1);
  const filledCount = Math.round(ratio * length);
  const emptyCount = length - filledCount;
  return filled.repeat(filledCount) + empty.repeat(emptyCount);
}
