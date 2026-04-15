# Beauty SaaS — архитектура v2 (multi-tenant, 3 роли, web-first)

> **Статус:** ПРЕДЛОЖЕНИЕ от 2026-04-15. Ожидает подтверждения Инной перед реализацией.
>
> **Референс:** паттерн 3 ролей взят из `clients/mastergroup/` (МГ). Адаптирован под бьюти-специфику.
>
> **Порядок запуска:** сначала веб полностью, потом Telegram Mini App (как ЮБ рюкзак — [yuzhnoberezhniy/mvp/ryukzak.html](../yuzhnoberezhniy/mvp/ryukzak.html) + [yuzhnoberezhniy/tg-app/index.html](../yuzhnoberezhniy/tg-app/index.html)).

---

## 1. Три роли × два канала — матрица экранов

| Роль | Что видит и делает | Веб (первым) | Telegram (потом) |
|---|---|---|---|
| 🌐 **Гость** | Узнаёт что такое Beauty, решает «Я мастер» или «Я клиент» | `landing.html` | общий бот `@beauty_vizitka_bot` |
| 👩‍🎨 **Мастер (заявка)** | Подаёт анкету, сохраняет токен, ждёт одобрения | `apply.html` → `status.html?t=…` | — (заявки только через веб) |
| 👩‍🎨 **Мастер (работает)** | Редактирует профиль, услуги, расписание, смотрит свои брони | `cabinet.html?m=<slug>&t=<token>` | позже — `tg-app-cabinet/` |
| 📅 **Клиент мастера** | Смотрит витрину мастера, выбирает услугу, записывается | `master.html?m=<slug>` | уже есть — `tg-app/` (адаптируем) |
| 👑 **Инна (админ)** | Модерирует заявки, видит всех мастеров, статистику | `admin.html` (SHA-256 gate) | — (админка только веб) |

**Ключевой принцип (из МГ):** каждая роль — **отдельный HTML-файл**, а не один SPA с переключением режимов. Это проще, надёжнее и легче поддерживать.

**Гейтинг доступа:**
- **Мастер** → токен в URL (`?t=<token>`), хэш проверяется на сервере через RPC
- **Клиент** → без гейта, публичная страница
- **Инна** → SHA-256 хэш пароля в окошке (как в МГ `admin.html`)

---

## 2. База данных — что добавить

Существующая схема ([миграции 001-005](supabase/migrations/)) уже почти готова — `masters`, `categories`, `services`, `schedules`, `bookings` есть. Нужно **добавить**:

### Миграция 006 — заявки мастеров и токены

```
beauty_applications
├── id            bigserial PK
├── name          text       — ФИО
├── city          text
├── specialty     text       — что делает (маникюр, брови, …)
├── telegram      text       — @ник
├── phone         text
├── portfolio_url text       — ссылка на портфолио (опционально)
├── about         text       — о себе
├── agreed_pd     bool       — согласие на ПД
├── status        text       — 'pending' | 'approved' | 'rejected'
├── master_slug   text       — присваивается при одобрении (ссылка на masters.id)
├── token_hash    text       — SHA-256(plain_token), хранится только хэш
├── created_at    timestamptz
├── moderated_at  timestamptz
└── moderator_note text
```

И колонку в существующую таблицу:

```sql
alter table masters add column token_hash text;
```

### Миграция 007 — RPC функции (security definer, как в МГ)

