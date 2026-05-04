// ============================================================
// П3 · TG-бот календаря Ирины Цепаевой
// ------------------------------------------------------------
// Делает 5 вещей:
//   1. /start — приветствие + кнопка Web App, которая открывает
//      Mini App с календарём (фронт пишет Кодыч).
//   2. /privacy — отдаёт ссылку на политику конфиденциальности
//      (требование 152-ФЗ ст.18.1).
//   3. POST /notify — опциональный endpoint для Baserow Webhook.
//      Принимает новую заявку, форматирует и шлёт Ирине в TG.
//   4. Polling Baserow раз в 60 сек на случай, если webhook не
//      настроен или упал. Ищет записи со status=new, которые ещё
//      не отправлялись (трекинг через локальный файл seen.json).
//   5. Inline-кнопки «Подтвердить / Отменить» под каждой
//      присланной заявкой — меняют status в Baserow через REST API.
//
// Стек: РФ-only. Baserow на VPS (РФ), email через UniSender Go
// или SendPulse (РФ). Никакого Supabase / Resend.
//
// Словарь Ирины: «бесплатное знакомство», «обсудить проект»,
// «изготовлю». НЕ «провожу аудит / консультирую» (это словарь Инны).
// ============================================================

require('dotenv').config();

const fs = require('fs');
const path = require('path');
const express = require('express');
const TelegramBot = require('node-telegram-bot-api');
const fetch = require('node-fetch');

const {
  TG_BOT_TOKEN,
  TG_OWNER_CHAT_ID,
  MINIAPP_URL,
  PRIVACY_URL,
  PORT = 3010,
  NOTIFY_SECRET,
  EMAIL_NOTIFY_URL,
  VK_BOT_NOTIFY_URL,

  BASEROW_URL,
  BASEROW_TOKEN,
  BASEROW_TABLE_BOOKINGS,

  POLL_INTERVAL_SEC = 60,
} = process.env;

if (!TG_BOT_TOKEN || !TG_OWNER_CHAT_ID || !MINIAPP_URL || !NOTIFY_SECRET) {
  console.error('[fatal] не заполнен .env (TG_BOT_TOKEN / TG_OWNER_CHAT_ID / MINIAPP_URL / NOTIFY_SECRET)');
  process.exit(1);
}
if (!BASEROW_URL || !BASEROW_TOKEN || !BASEROW_TABLE_BOOKINGS) {
  console.error('[fatal] не заполнен .env Baserow (BASEROW_URL / BASEROW_TOKEN / BASEROW_TABLE_BOOKINGS)');
  process.exit(1);
}

// ------------------------------------------------------------
// Локальный трекер уже отправленных заявок (на случай polling)
// ------------------------------------------------------------
const SEEN_FILE = path.join(__dirname, 'seen.json');
let seenIds = new Set();
try {
  if (fs.existsSync(SEEN_FILE)) {
    seenIds = new Set(JSON.parse(fs.readFileSync(SEEN_FILE, 'utf8')));
  }
} catch (e) {
  console.warn('[seen] не смог прочитать seen.json:', e.message);
}
function persistSeen() {
  try {
    fs.writeFileSync(SEEN_FILE, JSON.stringify([...seenIds]), 'utf8');
  } catch (e) {
    console.warn('[seen] не смог записать seen.json:', e.message);
  }
}

// ------------------------------------------------------------
// Baserow REST API helpers
// ------------------------------------------------------------
const baserowHeaders = {
  Authorization: `Token ${BASEROW_TOKEN}`,
  'Content-Type': 'application/json',
};

// Запрашиваем строки в JSON-формате с именами колонок (user_field_names=true)
async function baserowListNew() {
  const url =
    `${BASEROW_URL}/api/database/rows/table/${BASEROW_TABLE_BOOKINGS}/` +
    `?user_field_names=true&size=50&order_by=-created_at` +
    `&filter__status__equal=new`;

  const resp = await fetch(url, { headers: baserowHeaders, timeout: 10000 });
  if (!resp.ok) {
    throw new Error(`Baserow list ${resp.status}: ${await resp.text()}`);
  }
  const data = await resp.json();
  return data.results || [];
}

async function baserowUpdateStatus(rowId, status) {
  const url =
    `${BASEROW_URL}/api/database/rows/table/${BASEROW_TABLE_BOOKINGS}/${rowId}/` +
    `?user_field_names=true`;
  const resp = await fetch(url, {
    method: 'PATCH',
    headers: baserowHeaders,
    body: JSON.stringify({ status }),
    timeout: 10000,
  });
  if (!resp.ok) {
    throw new Error(`Baserow PATCH ${resp.status}: ${await resp.text()}`);
  }
  return resp.json();
}

