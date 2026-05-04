# П3 · Календарь Ирины · структура таблиц Baserow

> Заменяет старую `schema.sql` (Supabase). Baserow стоит на VPS Cheerful Marik (45.9.41.80, Beget Cloud, РФ) — соответствует ст.18 ч.5 152-ФЗ. Точный URL Baserow Инна подставит сама в `.env` (см. «Открытые вопросы» в README).

---

## Что собираем

Три таблицы в одной базе (workspace «Ирина»):

1. **bookings** — заявки клиентов с полями согласия по 152-ФЗ
2. **slot_settings** — рабочие часы по дням недели
3. **clients** — клиентская база (заготовка под интеграцию с «Моей базой клиентов»)

Все три — внутри одной Baserow-database, чтобы был общий API-токен.

---

## Шаг 0. Войти в Baserow

1. Открой Baserow на VPS Инны (URL уточнит Инна — это её Baserow на Cheerful Marik).
2. Логин/пароль — из Связки ключей Инны (запись `baserow-cheerful-marik`).
3. Слева вверху — название workspace. Создай новый: **Create workspace** → имя `Ирина`.
4. Внутри workspace — **Create new** → **Database** → имя `Календарь записи`.

---

## Шаг 1. Таблица `bookings` (заявки)

**Create table** → имя `bookings` → **From scratch**.

Поля по порядку (правый клик по заголовку → **Edit field** или **Add field**):

| Поле | Тип в Baserow | Настройки |
|---|---|---|
| `id` | (создаётся автоматически как Row ID, тип Number) | — |
| `slot_date` | **Date** | Date format: ISO (YYYY-MM-DD); без времени |
| `slot_time` | **Text** | формат `HH:MM`, например `14:00` (можно использовать **Single line text**, а не Time — Baserow Time умеет хуже) |
| `duration_min` | **Number** | Decimals: 0, по умолчанию `30` |
| `name` | **Long text** | без форматирования |
| `contact_method` | **Single select** | варианты: `telegram`, `vk`, `email`, `phone` |
| `contact_value` | **Long text** | сюда @username, email или телефон |
| `message` | **Long text** | опционально, что хочет обсудить клиент |
| `source` | **Single select** | варианты: `tg_miniapp`, `vk_miniapp`, `website` |
| `status` | **Single select** | варианты: `new` (default), `confirmed`, `done`, `cancelled`, `blocked` |
| `consent_given` | **Boolean** | по PD-AUDIT раздел 5; **обязательно `true` при сохранении** |
| `consent_text_version` | **Single line text** | по PD-AUDIT; пример: `v1.0` |
| `consent_timestamp` | **Date** | включи **Include time** (Date with time); UTC |
| `consent_ip` | **Single line text** | проставляется бэкендом из `X-Real-IP` |
| `created_at` | **Created on** | системное поле Baserow, заполняется автоматически |

**Важно:** статус `blocked` нужен для админ-страницы — Ирина может закрыть слот, не принимая клиента (например, личный нерабочий час), и фронт увидит этот слот как занятый.

### Уникальность слота

В Baserow нет SQL-`UNIQUE`, но контроль двойного бронирования работает на уровне фронта: перед `POST /api/database/rows/...` фронт сначала запрашивает занятые слоты на дату и не показывает уже занятые (см. README раздел «API-контракт»). Дополнительная защита — на стороне TG-бота: если он принимает webhook о новой записи и видит дубль, пишет Ирине «возможен конфликт».

---

## Шаг 2. Таблица `slot_settings` (расписание)

**Create table** в той же базе → имя `slot_settings`.

| Поле | Тип | Настройки |
|---|---|---|
| `weekday` | **Number** | 0–6 (0=вс, 1=пн, …, 6=сб); decimals 0 |
| `start_time` | **Single line text** | `HH:MM` |
| `end_time` | **Single line text** | `HH:MM` |
| `slot_duration_min` | **Number** | по умолчанию `30` |
| `max_slots_per_day` | **Number** | по умолчанию `5` |
| `is_active` | **Boolean** | true/false |

### Дефолты Ирины (заполни вручную)

| weekday | start_time | end_time | slot_duration_min | max_slots_per_day | is_active |
|---|---|---|---|---|---|
| 1 (пн) | 10:00 | 19:00 | 30 | 5 | true |
| 2 (вт) | 10:00 | 19:00 | 30 | 5 | true |
| 3 (ср) | 10:00 | 19:00 | 30 | 5 | true |
| 4 (чт) | 10:00 | 19:00 | 30 | 5 | true |
| 5 (пт) | 10:00 | 19:00 | 30 | 5 | true |
| 6 (сб) | 10:00 | 19:00 | 30 | 5 | false |
| 0 (вс) | 10:00 | 19:00 | 30 | 5 | false |

