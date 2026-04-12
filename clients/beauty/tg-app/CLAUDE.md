# Beauty TMA — Документация проекта

Telegram Mini App для бьюти-мастера: каталог услуг + онлайн-запись.
Стек: HTML + CSS + Vanilla JS, без фреймворков.

---

## Структура файлов

```
tg-app/
├── index.html        — точка входа, все 6 экранов внутри
├── css/
│   └── style.css     — все стили, CSS-переменные Telegram
├── js/
│   ├── data.js       — mock-данные, утилиты дат и форматирования
│   └── app.js        — вся логика, навигация, TG SDK
├── img/              — изображения (создать при деплое)
│   ├── avatar.jpg    — фото мастера
│   └── svc/          — фото услуг
└── CLAUDE.md         — этот файл
```

---

## Архитектура

### Навигация
Все экраны всегда в DOM. Переключение — CSS-классы `is-active / is-exiting`.
Анимация: fade + slide (translateX 20px, 220ms).
Навигация: `navigate('screen-id')` в `app.js`.

### Экраны (в порядке пользовательского пути)

| ID экрана    | Описание                  |
|--------------|---------------------------|
| `loading`    | Спиннер при инициализации |
| `index`      | Главная — витрина мастера |
| `services`   | Список услуг категории    |
| `details`    | Карточка услуги + галерея |
| `booking`    | Выбор даты и времени      |
| `confirm`    | Подтверждение + телефон   |
| `success`    | Успешная запись           |

### Данные
`data.js` содержит:
- `MASTER` — профиль мастера
- `CATEGORIES` — с `min_price` (ценовой ориентир на главном)
- `SERVICES` — по категориям, с `price_exact: bool`
- `getMockSlots(dateStr)` — только свободные слоты
- `getNextAvailableSlot(dateStr)` — ближайший день со слотами
- Утилиты: `formatPrice`, `formatDuration`, `formatDate`, `getNext14Days`

### Telegram SDK
Вызовы через обёртки в `app.js`:
- `MainButton.show/hide/enable/disable/showProgress`
- `BackButton.show/hide`
- `Haptic.tap/select/success/error`

---

## Ключевые UX-решения (из ../brief.md)

1. **Цена в карточке категории** — `min_price` сразу видна, клиент самофильтруется
2. **Телефон опционален** — запрашиваем, но не блокируем запись без него
3. **Кнопка "Назад в каталог"** на экране успеха — повторная запись без перезапуска TMA
4. **Только свободные слоты** — занятые не показываем, убираем тревогу
5. **Ближайший свободный слот** — если день пуст, подсказка с переходом
6. **price_exact** — точная цена без «от» там, где сумма фиксированная

---

## Деплой на Vercel

```bash
# В корне проекта (my-architecture/)
vercel --cwd clients/beauty/tg-app
```

Или через Vercel Dashboard → Import Git Repository → Root Directory: `clients/beauty/tg-app`

Настройки Vercel:
- Framework Preset: **Other**
- Build Command: _(пусто)_
- Output Directory: `.` (корень tg-app)

После деплоя — вставить URL в BotFather:
`/setmenubutton` → ввести URL → `t.me/BotName/app`

---

## Добавление реального контента

1. Положить `avatar.jpg` в `tg-app/img/`
2. Положить фото услуг в `tg-app/img/svc/`
3. В `js/data.js` обновить объект `MASTER` (имя, city, bio, accent)
4. В `SERVICES` прописать реальные услуги с ценами и путями к фото
5. В `CATEGORIES` обновить иконки при необходимости

---

## Подключение бэкенда (после MVP)

Заменить вызовы в `app.js`:
- `getMockSlots(dateStr)` → `fetch('/api/slots?masterId=X&date=Y')`
- `delay(900)` в `handleConfirmSubmit` → `fetch('/api/bookings', { method: 'POST', ... })`

Добавить валидацию `initData` на сервере (HMAC-SHA256).
