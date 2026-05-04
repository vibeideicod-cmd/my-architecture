# П3 · Календарь записи Ирины Цепаевой

**Что это.** Один backend на **Baserow (РФ)** — три фронта-входа (TG Mini App, VK Mini App, сайт). После записи Ирина получает уведомление в три канала параллельно: TG, email, VK (опционально). Если один лёг — два других всё равно доходят.

**Юр.основа.** Стек собран строго под 152-ФЗ: первичная БД на VPS в РФ (Baserow на Cheerful Marik, Beget Cloud), email через РФ-сервис (UniSender Go или SendPulse), мессенджеры — каналы связи. Подробно — `legal/PD-AUDIT.md`. Регистрация Ирины как оператора ПД в Роскомнадзоре — обязательна (см. PD-AUDIT, раздел 3).

**Стек (всё РФ).**
- **БД:** Baserow на VPS Cheerful Marik (45.9.41.80, Beget Cloud, РФ) — уже стоит.
- **API:** Baserow REST API (встроенный, по токену).
- **TG-бот:** Node.js + node-telegram-bot-api, PM2 на том же VPS.
- **VK-бот:** Node.js + vk-io, опционально.
- **Email:** UniSender Go (1500/мес бесплатно) или SendPulse (12000/мес) — Инна выбирает в `.env`.
- **Хостинг Mini App + admin:** Beget shared (`demo.ideidlyabiznesa1913.ru/cal/`).

**Дефолты Ирины.** Пн-пт 10:00–19:00 МСК · слот 30 мин · до 5 слотов в день · окно бронирования 14 дней. Меняются в таблице `slot_settings` Baserow.

---

## Содержимое папки

```
calendar/
├── README.md                    ← этот файл, пошаговая инструкция
├── BASEROW-SETUP.md             ← как создать таблицы в Baserow (заменяет старый schema.sql)
├── deploy.sh                    ← деплой ботов на VPS + admin.html на Beget
├── index.html                   ← Mini App-фронт (Кодыч)
├── tg-bot/                      ← TG-бот (PM2 irina-cal-tg, порт 3010)
├── vk-bot/                      ← VK-бот (PM2 irina-cal-vk, порт 3011) — опционально
├── notify-email/                ← email через РФ-провайдер (PM2 irina-cal-email, порт 3012)
│   ├── index.js                 ← HTTP-обёртка + диспетчер по EMAIL_PROVIDER
│   ├── unisender.js             ← UniSender Go API
│   ├── sendpulse.js             ← SendPulse API (OAuth2)
│   └── template.js              ← HTML/text шаблон в палитре Ирины
├── admin/
│   ├── SPEC.md                  ← спецификация админ-страницы для Кодыча
│   └── admin.html               ← (вёрстка от Кодыча, появится позже)
└── legal/
    ├── PD-AUDIT.md              ← юр.аудит по 152-ФЗ
    ├── CONSENT-TEXT.md          ← тексты согласия для формы
    └── PRIVACY-POLICY.md        ← политика конфиденциальности
```

---

## Что должна сделать Инна руками — 11 шагов

### Шаг 1. Открыть Baserow на VPS

1. URL Baserow Инна знает (он стоит на её VPS Cheerful Marik). Если не помнит — `ssh root@45.9.41.80`, `docker ps | grep baserow`, посмотреть проброс портов в nginx.
2. Логин/пароль — из Связки ключей под `baserow-cheerful-marik`.
3. Создай workspace «Ирина».

### Шаг 2. Создать таблицы по `BASEROW-SETUP.md`

Открой `BASEROW-SETUP.md` и пройди по всем шагам:
- таблица `bookings` (с полями согласия по 152-ФЗ — `consent_given`, `consent_text_version`, `consent_timestamp`, `consent_ip`)
- таблица `slot_settings` (с дефолтами Ирины пн-пт 10–19)
- таблица `clients` (заготовка под «Мою базу клиентов»)

### Шаг 3. Получить API-токен Baserow

Profile → Settings → Database tokens → Create token «irina-calendar», права Read+Create+Update на все три таблицы. Скопировать сразу — Baserow покажет один раз. В Связку ключей под `baserow-irina-calendar-token`.