// ------------------------------------------------------------
// Telegram-бот (long-polling)
// ------------------------------------------------------------
const bot = new TelegramBot(TG_BOT_TOKEN, { polling: true });

bot.onText(/^\/start(?:\s+(.+))?$/, async (msg) => {
  const chatId = msg.chat.id;

  const greeting =
    'Здравствуйте! Я бот Ирины Цепаевой.\n\n' +
    'Здесь можно записаться на бесплатное знакомство — 30 минут, чтобы обсудить ваш проект.\n\n' +
    'Нажмите кнопку ниже — откроется календарь, выберите удобное время.';

  await bot.sendMessage(chatId, greeting, {
    reply_markup: {
      inline_keyboard: [[
        { text: 'Открыть календарь', web_app: { url: MINIAPP_URL } },
      ]],
    },
  });

  try {
    await bot.setChatMenuButton({
      chat_id: chatId,
      menu_button: {
        type: 'web_app',
        text: 'Записаться',
        web_app: { url: MINIAPP_URL },
      },
    });
  } catch (e) {
    console.warn('[start] setChatMenuButton:', e.message);
  }
});

bot.onText(/^\/privacy$/, async (msg) => {
  const text =
    'Политика конфиденциальности и согласие на обработку персональных данных:\n' +
    (PRIVACY_URL || 'ссылка появится после публикации') + '\n\n' +
    'Запросы по персональным данным — на email Ирины (указан в политике).';
  await bot.sendMessage(msg.chat.id, text, { disable_web_page_preview: true });
});

bot.on('polling_error', (err) => {
  console.error('[polling_error]', err.code, err.message);
});

// Обработка inline-кнопок «Подтвердить / Отменить»
bot.on('callback_query', async (q) => {
  const data = q.data || '';
  const match = data.match(/^booking:(\d+):(confirm|cancel|done)$/);
  if (!match) return;

  const rowId = match[1];
  const action = match[2];
  const newStatus = action === 'confirm' ? 'confirmed' : (action === 'done' ? 'done' : 'cancelled');

  try {
    await baserowUpdateStatus(rowId, newStatus);
    await bot.answerCallbackQuery(q.id, { text: `Статус изменён: ${newStatus}` });
    // Обновим клавиатуру под сообщением — уберём кнопки
    await bot.editMessageReplyMarkup(
      { inline_keyboard: [[{ text: `Статус: ${newStatus}`, callback_data: 'noop' }]] },
      { chat_id: q.message.chat.id, message_id: q.message.message_id }
    );
  } catch (e) {
    console.error('[callback]', e.message);
    await bot.answerCallbackQuery(q.id, { text: 'Ошибка: ' + e.message, show_alert: true });
  }
});

// ------------------------------------------------------------
// Форматирование уведомления
// ------------------------------------------------------------
function formatBookingForTG(b) {
  const contactLabel = {
    telegram: 'Telegram',
    vk: 'VK',
    email: 'Email',
    phone: 'Телефон',
  }[b.contact_method?.value || b.contact_method] || (b.contact_method?.value || b.contact_method);

  const sourceLabel = {
    tg_miniapp: 'из Telegram',
    vk_miniapp: 'из VK',
    website: 'с сайта',
  }[b.source?.value || b.source] || (b.source?.value || b.source);

  return [
    'Новая запись на знакомство',
    '',
    `Дата: ${b.slot_date} в ${b.slot_time} (${b.duration_min} мин)`,
    `Имя: ${b.name}`,
    `${contactLabel}: ${b.contact_value}`,
    b.message ? `Сообщение: ${b.message}` : null,
    '',
    `Источник: ${sourceLabel}`,
    `ID: ${b.id}`,
  ].filter(Boolean).join('\n');
}

function bookingKeyboard(rowId) {
  return {
    inline_keyboard: [[
      { text: 'Подтвердить', callback_data: `booking:${rowId}:confirm` },
      { text: 'Отменить', callback_data: `booking:${rowId}:cancel` },
    ]],
  };
}

