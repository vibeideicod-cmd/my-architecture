# Beauty TMA — Дорожная карта разработки

**Продукт:** Клиентская витрина-каталог бьюти-мастера в Telegram Mini App
**Бизнес-модель:** SaaS — мастер подключается по подписке, клиенты пользуются бесплатно
**Документ:** Дорожная карта для кодера. Полный технический бриф — `brief-beauty-tma.md`
**Дата:** апрель 2026

---

## ЧТО МЫ СТРОИМ

Telegram Mini App, который открывается по ссылке вида:
```
https://t.me/BotName/app?startapp=master_abc123
```

Клиент мастера нажимает → TMA открывается прямо внутри Telegram → видит каталог услуг → записывается.
Никаких браузеров, никаких отдельных приложений. Всё внутри Telegram.

---

## ДИЗАЙН-ПРИНЦИПЫ

| Принцип | Как реализуем |
|---|---|
| Native Look & Feel | Только CSS-переменные Telegram (`--tg-theme-*`), никаких жёстких цветов |
| Эргономика | Минимум 44px на любой кнопке или нажимаемом элементе |
| Визуал | Фото на первом плане, текст — короткий и ёмкий |
| Плавность | Skeleton-экраны при загрузке, CSS transitions между состояниями |
| Язык | Русский |

---

## СТРУКТУРА ЭКРАНОВ (User Journey)

### Экран 1 — Главная (Витрина)

**Что видит клиент:**
- Аватар мастера — круг 80×80px
- Имя + специализация — "Анна · Мастер маникюра · Москва"
- Биография — максимум 2 строки, с кнопкой развернуть если длиннее
- Плитка категорий — 2 колонки, карточки с фоновым фото + название поверх
- Кнопка "Мои записи" — строка-ссылка под категориями (в MVP просто ведёт на Экран 5 с последней записью)

**Что нажимают:**
- Карточка категории → Экран 2
- "Мои записи" → просмотр последней записи (MVP: только одна)

**Telegram API:**
- `tg.expand()` — раскрыть TMA на весь экран
- `tg.MainButton.hide()` — на главной MainButton скрыта
- `tg.BackButton.hide()` — на главной BackButton скрыта

---

### Экран 2 — Список услуг в категории

**Что видит клиент:**
- Название категории вверху — "Маникюр", `font-size: 22px`, жирный
- Вертикальный список карточек услуг

Каждая карточка (высота 80px):
```
[ Фото 72×72 ] Название услуги (жирный)
               от 1 500 ₽ · 60 мин
                                    ›
```
- Серая плашка под именем — длительность и цена "от"
- Chevron (›) справа — сигнал о переходе
- Вся карточка кликабельна

**Что нажимают:**
- Карточка услуги → Экран 3
- BackButton (Telegram) → Экран 1

**Telegram API:**
- `tg.BackButton.show()` — показываем при входе на экран
- `tg.BackButton.onClick(() => showScreen('main'))` — возврат

**Загрузка:**
Skeleton-карточки (3 штуки) пока список не пришёл с сервера.

---

### Экран 3 — Карточка услуги (детально)

**Что видит клиент:**
- Галерея работ — горизонтальный слайдер 3–5 фото, `aspect-ratio: 4/3`
  - Индикатор слайдера — точки внизу галереи
  - Tap на фото → полноэкранный просмотр с pinch-to-zoom + swipe-to-close
- Название услуги — под галереей, крупно
- Цена — жирный, акцентным цветом
- Длительность — иконка часов + "60 мин"
- Описание — первые 3 строки видны, дальше "Читать полностью ↓" (разворачивается)

**Что нажимают:**
- Фото в галерее → полноэкранный просмотр (overlay)
- "Читать полностью" → раскрыть описание inline
- MainButton "Выбрать время" → Экран 4
- BackButton → Экран 2

