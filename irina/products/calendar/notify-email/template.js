// ============================================================
// HTML/text шаблон письма «Новая запись на знакомство»
// Палитра Ирины: хвоя #306654, коралл #FF935E, ваниль #FCFAE1.
// Тон: тёплый, словарь Ирины («бесплатное знакомство»,
// «обсудить проект»). НЕ канцелярский.
// ============================================================

function escape(s) {
  return String(s ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function fieldValue(v) {
  // Baserow Single select возвращает { id, value, color } — берём value.
  if (v && typeof v === 'object' && 'value' in v) return v.value;
  return v;
}

function renderEmailHtml(b) {
  const cm = fieldValue(b.contact_method);
  const src = fieldValue(b.source);
  const contactLabel = {
    telegram: 'Telegram',
    vk: 'VK',
    email: 'Email',
    phone: 'Телефон',
  }[cm] || cm;

  const sourceLabel = {
    tg_miniapp: 'из Telegram Mini App',
    vk_miniapp: 'из VK Mini App',
    website: 'с сайта',
  }[src] || src;

  return `<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<title>Новая запись на знакомство</title>
</head>
<body style="margin:0;padding:0;background:#FCFAE1;font-family:'Helvetica Neue',Arial,sans-serif;color:#306654;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#FCFAE1;padding:32px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="560" cellpadding="0" cellspacing="0" style="max-width:560px;background:#ffffff;border-radius:16px;border:1px solid #30665422;overflow:hidden;">
          <tr>
            <td style="background:#306654;color:#FCFAE1;padding:24px 28px;">
              <div style="font-size:13px;letter-spacing:0.08em;text-transform:uppercase;opacity:0.85;">Студия Ирины Цепаевой</div>
              <div style="font-size:22px;font-weight:600;margin-top:6px;">Новая запись на знакомство</div>
            </td>
          </tr>
          <tr>
            <td style="padding:28px;">
              <p style="margin:0 0 16px;font-size:16px;line-height:1.55;color:#306654;">
                Здравствуйте, Ирина! У вас новая запись — клиент выбрал слот сам.
              </p>

              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:8px 0 20px;border-collapse:collapse;">
                <tr>
                  <td style="padding:10px 0;border-bottom:1px solid #30665422;font-size:14px;color:#30665499;width:40%;">Дата и время</td>
                  <td style="padding:10px 0;border-bottom:1px solid #30665422;font-size:16px;color:#306654;font-weight:600;">
                    ${escape(b.slot_date)} · ${escape(b.slot_time)} <span style="color:#FF935E;">(${escape(b.duration_min)} мин)</span>
                  </td>
                </tr>
                <tr>
                  <td style="padding:10px 0;border-bottom:1px solid #30665422;font-size:14px;color:#30665499;">Имя</td>
                  <td style="padding:10px 0;border-bottom:1px solid #30665422;font-size:16px;color:#306654;font-weight:600;">${escape(b.name)}</td>
                </tr>
                <tr>
                  <td style="padding:10px 0;border-bottom:1px solid #30665422;font-size:14px;color:#30665499;">${escape(contactLabel)}</td>
                  <td style="padding:10px 0;border-bottom:1px solid #30665422;font-size:16px;color:#306654;font-weight:600;">${escape(b.contact_value)}</td>
                </tr>
                ${b.message ? `
                <tr>
                  <td style="padding:10px 0;border-bottom:1px solid #30665422;font-size:14px;color:#30665499;vertical-align:top;">Сообщение</td>
                  <td style="padding:10px 0;border-bottom:1px solid #30665422;font-size:15px;color:#306654;line-height:1.5;">${escape(b.message)}</td>
                </tr>` : ''}
                <tr>
                  <td style="padding:10px 0;font-size:14px;color:#30665499;">Источник</td>
                  <td style="padding:10px 0;font-size:14px;color:#306654;">${escape(sourceLabel)}</td>
                </tr>
              </table>

              <div style="background:#FCFAE1;border-left:3px solid #FF935E;padding:14px 16px;border-radius:6px;font-size:14px;line-height:1.55;color:#306654;">
                Это автоматическое письмо от вашего календаря записи. Ответьте клиенту в выбранном им канале — это подтвердит встречу.
              </div>

              <p style="margin:24px 0 0;font-size:12px;color:#30665477;">ID заявки: ${escape(b.id)}</p>
            </td>
          </tr>
          <tr>
            <td style="background:#FCFAE1;padding:16px 28px;border-top:1px solid #30665422;font-size:12px;color:#30665499;text-align:center;">
              Студия Ирины Цепаевой · самозанятая · палитра: хвоя · ваниль · коралл
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

function renderEmailText(b) {
  const cm = fieldValue(b.contact_method);
  const src = fieldValue(b.source);
  return [
    'Новая запись на знакомство',
    '',
    `Дата: ${b.slot_date} в ${b.slot_time} (${b.duration_min} мин)`,
    `Имя: ${b.name}`,
    `${cm}: ${b.contact_value}`,
    b.message ? `Сообщение: ${b.message}` : null,
    '',
    `Источник: ${src}`,
    `ID: ${b.id}`,
  ].filter(Boolean).join('\n');
}

function renderSubject(b) {
  return `Новая запись · ${b.slot_date} в ${b.slot_time} · ${b.name}`;
}

module.exports = { renderEmailHtml, renderEmailText, renderSubject };