| Функция | Кто вызывает | Что делает |
|---|---|---|
| `beauty_submit_application(data)` | `apply.html` | вставляет заявку, возвращает `{token, app_id}`. Plain token показывается один раз мастеру. |
| `beauty_application_status(token)` | `status.html` | по SHA-256(token) возвращает статус заявки + master_slug если одобрено |
| `beauty_moderate_application(admin_hash, app_id, decision)` | `admin.html` | создаёт запись в `masters` с этим token_hash, меняет статус заявки, возвращает slug |
| `beauty_save_profile(slug, token, data)` | `cabinet.html` | UPDATE masters (name, bio, avatar_url, accent, city) — только при совпадении token_hash |
| `beauty_save_category(slug, token, cat_data)` | `cabinet.html` | INSERT/UPDATE categories |
| `beauty_save_service(slug, token, svc_data)` | `cabinet.html` | INSERT/UPDATE services |
| `beauty_save_schedule(slug, token, schedule)` | `cabinet.html` | UPSERT schedules (7 дней недели) |
| `beauty_list_bookings(slug, token)` | `cabinet.html` | SELECT bookings для мастера (с именами и телефонами клиенток — мастеру это нужно видеть) |
| `beauty_list_applications(admin_hash)` | `admin.html` | SELECT все заявки для модерации |
| `beauty_list_masters(admin_hash)` | `admin.html` | SELECT все мастера для админки |

**Существующая функция** `get_available_slots` (миграция 005) остаётся как есть — она и так работает без токена, это публичный endpoint для клиентов.

**Существующая RLS policy** `public_create_bookings` (миграция 002) остаётся — клиент делает INSERT в bookings напрямую через anon-key.

### Что НЕ надо делать сейчас

- ❌ Supabase Auth — не нужно, хэши токенов проще и достаточно для MVP (как в МГ)
- ❌ Платежи ЮKassa — отложено, «Вариант Б» parked
- ❌ Тарифы Free/Pro — отложено
- ❌ Темы оформления — отложено
- ❌ Свой бот у каждого мастера — отложено, пока один общий `@beauty_vizitka_bot`

---

## 3. Визуальное направление (по правилу из `agents/websites.md`)

**Архетип:** **Soft / Pastel** — бьюти-аудитория, женская ЦА, нейтральная эстетика без агрессии.

**Обоснование:** бьюти-индустрия = ухоженность, расслабление, эстетика. Pastel + рukarounded + generous whitespace создают ощущение спокойного премиум-салона. Контрастные максималистские или брутальные варианты отпугнут ЦА.

**Палитра:**
- Фон: тёплый off-white `#faf7f3` (не чистый белый — слишком «больничный»)
- Акцент мастера: лаванда `#b49fd4` (дефолтный цвет Анны из схемы) — каждый мастер может иметь свой
- Текст: тёмно-серый `#4c4651` (из брендбука)
- Второстепенный акцент: мятный `#a8d5ba` или персиковый `#f2c5a5` (зависит от мастера)

**Шрифты:**
- Display: **Fraunces** (Google Fonts) — serif с характером, soft curves, ощущение premium beauty
- Body: **Manrope** (Google Fonts) — чистый sans-serif, отлично читается

**Техники из [knowledge/standards/visual-techniques.md](../../knowledge/standards/visual-techniques.md):**
- Gradient mesh с лавандой + персиком как фон
- Layered transparencies для карточек (glassmorphism в умеренных дозах)
- Soft shadows (не dramatic — мы в soft-архетипе)
- Page-load orchestration для плавного появления

**Запреты:** никаких Inter/Roboto, фиолетовых градиентов на белом, дефолтных 3-колонок, `box-shadow` с серым дефолтом — всё по [чёрному списку design-system.md](../../knowledge/standards/design-system.md).

---

## 4. План реализации — этапы

### Этап 1 — Фундамент (1-2 сессии) ← СТАРТУЕМ С ЭТОГО

1.1. ✅ Этот документ (план)
1.2. Миграция 006 — таблица `beauty_applications` + колонка `token_hash`
1.3. Миграция 007 — RPC-функции (security definer)
1.4. `landing.html` — главная страница проекта «что такое Beauty, стать мастером / найти мастера»
1.5. `apply.html` — форма анкеты мастера, отправка → `beauty_submit_application`, показ токена
1.6. `status.html?t=<token>` — проверка статуса по токену

**Deliverable:** мастер может подать заявку через веб и проверить статус. Ты (Инна) как админ пока модерируешь через Supabase Table Editor вручную.

### Этап 2 — Кабинет мастера (1-2 сессии)

