// ============================================================
// Email-провайдер: SendPulse (РФ, ст.18 ч.5 152-ФЗ ✅)
// ------------------------------------------------------------
// API-документация: https://sendpulse.com/integrations/api
// Бесплатный план SMTP: 12000 писем/мес.
// Адрес отправителя должен быть подтверждён в кабинете SendPulse.
// Аутентификация — OAuth2: получаем access_token и кэшируем его
// до истечения (обычно 1 час).
// ============================================================

const fetch = require('node-fetch');

let cachedToken = null;
let cachedTokenExp = 0;

async function getAccessToken({ clientId, clientSecret }) {
  if (cachedToken && Date.now() < cachedTokenExp - 60_000) return cachedToken;

  const resp = await fetch('https://api.sendpulse.com/oauth/access_token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      grant_type: 'client_credentials',
      client_id: clientId,
      client_secret: clientSecret,
    }),
    timeout: 10000,
  });
  if (!resp.ok) {
    throw new Error(`SendPulse OAuth ${resp.status}: ${await resp.text()}`);
  }
  const data = await resp.json();
  cachedToken = data.access_token;
  cachedTokenExp = Date.now() + Number(data.expires_in || 3600) * 1000;
  return cachedToken;
}

async function sendViaSendpulse({ clientId, clientSecret, fromEmail, fromName, toEmail, toName, subject, html, text }) {
  const token = await getAccessToken({ clientId, clientSecret });

  // SendPulse SMTP API ожидает html в base64
  const htmlB64 = Buffer.from(html, 'utf8').toString('base64');

  const payload = {
    email: {
      html: htmlB64,
      text,
      subject,
      from: { name: fromName || 'Календарь Ирины', email: fromEmail },
      to: [{ name: toName || '', email: toEmail }],
    },
  };

  const resp = await fetch('https://api.sendpulse.com/smtp/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
    timeout: 10000,
  });
  if (!resp.ok) {
    throw new Error(`SendPulse send ${resp.status}: ${await resp.text()}`);
  }
  return resp.json();
}

module.exports = { sendViaSendpulse };
