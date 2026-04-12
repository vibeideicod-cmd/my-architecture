# BACKEND-PLAN.md — Beauty Визитка SaaS

**Продукт:** Multi-tenant TMA-платформа для бьюти-мастеров
**Бизнес-модель:** Freemium SaaS (мастера платят за подписку, клиенты используют бесплатно)
**Архитектура:** Один бот — много мастеров. Разделение через deep link.
**Дата:** апрель 2026

---

## 1. КОНЦЕПЦИЯ И РОЛИ

### Роли в системе

| Роль | Кто | Что делает |
|---|---|---|
| **client** | Клиент мастера | Смотрит каталог, записывается, отменяет запись |
| **master** | Бьюти-мастер | Настраивает каталог, управляет расписанием, видит записи |
| **owner** | Инна | Видит всех мастеров, управляет подписками, доход |

### Как клиент попадает к мастеру

```
t.me/beauty_vizitka_bot/app?startapp=master_abc123
```

Или прямая ссылка в браузере:
```
https://beauty-tma-app.vercel.app?master=master_abc123
```

Оба варианта читают `master_abc123` и загружают данные конкретного мастера.

### Как мастер управляет своим кабинетом

Отдельный мини-сайт: `https://admin.beauty-vizitka.ru`
(не TMA — веб, потому что удобнее заполнять на десктопе)
Авторизация — через Telegram Login Widget (стандарт, без паролей).

---

## 2. ТАРИФЫ И ОГРАНИЧЕНИЯ

### Тарифная сетка

| Параметр | Бесплатно | Старт (590₽/мес) | Про (1490₽/мес) |
|---|---|---|---|
| Услуг максимум | 5 | 30 | Безлимит |
| Категорий | 1 | 5 | Безлимит |
| Фото на услугу | нет | 3 | 10 |
| Аватар мастера | да | да | да |
| Настройка часов работы | Фиксировано | да | да |
| Отмена записи клиентом | Нельзя | До 24ч | Настраиваемо |
| Цветовая тема (акцент) | По умолчанию | По умолчанию | 6 тем на выбор |
| Уведомления мастеру | да | да | да |
| Напоминания клиентам | нет | да | да |
| Веб-ссылка (вне TG) | нет | да | да |
| Аналитика (кол-во записей) | нет | нет | да |

### Логика freemium в коде

При каждом действии мастера (добавить услугу, загрузить фото) — проверка:
```
checkLimit(master_id, action) → { allowed: bool, reason: string, upgrade_to: 'start' | 'pro' }
```

Если не разрешено — возвращаем 403 с `reason` и `upgrade_to`. Фронт показывает плашку «Разблокировать в тарифе Старт».

---

## 3. БАЗА ДАННЫХ (PostgreSQL)

### Таблица: masters

```sql
CREATE TABLE masters (
  id                 TEXT PRIMARY KEY,          -- 'master_abc123' (slug)
  telegram_id        BIGINT UNIQUE NOT NULL,    -- tg user id
  name               TEXT NOT NULL,
  bio                TEXT,
  avatar_url         TEXT,                      -- Cloudinary URL
  specialty          TEXT,                      -- 'Бьюти-мастер'
  city               TEXT,
  accent_color       TEXT DEFAULT '#b49fd4',    -- hex
  theme_id           INTEGER REFERENCES themes(id),
  status_text        TEXT,                      -- 'Принимаю записи на май'
  cancellation_hours INTEGER DEFAULT 24,        -- за сколько часов можно отменить
  is_active          BOOLEAN DEFAULT TRUE,
  created_at         TIMESTAMPTZ DEFAULT NOW()
);
```

### Таблица: subscriptions

```sql
CREATE TABLE subscriptions (
  id          SERIAL PRIMARY KEY,
  master_id   TEXT REFERENCES masters(id),
  tier        TEXT NOT NULL,                  -- 'free' | 'start' | 'pro'
  started_at  TIMESTAMPTZ DEFAULT NOW(),
  expires_at  TIMESTAMPTZ,                   -- NULL = бессрочно (free)
  paid_amount INTEGER,                       -- в копейках
  payment_id  TEXT,                          -- id из платёжной системы
  status      TEXT DEFAULT 'active'          -- 'active' | 'expired' | 'cancelled'
);
```