2.1. `admin.html` с SHA-256 gate — модерация заявок одной кнопкой
2.2. `cabinet.html?m=<slug>&t=<token>` — профиль мастера (имя, био, аватар, цвет)
2.3. `cabinet.html` — экран «Мои услуги» (CRUD через RPC)
2.4. `cabinet.html` — экран «Моё расписание» (UPSERT 7 дней)
2.5. `cabinet.html` — экран «Мои брони» (list с именами клиенток)

**Deliverable:** полный self-serve цикл. Мастер с улицы → заявка → одобрение → кабинет → настраивает свою страницу → готов принимать клиентов.

### Этап 3 — Публичная витрина мастера (1 сессия)

3.1. `master.html?m=<slug>` — адаптация текущего `tg-app/` под обычный браузер (без Telegram SDK)
3.2. Используем ту же логику `bootstrapData`, `getAvailableSlots`, `createBooking`, но без `tg.*` обёрток
3.3. Соблюдаем soft/pastel архетип

**Deliverable:** клиент открывает `beauty.inir.ru/master.html?m=anna` и записывается к Анне. Без Telegram. Ссылку можно кидать в Instagram, визитки, любую соцсеть.

### Этап 4 — Telegram Mini App версия (1 сессия)

4.1. Текущий `tg-app/` переименовываем в клиентскую часть (витрина, бронирование) — он уже готов
4.2. По желанию: `tg-app-cabinet/` — кабинет мастера в TG (дубль `cabinet.html` с TG SDK)
4.3. Deep-link роутинг в боте: `?startapp=anna` → витрина Анны, `?startapp=cabinet:anna:<token>` → кабинет Анны

**Deliverable:** клиент может открыть витрину и через Telegram, и через браузер — одна и та же ссылка-слаг.

### Этап 5 — Деплой на Beget (финальный)

5.1. Мигрируем всё с Vercel на Beget (shared для веб, VPS Cheerful Marik для будущих server-functions если понадобится)
5.2. Кастомный домен (какой? `beauty.inir.ru`? `beauty-visitka.ru`? — решение от Инны)
5.3. Деплой-скрипт `deploy-beauty.sh`

---

## 5. Что происходит с текущим `tg-app/`

**Он НЕ выкидывается.** Текущая TMA — это **клиентская витрина в Telegram**. В новой архитектуре:

- **Сейчас:** `tg-app/` = один мастер (Анна), открывается через `?startapp=anna`
- **После Этапа 3-4:** `tg-app/` = клиентская витрина ЛЮБОГО мастера, slug из `?startapp=<slug>`, эквивалент `master.html?m=<slug>` в вебе

Всю проделанную сегодня работу (подключение к Supabase, RPC слотов, реальный INSERT брони) **сохраняем полностью** — она нужна и в вебе, и в TG. Просто переиспользуем код.

---

## 6. Что мне нужно от Инны перед стартом

1. **Подтверждение архитектуры** — ок, идём этим путём?
2. **Имя домена** — `beauty.inir.ru`? `beauty-visitka.ru`? (нужно для deploy в Этап 5, пока не критично)
3. **Админ-пароль** — придумай строку, я её SHA-256-хэшну и зашью в admin.html. Можно потом менять миграцией.
4. **Первым делом Этап 1** — начинаем с миграций + landing + apply + status. Подтверждаешь?
5. **Архетип soft/pastel + Fraunces/Manrope** — утверждаешь визуальное направление? Или хочешь другое?

---

## 7. Оценка времени

| Этап | Реалистично |
|---|---|
| Этап 1 — Фундамент (миграции + 3 HTML) | 1-2 сессии |
| Этап 2 — Кабинет мастера | 2 сессии |
| Этап 3 — Публичная витрина на вебе | 1 сессия |
| Этап 4 — Telegram Mini App версия | 1 сессия |
| Этап 5 — Деплой | 0.5 сессии |
| **Итого** | **~5-7 сессий** |

Это реальная оценка. Не «за один раз», не «за полчаса». Multi-tenant SaaS — это много работы даже на Supabase.