**Telegram API:**
- `tg.MainButton.setText('Выбрать время')`
- `tg.MainButton.show()` и `tg.MainButton.enable()`
- При открытии полноэкранного фото: `tg.MainButton.hide()` + `tg.BackButton.hide()`
- При закрытии фото: вернуть обе кнопки

---

### Экран 4 — Бронирование (Дата и Время)

**Что видит клиент:**

**Выбор даты — горизонтальный скролл:**
- 14 дней вперёд, каждый день — таблетка с названием дня ("Пн") и числом ("16")
- Сегодня — метка "Сегодня" вместо названия дня
- Выходные мастера — серые, нельзя нажать
- Выбранный день — заливка акцентным цветом

**Выбор слота — сетка:**
- После выбора дня — сетка 4 колонки с временными слотами `[10:00]`
- Свободные — фон `--tg-theme-secondary-bg-color`
- Занятые — серые, с крестом, нельзя нажать (но видны — показывают что мастер реально работает)
- Выбранный слот — акцентный цвет + рамка

**Что нажимают:**
- День в скролле → загрузить слоты этого дня + сбросить выбор слота
- Свободный слот → выделить + HapticFeedback + активировать MainButton
- MainButton "Подтвердить время" → Экран 5
- BackButton → Экран 3

**Telegram API:**
```javascript
// Выбор слота
tg.HapticFeedback.selectionChanged();     // при выборе слота
tg.HapticFeedback.impactOccurred('light'); // дополнительный импакт

tg.MainButton.setText('Подтвердить время');
tg.MainButton.disable(); // пока слот не выбран
// После выбора слота:
tg.MainButton.enable();
```

---

### Экран 5 — Успех / Резюме записи

**Что видит клиент:**
- Анимация: зелёный круг → галочка (CSS, без библиотек, ~600ms)
- Заголовок: "Вы записаны!"
- Детали записи — карточка:
  - Услуга + цена
  - Дата + время: "Пятница, 16 мая · 14:00"
  - Мастер: мини-аватар + имя
  - Длительность: "Примерно 90 минут"
- Сообщение: "Напоминание придёт в Telegram за 24 часа до визита"
- Ссылка "Добавить в календарь" → Google Calendar deeplink

**Что нажимают:**
- "Добавить в календарь" → открывает ссылку в браузере
- MainButton "Готово" → `tg.close()`
- BackButton — **скрыт** (запись уже создана, нельзя "отменить" через назад)

**Telegram API:**
```javascript
tg.HapticFeedback.notificationOccurred('success');
tg.BackButton.hide();
tg.MainButton.setText('Готово');
tg.MainButton.onClick(() => tg.close());
```

---

## ПЕРЕХОДЫ И ЛОГИКА

### Схема навигации

```
Экран 1 (Главная)
  └─→ Экран 2 (Список услуг)    BackButton → Экран 1
        └─→ Экран 3 (Карточка)  BackButton → Экран 2
              └─→ Экран 4 (Слоты) BackButton → Экран 3
                    └─→ Экран 5 (Успех)    BackButton = скрыт
```

Навигация — SPA без перезагрузки страницы. `show/hide` блоков через CSS + JS, не через роутер.

### MainButton — состояния по экранам

| Экран | Текст | Состояние | Действие |
|---|---|---|---|
| 1. Главная | — | hidden | — |
| 2. Список услуг | — | hidden | — |
| 3. Карточка | "Выбрать время" | enabled | → Экран 4 |
| 4. Слоты | "Подтвердить время" | disabled → enabled | → Экран 5 |
| 5. Успех | "Готово" | enabled | tg.close() |

### BackButton — состояния по экранам

| Экран | Состояние | Действие |
|---|---|---|
| 1. Главная | hidden | — |
| 2. Список услуг | visible | → Экран 1 |
| 3. Карточка | visible | → Экран 2 |
| 4. Слоты | visible | → Экран 3 |
| 5. Успех | hidden | — |

### Haptic Feedback — карта вибраций