### Таблица: categories

```sql
CREATE TABLE categories (
  id          SERIAL PRIMARY KEY,
  master_id   TEXT REFERENCES masters(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  icon        TEXT,                          -- emoji
  photo_url   TEXT,                          -- Cloudinary URL (опционально)
  position    INTEGER DEFAULT 0,             -- порядок в списке
  is_active   BOOLEAN DEFAULT TRUE
);
```

### Таблица: services

```sql
CREATE TABLE services (
  id           SERIAL PRIMARY KEY,
  master_id    TEXT REFERENCES masters(id) ON DELETE CASCADE,
  category_id  INTEGER REFERENCES categories(id),
  name         TEXT NOT NULL,
  description  TEXT,
  price_from   INTEGER NOT NULL,             -- в рублях
  price_exact  BOOLEAN DEFAULT TRUE,         -- false = «от X ₽»
  duration     INTEGER NOT NULL,             -- в минутах
  tags         TEXT[],
  is_active    BOOLEAN DEFAULT TRUE,
  position     INTEGER DEFAULT 0
);
```

### Таблица: service_photos

```sql
CREATE TABLE service_photos (
  id          SERIAL PRIMARY KEY,
  service_id  INTEGER REFERENCES services(id) ON DELETE CASCADE,
  url         TEXT NOT NULL,                 -- Cloudinary URL
  position    INTEGER DEFAULT 0
);
```

### Таблица: schedules (рабочие часы мастера)

```sql
CREATE TABLE schedules (
  id             SERIAL PRIMARY KEY,
  master_id      TEXT REFERENCES masters(id) ON DELETE CASCADE,
  day_of_week    INTEGER NOT NULL,           -- 1=Пн, 7=Вс
  start_time     TIME NOT NULL,              -- '10:00'
  end_time       TIME NOT NULL,              -- '18:00'
  slot_duration  INTEGER DEFAULT 60,         -- минуты
  is_working     BOOLEAN DEFAULT TRUE        -- false = выходной
);
```

### Таблица: bookings

```sql
CREATE TABLE bookings (
  id                  SERIAL PRIMARY KEY,
  master_id           TEXT REFERENCES masters(id),
  service_id          INTEGER REFERENCES services(id),
  client_telegram_id  BIGINT NOT NULL,
  client_name         TEXT,
  client_phone        TEXT,                  -- опционально
  scheduled_at        TIMESTAMPTZ NOT NULL,  -- конкретное время записи
  duration_min        INTEGER NOT NULL,
  status              TEXT DEFAULT 'confirmed', -- confirmed | cancelled | completed
  cancel_reason       TEXT,
  cancelled_by        TEXT,                  -- 'client' | 'master'
  cancelled_at        TIMESTAMPTZ,
  reminded_24h        BOOLEAN DEFAULT FALSE,
  reminded_2h         BOOLEAN DEFAULT FALSE,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);
```

### Таблица: themes (пресеты оформления)

```sql
CREATE TABLE themes (
  id           SERIAL PRIMARY KEY,
  name         TEXT NOT NULL,               -- 'Лаванда', 'Кораллы', 'Мята'
  accent_color TEXT NOT NULL,               -- hex
  preview_url  TEXT                         -- превью для выбора в кабинете
);

INSERT INTO themes (name, accent_color) VALUES
  ('По умолчанию', '#b49fd4'),
  ('Лаванда',      '#9b59b6'),
  ('Кораллы',      '#e06c75'),
  ('Мята',         '#00b894'),
  ('Золото',       '#f39c12'),
  ('Небо',         '#74b9ff');
```

---

## 4. API ENDPOINTS

### Базовый URL: `https://api.beauty-vizitka.ru/v1`