Также записать ID базы и таблиц (числа из URL):
- `BASEROW_DB_ID`
- `BASEROW_TABLE_BOOKINGS`
- `BASEROW_TABLE_SLOT_SETTINGS`
- `BASEROW_TABLE_CLIENTS`

### Шаг 4. Создать TG-бота

В Telegram → @BotFather → `/newbot`:
- Имя: `Календарь Ирины Цепаевой`
- Username: `irina_calendar_bot` (или другой свободный, на `_bot`)
- Сохрани токен.

Узнай **TG User ID Ирины** через @userinfobot (он напишет числом). Это `TG_OWNER_CHAT_ID`. **Узнаёт сама Ирина**, не Инна.

### Шаг 5. (Опционально) VK Mini App

Если запускаем VK-канал — `vk.com/dev` → Create App → тип Web App. Получишь `app_id`. В сообществе Ирины (vk.ru/stydiya) → Управление → Работа с API → Ключи доступа (права messages, manage). Это `VK_GROUP_TOKEN`. Callback API: URL `https://<vps-домен>/vk-callback`, тип confirmation + message_new — оттуда `confirmation token` + придумать `secret key`.

Если откладываем VK — пропусти. TG + email уже резервируют друг друга.

### Шаг 6. Зарегистрироваться в РФ-email-сервисе (на выбор)