// ------------------------------------------------------------
// Fan-out: TG (это мы) → email + VK (опционально)
// ------------------------------------------------------------
async function fanoutBooking(record) {
  // 1. TG — главный канал
  const tgPromise = bot
    .sendMessage(TG_OWNER_CHAT_ID, formatBookingForTG(record), {
      reply_markup: bookingKeyboard(record.id),
    })
    .then(() => ({ channel: 'tg', ok: true }))
    .catch((e) => ({ channel: 'tg', ok: false, error: e.message }));

  // 2. Email — параллельно
  const emailPromise = EMAIL_NOTIFY_URL
    ? fetch(EMAIL_NOTIFY_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${NOTIFY_SECRET}`,
        },
        body: JSON.stringify({ record }),
        timeout: 7000,
      })
        .then((r) => ({ channel: 'email', ok: r.ok, status: r.status }))
        .catch((e) => ({ channel: 'email', ok: false, error: e.message }))
    : Promise.resolve({ channel: 'email', ok: false, skipped: true });

  // 3. VK — опционально
  const vkPromise = VK_BOT_NOTIFY_URL
    ? fetch(VK_BOT_NOTIFY_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${NOTIFY_SECRET}`,
        },
        body: JSON.stringify({ record }),
        timeout: 5000,
      })
        .then((r) => ({ channel: 'vk', ok: r.ok, status: r.status }))
        .catch((e) => ({ channel: 'vk', ok: false, error: e.message }))
    : Promise.resolve({ channel: 'vk', ok: false, skipped: true });

  const results = await Promise.allSettled([tgPromise, emailPromise, vkPromise]);
  const summary = results.map((r) => (r.status === 'fulfilled' ? r.value : { ok: false, error: r.reason?.message }));
  console.log(`[fanout] booking=${record.id}`, JSON.stringify(summary));
  return summary;
}

// ------------------------------------------------------------
// Polling Baserow раз в N секунд
// ------------------------------------------------------------
async function pollBaserow() {
  try {
    const rows = await baserowListNew();
    for (const row of rows) {
      if (seenIds.has(row.id)) continue;
      // 152-ФЗ: без согласия не отправляем (доп. защита, фронт уже фильтрует)
      if (!row.consent_given) {
        console.warn(`[poll] booking=${row.id} без consent_given — пропуск`);
        seenIds.add(row.id);
        continue;
      }
      await fanoutBooking(row);
      seenIds.add(row.id);
    }
    persistSeen();
  } catch (e) {
    console.error('[poll]', e.message);
  }
}

setInterval(pollBaserow, Number(POLL_INTERVAL_SEC) * 1000);
// Стартовый запуск через 5 секунд
setTimeout(pollBaserow, 5000);

// ------------------------------------------------------------
// HTTP-сервер: /notify (от Baserow Webhook, если он работает) + /health
// ------------------------------------------------------------
const app = express();
app.use(express.json({ limit: '64kb' }));

app.get('/health', (req, res) => res.json({ ok: true, service: 'tg-bot', ts: Date.now() }));

// Baserow webhook payload зависит от версии. Принимаем гибко:
//   { items: [ {...row...} ], ... }   (новый формат)
//   { row: {...} }                    (старый)
//   { ...row... }                     (минимальный)
app.post('/notify', async (req, res) => {
  const auth = req.headers['authorization'] || '';
  if (auth !== `Bearer ${NOTIFY_SECRET}`) {
    return res.status(401).json({ ok: false, error: 'unauthorized' });
  }

  const body = req.body || {};
  const records = Array.isArray(body.items) ? body.items
                : body.row ? [body.row]
                : body.id ? [body]
                : [];

  if (!records.length) {
    return res.status(400).json({ ok: false, error: 'no record' });
  }

  for (const record of records) {
    if (seenIds.has(record.id)) continue;
    if (!record.consent_given) {
      console.warn(`[notify] booking=${record.id} без consent_given — пропуск`);
      seenIds.add(record.id);
      continue;
    }
    await fanoutBooking(record);
    seenIds.add(record.id);
  }
  persistSeen();
  res.json({ ok: true, processed: records.length });
});

app.listen(PORT, () => {
  console.log(`[tg-bot] HTTP listening on :${PORT}`);
  console.log(`[tg-bot] polling Baserow every ${POLL_INTERVAL_SEC}s, owner=${TG_OWNER_CHAT_ID}`);
});

process.on('SIGTERM', async () => {
  console.log('[tg-bot] SIGTERM, stopping polling…');
  try { await bot.stopPolling(); } catch (_) {}
  persistSeen();
  process.exit(0);
});