### 4.1 Публичные (без авторизации) — для клиентов

```
GET    /masters/:slug                       → профиль мастера + тема
GET    /masters/:slug/categories            → категории с min_price
GET    /masters/:slug/services/:cat_id      → услуги категории
GET    /masters/:slug/slots?date=YYYY-MM-DD → свободные слоты
POST   /masters/:slug/bookings             → создать запись
DELETE /bookings/:id                       → отменить запись (по telegram_id клиента)
```

**POST /masters/:slug/bookings — тело запроса:**
```json
{
  "service_id": 42,
  "scheduled_at": "2026-05-16T14:00:00",
  "client_telegram_id": 123456789,
  "client_name": "Мария",
  "client_phone": "+79001234567"
}
```

**Логика GET /slots:**
1. Получить расписание мастера на день недели из `schedules`
2. Сгенерировать все слоты (start_time → end_time с шагом slot_duration)
3. Вычесть занятые из `bookings` где `status = 'confirmed'` на этот день
4. Вернуть только свободные
5. Слоты на прошедшее время не возвращать

### 4.2 Мастер-кабинет — заголовок: `Authorization: Bearer <jwt_token>`

```
GET    /admin/me                            → профиль + текущий тариф
PUT    /admin/me                            → обновить профиль
POST   /admin/me/avatar                     → загрузить аватар (multipart/form-data)

GET    /admin/categories
POST   /admin/categories
PUT    /admin/categories/:id
DELETE /admin/categories/:id
PUT    /admin/categories/reorder

GET    /admin/services
POST   /admin/services
PUT    /admin/services/:id
DELETE /admin/services/:id
POST   /admin/services/:id/photos           → загрузить фото
DELETE /admin/services/:id/photos/:photo_id

GET    /admin/schedule
PUT    /admin/schedule                      → массив рабочих дней

GET    /admin/bookings?status=confirmed&from=YYYY-MM-DD&to=YYYY-MM-DD
PUT    /admin/bookings/:id/cancel

GET    /admin/subscription
POST   /admin/subscription/upgrade
```

### 4.3 Платформа Инны — заголовок: `X-Owner-Key: <secret>`

```
GET  /platform/masters
GET  /platform/masters/:id
PUT  /platform/masters/:id/subscription    → ручная активация тарифа
GET  /platform/stats                       → мастеров, записей, доход
```

---

## 5. АВТОРИЗАЦИЯ

### Клиент
Не авторизуется. Идентифицируется по `client_telegram_id` из Telegram `initData`.
При отмене записи — проверяем что `client_telegram_id` совпадает с записью.

### Мастер (Telegram Login Widget)

1. Открывает admin.beauty-vizitka.ru
2. Нажимает «Войти через Telegram»
3. Сервер проверяет подпись (HMAC-SHA256 с bot token)
4. Новый мастер — создаём запись в `masters`, тариф `free`, slug генерируется автоматически
5. Выдаём JWT: `{ master_id, telegram_id, tier }`, TTL 7 дней

### Валидация initData для TMA-запросов

```javascript
// backend/src/middleware/validateInitData.js
function validateInitData(initDataRaw, botToken) {
  const params = new URLSearchParams(initDataRaw);
  const hash = params.get('hash');
  params.delete('hash');
  const dataCheckString = [...params.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([k, v]) => `${k}=${v}`)
    .join('\n');
  const secretKey = crypto.createHmac('sha256', 'WebAppData').update(botToken).digest();
  const expectedHash = crypto.createHmac('sha256', secretKey).update(dataCheckString).digest('hex');
  if (hash !== expectedHash) throw new Error('Invalid initData');
  if (Date.now() / 1000 - parseInt(params.get('auth_date')) > 86400) throw new Error('Expired');
  return JSON.parse(params.get('user'));
}
```

---

## 6. БОТ И УВЕДОМЛЕНИЯ

Библиотека: **Grammy** (`grammy` npm)
Режим: **webhook**, URL: `https://api.beauty-vizitka.ru/bot/webhook`