**Вариант А — UniSender Go (рекомендую новичкам).** [go.unisender.ru](https://go.unisender.ru/) → Sign up → подтверди email → Кабинет → Настройки → API → создать ключ. Бесплатно 1500 писем/мес. Потребуется подтвердить адрес отправителя (либо одиночный email, либо домен).

**Вариант Б — SendPulse.** [sendpulse.com/ru](https://sendpulse.com/ru) → Sign up → Кабинет → Настройки аккаунта → API → Client ID + Secret. Бесплатно 12000 писем/мес. Чуть сложнее (OAuth2), но запас большой.

Адрес отправителя: пока нет домена Ирины — используй её собственный email и подтверди его в кабинете провайдера. Когда появится домен — пройди верификацию домена и поменяй `FROM_EMAIL`.

### Шаг 7. Зарегистрироваться в Роскомнадзоре

**Это делает Ирина**, не Инна. Через Госуслуги, 10 минут заполнения, бесплатно. Подробно — `legal/PD-AUDIT.md`, раздел 3. Без этого собирать ПД нельзя по закону. Регистрационный номер потом вставить в `legal/PRIVACY-POLICY.md`.

### Шаг 8. Заполнить три файла .env

```bash
cd clients/irina/products/calendar
cp tg-bot/.env.example       tg-bot/.env
cp vk-bot/.env.example       vk-bot/.env       # если делаем VK
cp notify-email/.env.example notify-email/.env
# открой каждый в VS Code, заполни, Cmd+S после каждого
```

`NOTIFY_SECRET` должен быть **одинаковый** во всех `.env`. Сгенерируй один раз:

```bash
openssl rand -hex 32
```

И вставь в каждый `.env`.

В `EMAIL_PROVIDER` поставь `unisender` или `sendpulse` — в зависимости от выбора в шаге 6.

### Шаг 9. Деплой ботов

```bash
cd clients/irina/products/calendar
chmod +x deploy.sh
./deploy.sh
```

Скрипт сам проверит .env, синкнет код на VPS, поставит зависимости, поднимет PM2-процессы (`irina-cal-tg`, `irina-cal-email`, `irina-cal-vk` если делали), сделает health-check и (если есть `admin/admin.html`) задеплоит админ-страницу на Beget shared.

После деплоя один раз настрой nginx на VPS, чтобы Baserow webhook (если будем использовать) и внешний мир достучались до /notify:

```nginx
location /irina-cal/notify {
  proxy_pass http://127.0.0.1:3010/notify;
  proxy_set_header Host $host;
}
location /irina-cal/vk-callback {
  proxy_pass http://127.0.0.1:3011/vk-callback;
  proxy_set_header Host $host;
}
```

`nginx -t && systemctl reload nginx`.

### Шаг 10. (Опционально) Webhook в Baserow

В Baserow → таблица `bookings` → правый клик → Webhooks → Create:
- URL: `https://<vps-домен>/irina-cal/notify`
- Events: Row created
- Headers: `Authorization: Bearer <NOTIFY_SECRET>` (тот же, что в `.env`)

Если в твоей версии Baserow webhook'и не работают (бывает) — ничего страшного, TG-бот опрашивает Baserow раз в 60 секунд (см. `tg-bot/index.js`, режим polling). Webhook просто ускоряет реакцию с ~30 сек до ~1 сек.

### Шаг 11. Привязать Mini App к ботам и протестировать

**TG:** @BotFather → `/mybots` → выбери бота → Bot Settings → Menu Button → URL = `https://demo.ideidlyabiznesa1913.ru/cal/`. Текст: «Записаться». Также: Bot Settings → Configure Mini App → Enable → тот же URL → получишь прямую ссылку `t.me/<bot>/app`. Описание бота через `/setdescription`:

> Бот Ирины Цепаевой. Здесь можно записаться на бесплатное знакомство — 30 минут, чтобы обсудить ваш проект. Жми кнопку «Записаться» внизу — откроется календарь.

**Тест:** открой Mini App → выбери слот → впиши «Тест Инна» → отметь чекбокс согласия → отправь. Должны прийти три уведомления (TG + email + VK если есть). Проверь в Baserow → таблица `bookings` — появилась ли запись с `consent_given=true`. Если нет — `pm2 logs irina-cal-tg` на VPS.

---

## Архитектура потока заявки

```
Mini App (фронт, Кодыч)
   │  чекбокс согласия отмечен
   │  POST /api/database/rows/table/<bookings>/?user_field_names=true
   │  Authorization: Token <BASEROW_TOKEN>
   │  body: { slot_date, slot_time, name, contact_*, message, source,
   │          consent_given:true, consent_text_version:'v1.0',
   │          consent_timestamp:<ISO> }
   ▼
Baserow на VPS (РФ, ст.18 ч.5 152-ФЗ ✅)
   │  Webhook (если настроен) → POST /notify
   │  ИЛИ TG-бот опросом (раз в 60 сек) видит status=new
   ▼
TG-бот (на том же VPS)
   ├──▶ TG-сообщение Ирине + inline-кнопки «Подтвердить / Отменить»
   ├──▶ POST email-сервис → UniSender Go или SendPulse → email Ирине
   └──▶ POST VK-бот (если включён) → VK-сообщение Ирине от имени группы
```

Ирина видит уведомление, нажимает «Подтвердить» — TG-бот делает PATCH в Baserow, статус меняется на `confirmed`. Дальше Ирина пишет клиенту в выбранный им канал.

Альтернативный путь — Ирина открывает `admin.html`, вводит свой Baserow-токен, видит весь список заявок, может закрыть слот вручную, посмотреть историю клиента.

---

## API-контракт для Кодыча (фронта)

Кодыч пишет один HTML-файл `index.html`. Среду определяет через `window.Telegram?.WebApp` / `window.vkBridge` / fallback browser. Backend для всех трёх — один Baserow.

### Получить занятые слоты на дату

```
GET ${BASEROW_URL}/api/database/rows/table/${TABLE_BOOKINGS}/
    ?user_field_names=true
    &filter__slot_date__date_equal=2026-05-10
    &filter__status__not_equal=cancelled
    &size=100
Authorization: Token <BASEROW_TOKEN>

→ 200 OK
{ "results": [ { "id":1, "slot_time":"10:00", "status":"new" }, ... ] }
```

### Получить рабочие часы дня

```
GET ${BASEROW_URL}/api/database/rows/table/${TABLE_SLOT_SETTINGS}/
    ?user_field_names=true&size=10
Authorization: Token <BASEROW_TOKEN>

→ 200 OK
{ "results": [ { "weekday":1, "start_time":"10:00", "end_time":"19:00",
                 "slot_duration_min":30, "max_slots_per_day":5,
                 "is_active":true }, ... ] }
```

### Сгенерировать список свободных слотов

**Считается на фронте.** Алгоритм:

1. Считаем `weekday` из выбранной даты (`Date.getDay()` в JS).
2. Из `slot_settings` берём строку с этим `weekday` и `is_active=true`. Если нет — выходной, слотов нет.
3. От `start_time` до `end_time` шагом `slot_duration_min` минут генерируем все возможные `HH:MM`.
4. Из `bookings` на эту дату вычитаем уже занятые `slot_time` (status ≠ cancelled).
5. Не больше `max_slots_per_day` штук.

В старой версии это делалось PostgreSQL-функцией `available_slots`. В Baserow такого механизма нет — поэтому считаем на фронте, это 30 строк JS. **Это нормальное архитектурное решение для Baserow.**

### Создать бронь

```
POST ${BASEROW_URL}/api/database/rows/table/${TABLE_BOOKINGS}/?user_field_names=true
Authorization: Token <BASEROW_TOKEN>
Content-Type: application/json

{
  "slot_date": "2026-05-10",
  "slot_time": "14:00",
  "duration_min": 30,
  "name": "Иван Иванов",
  "contact_method": "telegram",
  "contact_value": "@ivan_ivanov",
  "message": "Хочу обсудить логотип для кофейни",
  "source": "tg_miniapp",
  "status": "new",
  "consent_given": true,
  "consent_text_version": "v1.0",
  "consent_timestamp": "2026-05-10T11:23:45Z"
}

→ 200 OK
{ "id": 42, "slot_date": "2026-05-10", ... }
```

**Без `consent_given:true` отправлять нельзя** — кнопка «Записаться» во фронте `disabled`, пока чекбокс не отмечен. Дополнительно бот фильтрует записи без согласия (см. PD-AUDIT раздел 5).

`consent_ip` фронт не пишет — его проставит nginx-логика на VPS. На случай, когда пишем напрямую в Baserow (без промежуточного бэкенда), `consent_ip` остаётся пустым; это допустимо как «нет данных» — ключевое доказательство согласия — это сам факт `consent_given=true` + timestamp.

После INSERT Baserow Webhook (или polling TG-бота) сам стрельнёт уведомления — фронту больше делать ничего не нужно.

---

## Палитра в письмах

В шаблоне email-письма (`notify-email/template.js`) — только палитра Ирины:
- `#306654` хвоя — текст и заголовки
- `#FF935E` коралл — акценты
- `#FCFAE1` ваниль — фон

Никаких чужих цветов (не Иннины `#103206/#D4AF37`).

## Юр.правила в текстах

В сообщениях ботов и в email — словарь Ирины:
- ✅ «бесплатное знакомство», «обсудить проект», «изготовлю»
- ❌ НЕ «провожу аудит», НЕ «консультирую», НЕ «сопровождаю» (это словарь Инны, у Ирины нет ОКВЭД 70.22)

---

## Если что-то пошло не так

| Симптом | Где смотреть |
|---|---|
| `/start` не отвечает в TG | `pm2 logs irina-cal-tg` — увидишь polling_error |
| Запись создаётся, но Ирина не получает уведомление | `pm2 logs irina-cal-tg` — лог fan-out по трём каналам |
| Email не приходит | `pm2 logs irina-cal-email` + кабинет UniSender/SendPulse → Активность отправок |
| Baserow webhook не стреляет | TG-бот всё равно опрашивает раз в 60 сек, заявка дойдёт |
| 401/403 от Baserow | Токен не заполнен или просрочен — пересоздай в Baserow → Settings |
| Двойное бронирование одного слота | Фронт обязан показывать только свободные; если всё-таки случилось — Ирина вручную в admin.html меняет один на cancelled |

---

## Что удалено из старой версии (для истории)

- `schema.sql` (Supabase) → заменён на `BASEROW-SETUP.md`
- `notify-email/send.js` (Resend) → заменён на `notify-email/index.js` + `unisender.js` / `sendpulse.js`
- Все упоминания Supabase в README, deploy.sh, ботах
- `Database Webhook` Supabase → `Webhook` Baserow (опционально) + polling fallback

---

**Автор пакета:** Systems · **Дата:** 2026-05-04 (v2.0, переход на РФ-стек) · **Связано с:** `clients/irina/visitka-v3/spec/INTERACTIONS-MAP.md` (П3, Развилка 2 → вариант A), `legal/PD-AUDIT.md`.
