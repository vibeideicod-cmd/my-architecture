// ============================================================
// Email-уведомления о новых записях календаря Ирины Цепаевой
// ------------------------------------------------------------
// HTTP-сервер на VPS Cheerful Marik (порт 3012).
// Принимает POST /notify от tg-bot, шлёт письмо Ирине через
// выбранный РФ-провайдер: UniSender Go или SendPulse.
//
// Выбор провайдера: переменная EMAIL_PROVIDER в .env.
//   - unisender (по умолчанию, проще, 1500 писем/мес бесплатно)
//   - sendpulse (12000 писем/мес бесплатно, OAuth2)
//
// Стек: РФ-only. Никакого Resend.
// ============================================================

require('dotenv').config();

const express = require('express');
const { renderEmailHtml, renderEmailText, renderSubject } = require('./template');
const { sendViaUnisender } = require('./unisender');
const { sendViaSendpulse } = require('./sendpulse');

const {
  EMAIL_PROVIDER = 'unisender',
  IRINA_EMAIL,
  IRINA_NAME = 'Ирина',
  FROM_EMAIL,
  FROM_NAME = 'Календарь Ирины',
  PORT = 3012,
  NOTIFY_SECRET,

  // UniSender Go
  UNISENDER_API_KEY,

  // SendPulse
  SENDPULSE_CLIENT_ID,
  SENDPULSE_CLIENT_SECRET,
} = process.env;

if (!IRINA_EMAIL || !FROM_EMAIL || !NOTIFY_SECRET) {
  console.error('[fatal] не заполнен .env (IRINA_EMAIL / FROM_EMAIL / NOTIFY_SECRET)');
  process.exit(1);
}
if (EMAIL_PROVIDER === 'unisender' && !UNISENDER_API_KEY) {
  console.error('[fatal] EMAIL_PROVIDER=unisender, но не заполнен UNISENDER_API_KEY');
  process.exit(1);
}
if (EMAIL_PROVIDER === 'sendpulse' && (!SENDPULSE_CLIENT_ID || !SENDPULSE_CLIENT_SECRET)) {
  console.error('[fatal] EMAIL_PROVIDER=sendpulse, но не заполнены SENDPULSE_CLIENT_ID / SENDPULSE_CLIENT_SECRET');
  process.exit(1);
}

async function sendBookingEmail(booking) {
  const subject = renderSubject(booking);
  const html = renderEmailHtml(booking);
  const text = renderEmailText(booking);

  if (EMAIL_PROVIDER === 'unisender') {
    return sendViaUnisender({
      apiKey: UNISENDER_API_KEY,
      fromEmail: FROM_EMAIL,
      fromName: FROM_NAME,
      toEmail: IRINA_EMAIL,
      subject, html, text,
    });
  }
  if (EMAIL_PROVIDER === 'sendpulse') {
    return sendViaSendpulse({
      clientId: SENDPULSE_CLIENT_ID,
      clientSecret: SENDPULSE_CLIENT_SECRET,
      fromEmail: FROM_EMAIL,
      fromName: FROM_NAME,
      toEmail: IRINA_EMAIL,
      toName: IRINA_NAME,
      subject, html, text,
    });
  }
  throw new Error(`Неизвестный EMAIL_PROVIDER: ${EMAIL_PROVIDER}`);
}

const app = express();
app.use(express.json({ limit: '64kb' }));

app.get('/health', (req, res) => res.json({
  ok: true,
  service: 'email',
  provider: EMAIL_PROVIDER,
  ts: Date.now(),
}));

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
    const result = await sendBookingEmail(record);
    console.log(`[notify] email (${EMAIL_PROVIDER}) → ${IRINA_EMAIL} ok, booking=${record.id}`);
    res.json({ ok: true, provider: EMAIL_PROVIDER, result });
  } catch (e) {
    console.error('[notify] email send:', e.message);
    res.json({ ok: false, error: e.message });
  }
});

app.listen(PORT, () => {
  console.log(`[email] HTTP listening on :${PORT}, provider=${EMAIL_PROVIDER}, to=${IRINA_EMAIL}, from=${FROM_EMAIL}`);
});

process.on('SIGTERM', () => {
  console.log('[email] SIGTERM, exiting');
  process.exit(0);
});

module.exports = { sendBookingEmail };