### Уведомления мастеру (при новой записи)
```
📅 Новая запись!
Мария · Маникюр гель-лак
Пятница, 16 мая · 14:00 (90 мин)
📞 +79001234567

[✅ Принято] [❌ Отменить]
```
Inline кнопки → callback → обновляют `bookings.status`.

### Напоминания клиенту (cron каждые 15 мин)

За 24 часа:
```
⏰ Напоминаем: завтра в 14:00
Маникюр гель-лак у Анна Смирнова
```

За 2 часа:
```
🔔 Через 2 часа запись к Анна Смирнова · 14:00
```

Cron-напоминания: только тарифы `start` и `pro`.

### Уведомление мастеру при отмене клиентом
```
❗️ Отмена записи
Мария отменила запись на 16 мая · 14:00
Услуга: Маникюр гель-лак
```

---

## 7. ХРАНИЛИЩЕ ФОТО

Сервис: **Cloudinary** (бесплатный тир: 25 GB, 25K трансформаций/месяц)

Поток:
1. Мастер загружает фото в admin-кабинете
2. Сервер принимает multipart/form-data
3. Стримит файл в Cloudinary через Node SDK
4. Сохраняет `secure_url` в БД
5. Фронт использует URL напрямую (CDN)

Лимиты по тарифам:
- Free: аватар мастера — да, фото услуг — нет
- Старт: до 3 фото на услугу
- Про: до 10 фото на услугу

---

## 8. АНТИКОНФЛИКТ СЛОТОВ

Проблема: два клиента берут один слот одновременно.

Решение — транзакция PostgreSQL с блокировкой:
```sql
BEGIN;

SELECT id FROM bookings
  WHERE master_id = $1
    AND scheduled_at = $2
    AND status = 'confirmed'
  FOR UPDATE SKIP LOCKED;

-- нашли строку → 409 Conflict, ROLLBACK
-- не нашли    → INSERT, COMMIT

COMMIT;
```

Для масштаба v2: Redis lock на `slot:{master_id}:{datetime}` TTL 30 сек.

---

## 9. TECH STACK

| Слой | Технология | Почему |
|---|---|---|
| API | Node.js + Express | Быстро, знакомо, легко деплоить |
| БД | PostgreSQL | Транзакции, FOR UPDATE |
| Кэш | Redis | Lock слотов, rate limit |
| Бот | Grammy | Middleware, типизация, webhook |
| Фото | Cloudinary | CDN-ссылки, бесплатный тир |
| Cron | node-cron | Напоминания, проверка подписок |
| Фронт клиента | Vanilla JS (tg-app/) | Уже есть, без переписывания |
| Фронт мастера | HTML + CSS + JS (admin/) | Простой кабинет |
| Деплой API | Railway или VPS | PostgreSQL + Node в одном месте |
| Деплой фронт | Vercel | Уже настроен, автодеплой |

---

## 10. СТРУКТУРА ПАПОК

```
my-architecture/
├── tg-app/                  ← уже существует (клиентский TMA)
├── admin/                   ← новый (кабинет мастера)
│   └── index.html
├── backend/                 ← новый
│   ├── src/
│   │   ├── routes/
│   │   │   ├── public.js    ← /masters/* (клиенты)
│   │   │   ├── admin.js     ← /admin/* (мастера)
│   │   │   ├── platform.js  ← /platform/* (Инна)
│   │   │   └── bot.js       ← /bot/webhook
│   │   ├── middleware/
│   │   │   ├── auth.js      ← JWT + Telegram Login
│   │   │   └── limits.js    ← проверка лимитов тарифа
│   │   ├── services/
│   │   │   ├── slots.js     ← генерация свободных слотов
│   │   │   ├── notify.js    ← уведомления через бот
│   │   │   ├── photos.js    ← Cloudinary
│   │   │   └── subs.js      ← логика тарифов и лимитов
│   │   ├── db/
│   │   │   ├── pool.js      ← pg Pool
│   │   │   └── migrations/  ← SQL-файлы по разделу 3
│   │   ├── bot/
│   │   │   └── index.js     ← Grammy бот
│   │   └── cron/
│   │       └── reminders.js ← cron-задачи
│   ├── package.json
│   └── .env.example
└── BACKEND-PLAN.md
```

