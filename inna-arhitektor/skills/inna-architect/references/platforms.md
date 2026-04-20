# references/platforms.md

Все 3 платформы (browser / tma / vk) — это **один источник контента, три разных обёртки**. Общая часть — HTML-шаблон посадочной. Отличия — только в init-блоке и в форме гейта.

## Браузер (`templates/browser.html`)

**Базовый шаблон**, от которого производятся остальные.

- Никаких SDK
- Форма гейта — классическая: 1 input с переключалкой «TG username» / «email»
- CTA-кнопка — inline в карточке конструктора
- Сабмит → Supabase insert + TG-webhook уведомление + download HTML файла в браузере (Blob + URL.createObjectURL)

## Telegram Mini App (`templates/tma.html`)

**Основан на browser.html + поверх:**

1. **Скрипт TG SDK** (в `<head>`):
```html
<script src="https://telegram.org/js/telegram-web-app.js"></script>
```

2. **Init-блок** (сразу после `<body>`):
```js
const tg = window.Telegram?.WebApp;
if (tg) {
  tg.ready();
  tg.expand();
  tg.setHeaderColor('#103206');  // под нашу палитру
  tg.setBackgroundColor('#103206');
}
```

3. **Префилл контакта** (удаляем форму гейта, используем TG-контакт):
```js
if (tg?.initDataUnsafe?.user) {
  const user = tg.initDataUnsafe.user;
  // Запоминаем username/id — не требуем ввода
  window.__tgContact = {
    username: user.username,
    id: user.id,
    first_name: user.first_name
  };
}
```

Когда посетитель нажимает «Забрать готовое» — показываем одну кнопку подтверждения «Да, я @{{username}}» вместо формы. Уменьшает барьер с 2 действий до 1.

4. **MainButton вместо inline-кнопки** (опционально для премиального ощущения):
```js
tg.MainButton.setText('Забрать готовое');
tg.MainButton.show();
tg.MainButton.onClick(() => { /* trigger same flow */ });
```

Показываем MainButton только когда все 3 обязательных поля формы заполнены.

5. **Haptic feedback** на submit:
```js
tg.HapticFeedback?.notificationOccurred('success');
```

## VK Mini App (`templates/vk.html`) — v1.1, пустая заготовка

Для текущего v1: файл содержит только комментарий-заглушку:

```html
<!DOCTYPE html>
<html lang="ru"><head><meta charset="utf-8"><title>Инна Архитектор — VK Mini App</title></head>
<body>
<!-- TBD v1.1: VK Mini App версия. См. research.md раздел «VK Mini App — quick-start». -->
<!-- Будет: VK Bridge init + VKWebAppGetEmail для нативного гейта без формы -->
</body></html>
```

Когда запустим v1.1:
1. Подключить VK Bridge CDN: `<script src="https://unpkg.com/@vkontakte/vk-bridge/dist/browser.min.js"></script>`
2. `vkBridge.send('VKWebAppInit')`
3. Заменить форму гейта на вызов `vkBridge.send('VKWebAppGetEmail')` — нативная модалка VK, одно нажатие
4. Манифест — настраиваем в `vk.com/editapp?act=create`, не файлом в репо

## Что общее для всех 3

- **Supabase insert** одинаков. Таблица `inna_leads` с колонками: `id, created_at, platform, visitor_name, visitor_role, visitor_achievement, visitor_audience, visitor_contact, tg_username, vk_id, user_agent`.
- **TG-webhook** Инне одинаков — простой POST в `/bot<TOKEN>/sendMessage`, сообщение формата:
  > Новый лид: {name} — {role}. Контакт: {contact}. Платформа: {platform}.
- **Превью-логика** одинакова — клиентский JS, debounce 300ms, обновление DOM.