| Действие | Метод |
|---|---|
| Tap по категории или услуге | `selectionChanged()` |
| Выбор временного слота | `selectionChanged()` + `impactOccurred('light')` |
| Tap MainButton "Подтвердить" | `impactOccurred('medium')` |
| Запись успешно создана | `notificationOccurred('success')` |
| Ошибка при создании записи | `notificationOccurred('error')` |
| Закрытие полноэкранного фото | `impactOccurred('light')` |

---

## ЧЕГО НЕ БУДЕТ В MVP (v1.0)

### Отложено на v1.1

| Функция | Почему откладываем |
|---|---|
| Онлайн-оплата услуг | Нужен платёжный провайдер + юридическое оформление |
| Личный кабинет клиента с историей | Нужна авторизация и хранение данных клиентов. В MVP — авторизация только по Telegram ID |
| Отмена и перенос записи клиентом | Требует бизнес-логики: депозиты, штрафы, уведомления |
| Отзывы и рейтинги | Нужна модерация |
| Поиск услуг по ключевым словам | Мало смысла при малом каталоге |
| Чат клиент ↔ мастер внутри TMA | Для этого есть сам Telegram |
| Уведомление "запись подтверждена мастером" | В MVP — автоподтверждение |

### Отложено на v2.0

| Функция | Почему |
|---|---|
| Программа лояльности и промокоды | Сложная бизнес-логика |
| Групповые записи (несколько услуг сразу) | Конфликты слотов, сложный UX |
| Мультимастер (несколько сотрудников) | Архитектурные изменения в модели данных |
| Собственный бот на каждого мастера | Только для Premium-тарифа |
| Виджет для сайта / Instagram | Вне экосистемы Telegram |

---

## ПОШАГОВЫЙ ПЛАН РАЗРАБОТКИ

### Этап 0 — Подготовка окружения (день 1)

```bash
# Инициализация проекта
npm create vite@latest beauty-tma -- --template react
cd beauty-tma
npm install

# Структура папок
src/
  screens/       # Экраны (компоненты)
  components/    # Галерея, слот, карточка и т.д.
  api/           # Запросы к серверу
  styles/        # CSS-переменные, базовые стили
```

**Что настраиваем:**
- Vite + React (или чистый JS если без фреймворка)
- CSS-переменные Telegram в `variables.css`
- Базовые стили: сброс, типографика, эргономика (44px)
- `index.html` — подключение Telegram WebApp SDK:
  ```html
  <script src="https://telegram.org/js/telegram-web-app.js"></script>
  ```
- Локальный ngrok для тестирования TMA на телефоне

**Проверка:** TMA открывается в Telegram, `tg.ready()` и `tg.expand()` работают.

---

### Этап 1 — Статичная верстка экранов (день 2–4)

Верстаем все 5 экранов с хардкодными данными. Никакого API, только HTML + CSS.

**Порядок:**
1. Экран 1 — Главная: аватар, плитка категорий
2. Экран 2 — Список услуг: горизонтальные карточки
3. Экран 3 — Карточка услуги: галерея + описание
4. Экран 4 — Слоты: горизонтальный скролл дат + сетка слотов
5. Экран 5 — Успех: анимация галочки + карточка записи

**Навигация:** реализуем show/hide экранов через JS — `showScreen('services')`.

**MainButton и BackButton** — подключаем логику на каждом экране.

**Проверка:** можно пройти весь flow от Главной до Успеха. Всё тестируем на реальном телефоне через Telegram.

---

### Этап 2 — Галерея и UX-фишки (день 5–6)

**Галерея (Экран 3):**
- Горизонтальный touch-слайдер без библиотек (touch events + CSS transform)
- Индикатор-точки
- Полноэкранный просмотр — overlay с pinch-to-zoom
- Swipe-to-close полноэкранного просмотра

**Skeleton-экраны:**
- Компонент `Skeleton` — анимированные плейсхолдеры
- Применить на: список услуг, карточка услуги, слоты

