// ============================================================
// Email-провайдер: UniSender Go (РФ, ст.18 ч.5 152-ФЗ ✅)
// ------------------------------------------------------------
// API-документация: https://godocs.unisender.ru/web-api-ref
// Бесплатный план: 1500 писем/мес.
// Адрес отправителя должен быть подтверждён в кабинете
// UniSender Go (домен либо одиночный email).
// ============================================================

const fetch = require('node-fetch');

async function sendViaUnisender({ apiKey, fromEmail, fromName, toEmail, subject, html, text }) {
  // UniSender Go использует POST /transactional/api/v1/email/send.json
  // с заголовком X-API-KEY. Регион: ru1 / ru2 / b1 — берём из URL в кабинете.
  const apiUrl = process.env.UNISENDER_API_URL || 'https://go1.unisender.ru/ru/transactional/api/v1/email/send.json';

  const payload = {
    message: {
      recipients: [{ email: toEmail }],
      body: { html, plaintext: text },
      subject,
      from_email: fromEmail,
      from_name: fromName || 'Календарь Ирины',
    },
  };

  const resp = await fetch(apiUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-KEY': apiKey,
    },
    body: JSON.stringify(payload),
    timeout: 10000,
  });

  if (!resp.ok) {
    const txt = await resp.text();
    throw new Error(`UniSender ${resp.status}: ${txt}`);
  }
  return resp.json();
}

module.exports = { sendViaUnisender };