Когда Ирина захочет включить субботу — открой строку, переключи `is_active` на true.

---

## Шаг 3. Таблица `clients` (база клиентов)

Заготовка под будущую интеграцию с «Моей базой клиентов». Сейчас — необязательная, но желательно создать сразу, чтобы потом не переделывать.

**Create table** → `clients`.

| Поле | Тип | Настройки |
|---|---|---|
| `id` | (Row ID автоматически) | — |
| `name` | **Long text** | — |
| `contact_method` | **Single select** | telegram / vk / email / phone |
| `contact_value` | **Single line text** | — |
| `first_seen` | **Date** | Date with time |
| `last_seen` | **Date** | Date with time |
| `total_bookings` | **Number** | decimals 0, default 0 |
| `notes` | **Long text** | — |
| `tags` | **Multiple select** | пустой; теги Ирина добавляет по ходу (`vip`, `постоянный`, `сложный` и т.п.) |

**Связь с `bookings`** не настраивается на старте: чтобы не усложнять, синхронизация `bookings` → `clients` делается на стороне TG-бота скриптом раз в сутки (см. README).

---

## Шаг 4. Получить API-токен Baserow

1. Кликни по аватарке в правом верхнем углу → **Settings** → **API tokens** (или **Database tokens**, в зависимости от версии).
2. **Create token** → имя `irina-calendar`.
3. Workspace: `Ирина`. Permissions: **Read + Create + Update** на все три таблицы. **Delete** не давай — лишний риск.
4. Скопируй токен сразу — Baserow показывает его один раз. Запиши в Связку ключей под именем `baserow-irina-calendar-token`.

Этот токен пойдёт в три `.env`:
- `tg-bot/.env` — для опроса новых заявок и смены статуса
- `notify-email/.env` — для чтения данных при отправке письма
- админ-страницу `admin.html` — Ирина вводит руками при первом открытии (хранится в localStorage)

---

## Шаг 5. Узнать ID базы и таблиц

В Baserow API всё работает по числовым ID, не по именам.

1. Открой таблицу `bookings` → URL примерно `https://baserow.<host>/database/<DB_ID>/table/<TABLE_ID>`. Запиши оба числа.
2. То же для `slot_settings` и `clients`.

В `.env`:
```
BASEROW_URL=https://baserow.<host-уточнит-Инна>
BASEROW_TOKEN=<из шага 4>
BASEROW_DB_ID=<число>
BASEROW_TABLE_BOOKINGS=<число>
BASEROW_TABLE_SLOT_SETTINGS=<число>
BASEROW_TABLE_CLIENTS=<число>
```

---

## Шаг 6. Webhook (опционально, но желательно)

Baserow self-hosted поддерживает webhook'и: правый клик по таблице → **Webhooks** → **Create webhook**.

| Поле | Значение |
|---|---|
| Name | `notify-tg-bot` |
| URL | `http://127.0.0.1:3010/notify` (если бот на том же VPS) или внешний URL за nginx |
| Events | **Row created** для таблицы `bookings` |
| Method | POST |
| Headers | `Authorization: Bearer <NOTIFY_SECRET>` |

Если webhook'и в твоей версии Baserow не работают (бывает на старых self-hosted сборках) — ничего страшного, TG-бот всё равно опрашивает таблицу раз в 60 секунд (см. `tg-bot/index.js`, режим polling). Webhook просто ускоряет реакцию с ~30 сек до ~1 сек.

---

## Шаг 7. Проверка

В Baserow вручную создай тестовую строку в `bookings`:

```
slot_date: 2026-05-10
slot_time: 14:00
duration_min: 30
name: Тест Инна
contact_method: telegram
contact_value: @inna
message: тестовая запись, удалить
source: website
status: new
consent_given: true
consent_text_version: v1.0
consent_timestamp: <текущий момент>
consent_ip: 127.0.0.1
```

Сохрани. В течение минуты Ирине должно прийти уведомление в TG (если бот запущен) и письмо. После теста — удали строку.

---

## Что нельзя забывать (152-ФЗ)

- **Без `consent_given = true` запись не должна попадать в `bookings`** — это проверяет фронт (кнопка `disabled` без галочки) и дополнительно бэкенд (бот отбрасывает запись без согласия).
- **`consent_ip` обязателен** — проставляется бэкендом приёма (если фронт пишет напрямую в Baserow REST API, IP можно достать только из nginx-логов; рекомендуется промежуточный приём через bot-endpoint, который ставит IP сам — см. README).
- **Срок хранения:** `bookings` — до отзыва согласия или 3 года после последнего контакта. Раз в полгода Ирина проходится по таблице и удаляет содержательные поля у просроченных записей (имя, контакт, сообщение), оставляя `consent_*` поля как доказательство.