**Haptic Feedback:**
- Подключить на все события по карте из раздела выше

**Анимация успеха (Экран 5):**
- SVG-галочка с CSS stroke-dasharray анимацией
- Длительность ~600ms

**Проверка:** UX ощущается нативно. Нет дёрганий и задержек. Тестируем на iOS и Android.

---

### Этап 3 — API и реальные данные (день 7–9)

**Серверная часть (Express + PostgreSQL):**

```
GET /api/master/:id              → профиль + брендинг
GET /api/master/:id/categories   → категории услуг
GET /api/services/:categoryId    → список услуг категории
GET /api/service/:id             → карточка + фото портфолио
GET /api/slots/:masterId/:date   → свободные слоты (YYYY-MM-DD)
POST /api/bookings               → создать запись
```

**Валидация initData — обязательно:**
```javascript
// На сервере — в middleware перед каждым запросом
function validateInitData(initData, botToken) {
  const params = new URLSearchParams(initData);
  const hash = params.get('hash');
  params.delete('hash');

  const dataCheckString = [...params.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([k, v]) => `${k}=${v}`)
    .join('\n');

  const secretKey = crypto.createHmac('sha256', 'WebAppData')
    .update(botToken).digest();

  const expectedHash = crypto.createHmac('sha256', secretKey)
    .update(dataCheckString).digest('hex');

  if (hash !== expectedHash) throw new Error('Invalid');

  const authDate = parseInt(params.get('auth_date'));
  if (Date.now() / 1000 - authDate > 300) throw new Error('Expired');

  return JSON.parse(params.get('user'));
}
```

**Замена хардкода на реальные запросы:**
- Загрузка профиля мастера из deep link (`start_param`)
- Динамический брендинг мастера (`--accent` из БД)
- Список категорий и услуг с сервера
- Слоты на дату

**Автосохранение черновика в CloudStorage:**
```javascript
tg.CloudStorage.setItem('booking_draft', JSON.stringify({ serviceId, slotId, phone }));
```

**Проверка:** полный flow работает с реальными данными тестового мастера.

---

### Этап 4 — Бот и уведомления (день 10–11)

**Бот (node-telegram-bot-api или Grammy):**

```javascript
// Уведомление мастеру о новой записи
bot.sendMessage(master.telegram_id,
  `📅 Новая запись!\n` +
  `${client.name} · ${service.name}\n` +
  `${formatDate(booking.datetime)}`,
  {
    reply_markup: { inline_keyboard: [[
      { text: '✅ Принять', callback_data: `confirm_${booking.id}` },
      { text: '❌ Отменить', callback_data: `cancel_${booking.id}` }
    ]]}
  }
);

// Напоминание клиенту за 24 часа (cron-job)
cron.schedule('*/15 * * * *', async () => {
  const bookings = await getBookingsIn24Hours();
  for (const b of bookings) {
    await bot.sendMessage(b.client_telegram_id,
      `⏰ Напоминание: завтра в ${b.time} — ${b.service_name} у ${b.master_name}`
    );
    await sleep(50); // rate limit: 20 msg/sec
  }
});
```

**Что реализуем:**
- Уведомление мастеру при новой записи
- Автоподтверждение записи (мастер может отменить)
- Напоминание клиенту за 24 часа и за 2 часа

**Проверка:** мастер получает уведомление сразу. Клиент получает напоминание в нужное время.

---

### Этап 5 — Деплой и тестирование (день 12–14)

**Деплой фронтенда:**
- Сборка: `npm run build` → папка `dist/`
- Хостинг: Vercel или Netlify (автодеплой из GitHub)
- Домен с HTTPS — обязателен для TMA

**Деплой бэкенда:**
- VPS или Railway / Render
- HTTPS с SSL
- Webhook для Telegram бота: `setWebhook(https://yourdomain.com/bot)`