---

## 11. ПОРЯДОК РАЗРАБОТКИ

### Этап 0: Инфраструктура (1 день)
- [ ] Создать `backend/`, `npm init`
- [ ] Установить: `express pg redis grammy cloudinary jsonwebtoken node-cron dotenv multer`
- [ ] PostgreSQL на Railway (или локально через Docker)
- [ ] SQL-миграции из раздела 3
- [ ] `.env` с переменными

### Этап 1: Публичный API — клиентский TMA (2 дня)
- [ ] GET /masters/:slug — профиль мастера
- [ ] GET /masters/:slug/categories
- [ ] GET /masters/:slug/services/:cat_id
- [ ] GET /masters/:slug/slots?date= — реальные данные из schedules + bookings
- [ ] POST /masters/:slug/bookings — транзакция из раздела 8
- [ ] Заменить mock в `tg-app/js/app.js` на fetch к API

### Этап 2: Бот и уведомления (1 день)
- [ ] Grammy webhook
- [ ] Уведомление мастеру при новой записи
- [ ] cron: напоминания за 24ч и 2ч (Старт/Про)
- [ ] Callback: «Принять/Отменить» от мастера

### Этап 3: Admin API — кабинет мастера (2 дня)
- [ ] Telegram Login Widget auth → JWT
- [ ] CRUD: категории, услуги
- [ ] Расписание
- [ ] Загрузка фото → Cloudinary
- [ ] Просмотр своих записей

### Этап 4: Подписки (1 день)
- [ ] `checkLimit` middleware
- [ ] CRUD подписок
- [ ] Ручная активация через /platform/
- [ ] cron: даунгрейд истёкших подписок к free

### Этап 5: Admin-фронт (2 дня)
- [ ] Telegram Login Widget → вход
- [ ] Онбординг: профиль → категории → услуги → расписание → ссылка
- [ ] Dashboard: записи, сводка
- [ ] Управление услугами и фото

---

## 12. ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ

```bash
# Файл: backend/.env.example

DATABASE_URL=postgresql://user:pass@host:5432/beauty_db
REDIS_URL=redis://localhost:6379

BOT_TOKEN=ваш_токен_из_.env

JWT_SECRET=длинная_случайная_строка
JWT_TTL=7d

CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=

OWNER_API_KEY=секретный_ключ_для_инны

FRONTEND_URL=https://beauty-tma-app.vercel.app
ADMIN_URL=https://admin.beauty-vizitka.ru
API_URL=https://api.beauty-vizitka.ru
WEBHOOK_PATH=/bot/webhook
```

---

## 13. ОНБОРДИНГ МАСТЕРА (6 шагов)

```
Шаг 1: Войди через Telegram
Шаг 2: Заполни профиль — имя, специализация, город, bio, аватар
Шаг 3: Создай первую категорию услуг
Шаг 4: Добавь услуги (на free — до 5)
Шаг 5: Настрой расписание — рабочие дни и часы приёма
Шаг 6: Готово! Вот твоя ссылка для клиентов:
         t.me/beauty_vizitka_bot/app?startapp=master_abc123
```

Попытка добавить 6-ю услугу на free → плашка:
«Вы достигли лимита. Переходи на Старт (590₽/мес) — до 30 услуг»

---

## 14. КАК ВОЗОБНОВИТЬ РАБОТУ В НОВОЙ СЕССИИ CLAUDE

Написать в чат:

> Продолжаем разработку Beauty Визитка SaaS. Прочитай MEMORY.md и BACKEND-PLAN.md и скажи, с чего начнём.

Claude прочитает память и этот план, восстановит контекст и предложит следующий шаг.
