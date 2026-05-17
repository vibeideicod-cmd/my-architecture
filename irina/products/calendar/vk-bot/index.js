// ============================================================
// П3 · VK-бот календаря Ирины Цепаевой
// ------------------------------------------------------------
// Делает 3 вещи:
//   1. POST /vk-callback — принимает Callback API от VK:
//      - confirmation → отдаёт confirmation-token
//      - message_new  → шлёт пользователю приветствие со ссылкой
//                       на VK Mini App
//   2. POST /notify — принимает уведомление от TG-бота (наш
//      внутренний канал, после того как TG-бот выгреб новую запись
//      из Baserow) и шлёт сообщение Ирине в личку от имени
//      сообщества.
//   3. GET /health — health-check.
//
// Стек: РФ-only. Никакого Supabase / Resend.
// ============================================================

require('dotenv').config();

const express = require('express');
const { VK } = require('vk-io');

const {
  VK_GROUP_TOKEN,
  VK_GROUP_ID,
  VK_OWNER_USER_ID,
  VK_MINIAPP_URL,
  PORT = 3011,
  NOTIFY_SECRET,
  VK_CONFIRMATION_TOKEN,
  VK_CALLBACK_SECRET,
} = process.env;

if (!VK_GROUP_TOKEN || !VK_OWNER_USER_ID || !NOTIFY_SECRET || !VK_CONFIRMATION_TOKEN) {
  console.error('[fatal] не заполнен .env (VK_GROUP_TOKEN / VK_OWNER_USER_ID / NOTIFY_SECRET / VK_CONFIRMATION_TOKEN)');
  process.exit(1);
}

const vk = new VK({ token: VK_GROUP_TOKEN });

const app = express();
app.use(express.json({ limit: '64kb' }));

app.get('/health', (req, res) => res.json({ ok: true, service: 'vk-bot', ts: Date.now() }));

// ------------------------------------------------------------
// VK Callback API
// ------------------------------------------------------------
// Настраивается в сообществе: «Управление» → «Работа с API» → «Callback API»
// → URL: https://<твой-vps-домен>/vk-callback
// → Тип: confirmation, message_new
// → Secret key: тот же, что в VK_CALLBACK_SECRET
app.post('/vk-callback', async (req, res) => {
  const body = req.body || {};

  if (body.type === 'confirmation') {
    return res.send(VK_CONFIRMATION_TOKEN);
  }

  if (VK_CALLBACK_SECRET && body.secret !== VK_CALLBACK_SECRET) {
    console.warn('[vk-callback] неверный secret');
    return res.status(401).send('bad secret');
  }

  if (body.type === 'message_new') {
    const message = body.object?.message;
    if (message && message.from_id) {
      const userId = message.from_id;
      const text =
        'Здравствуйте! Я бот Ирины.\n' +
        'Записаться на бесплатное знакомство (30 минут, обсудим ваш проект) — откройте приложение по ссылке:\n' +
        VK_MINIAPP_URL;

      try {
        await vk.api.messages.send({
          user_id: userId,
          message: text,
          random_id: Math.floor(Math.random() * 1e9),
          dont_parse_links: 1,
        });
      } catch (e) {
        console.error('[vk-callback] messages.send:', e.message);
      }
    }
  }

  res.send('ok');
});

// ------------------------------------------------------------
// Внутренний endpoint /notify — приходит от tg-bot
// ------------------------------------------------------------
function formatBookingForVK(record) {
  const contactLabel = {
    telegram: 'Telegram',
    vk: 'VK',
    email: 'Email',
    phone: 'Телефон',
  }[record.contact_method?.value || record.contact_method] || (record.contact_method?.value || record.contact_method);

  const sourceLabel = {
    tg_miniapp: 'из Telegram',
    vk_miniapp: 'из VK',
    website: 'с сайта',
  }[record.source?.value || record.source] || (record.source?.value || record.source);

  return [
    'Новая запись на знакомство',
    '',
    `Дата: ${record.slot_date} в ${record.slot_time} (${record.duration_min} мин)`,
    `Имя: ${record.name}`,
    `${contactLabel}: ${record.contact_value}`,
    record.message ? `Сообщение: ${record.message}` : null,
    '',
    `Источник: ${sourceLabel}`,
    `ID: ${record.id}`,
  ].filter(Boolean).join('\n');
}

app.post('/notify', async (req, res) => {
  const auth = req.headers['authorization'] || '';
  if (auth !== `Bearer ${NOTIFY_SECRET}`) {
    return res.status(401).json({ ok: false, error: 'unauthorized' });
  }

  const record = req.body?.record;
  if (!record || !record.id) {
    return res.status(400).json({ ok: false, error: 'no record' });
  }

  try {
    await vk.api.messages.send({
      user_id: Number(VK_OWNER_USER_ID),
      message: formatBookingForVK(record),
      random_id: Math.floor(Math.random() * 1e9),
      dont_parse_links: 1,
    });
    console.log(`[notify] vk → owner ok, booking=${record.id}`);
    res.json({ ok: true });
  } catch (e) {
    console.error('[notify] vk send:', e.message);
    res.json({ ok: false, error: e.message });
  }
});

app.listen(PORT, () => {
  console.log(`[vk-bot] HTTP listening on :${PORT}, group=${VK_GROUP_ID}, owner=${VK_OWNER_USER_ID}`);
});

process.on('SIGTERM', () => {
  console.log('[vk-bot] SIGTERM, exiting');
  process.exit(0);
});