**Подключение TMA к боту:**
```
BotFather → /newapp → указать URL фронтенда
```

**Чеклист перед запуском:**

- [ ] `tg.ready()` и `tg.expand()` при старте
- [ ] initData валидируется на сервере для каждого запроса
- [ ] Все цвета — через `var(--tg-theme-*)`, никаких жёстких hex
- [ ] MainButton и BackButton управляются на каждом экране
- [ ] HapticFeedback на всех действиях
- [ ] Skeleton-экраны при загрузке данных
- [ ] Минимальный tap target 44px (проверить на реальном телефоне)
- [ ] Отступ 80px снизу под MainButton на всех экранах
- [ ] Протестировано в светлой и тёмной теме Telegram
- [ ] Протестировано на iOS и Android

---

## СТЕК ТЕХНОЛОГИЙ

| Слой | Технология | Почему |
|---|---|---|
| Фронтенд | Vite + React | Быстрая сборка, компонентный подход |
| Стили | Чистый CSS + CSS Variables | Нет лишних зависимостей, полный контроль |
| Бэкенд | Node.js + Express | Быстрый старт, легко деплоить |
| База данных | PostgreSQL | Надёжность, транзакции для слотов |
| Кэш / очередь | Redis | Rate limit для Bot API, кэш слотов |
| Бот | Grammy (или node-telegram-bot-api) | Типизация, middleware |
| Деплой фронт | Vercel | Автодеплой, HTTPS, CDN |
| Деплой бэк | Railway или VPS | Простой деплой Node.js + PostgreSQL |
| Cron | node-cron или BullMQ | Напоминания клиентам |

---

## СТРУКТУРА ДАННЫХ (MVP)

```sql
-- Профиль мастера
CREATE TABLE masters (
  id            TEXT PRIMARY KEY,        -- "master_abc123"
  telegram_id   BIGINT UNIQUE,
  name          TEXT,
  bio           TEXT,
  avatar_url    TEXT,
  accent_color  TEXT DEFAULT '#b49fd4',
  city          TEXT,
  subscription_expires_at TIMESTAMPTZ
);

-- Категории услуг
CREATE TABLE categories (
  id        SERIAL PRIMARY KEY,
  master_id TEXT REFERENCES masters(id),
  name      TEXT,                        -- "Маникюр"
  photo_url TEXT,
  position  INTEGER
);

-- Услуги
CREATE TABLE services (
  id          SERIAL PRIMARY KEY,
  category_id INTEGER REFERENCES categories(id),
  master_id   TEXT REFERENCES masters(id),
  name        TEXT,
  description TEXT,
  price_from  INTEGER,                   -- в рублях
  duration    INTEGER,                   -- в минутах
  photos      TEXT[]                     -- массив URL
);

-- Расписание (рабочие дни и часы)
CREATE TABLE schedules (
  id        SERIAL PRIMARY KEY,
  master_id TEXT REFERENCES masters(id),
  day_of_week INTEGER,                   -- 1=Пн, 7=Вс
  start_time TIME,
  end_time   TIME,
  slot_duration INTEGER DEFAULT 30       -- минуты
);

-- Записи
CREATE TABLE bookings (
  id              SERIAL PRIMARY KEY,
  master_id       TEXT REFERENCES masters(id),
  service_id      INTEGER REFERENCES services(id),
  client_telegram_id BIGINT,
  client_name     TEXT,
  client_phone    TEXT,
  datetime        TIMESTAMPTZ,
  duration        INTEGER,
  status          TEXT DEFAULT 'confirmed', -- confirmed / cancelled
  reminded_24h    BOOLEAN DEFAULT FALSE,
  reminded_2h     BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
```

---

## ССЫЛКИ НА СВЯЗАННЫЕ ДОКУМЕНТЫ

- `research-beauty.md` — полное исследование рынка + экспертная оценка
- `brief-beauty-tma.md` — детальный технический бриф (CSS-код, API-схема, компоненты)
