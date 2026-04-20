# references/content-schema.md

## Полная JSON-схема входа скилла

```json
{
  "platform": "browser",

  "inna": {
    "tg_channel":  "https://t.me/inna_arhitektor",
    "tg_direct":   "https://t.me/inna_username",
    "email":       "inna@example.com",
    "photo_url":   "/assets/inna-portrait.jpg"
  },

  "speed_triggers": [
    {"format": "Визитка-упаковка эксперта",   "time": "2 часа",      "tech": "Нейроагенты + vibe-coding"},
    {"format": "Сайт-визитка / лендинг",        "time": "1 сутки",     "tech": "Нейроагенты + готовые шаблоны"},
    {"format": "Telegram Mini App",             "time": "3–5 дней",    "tech": "TMA SDK + Supabase"},
    {"format": "ИИ-ассистент в отдел продаж",   "time": "1–2 недели",  "tech": "Каскад скилов + CRM"},
    {"format": "Автоворонка в мессенджере",     "time": "неделя",      "tech": "Скилл-цепочка + бот"}
  ],

  "visitor": null,

  "supabase": {
    "url":       "https://qwoepdibvmwqgkkaabba.supabase.co",
    "anon_key":  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "table":     "inna_leads"
  },

  "notification_bot": {
    "token":    "1234567890:AAH...",
    "chat_id":  "123456789"
  }
}
```

## Валидация

| Поле | Обязательное | Fallback если пусто |
|---|---|---|
| `platform` | да | ошибка, скилл не может рендерить без платформы |
| `inna.tg_channel` | желательно | строка `TBD` в HTML + warning в лог |
| `inna.tg_direct` | желательно | строка `TBD` + warning |
| `inna.email` | нет | скрываем блок email в футере |
| `inna.photo_url` | желательно | плейсхолдер-монограмма «ИА» в круге |
| `speed_triggers` | да, массив 3-5 | если пусто — ошибка, блок триггеров обязателен |
| `visitor` | нет | `null` = пустой конструктор, интерактив включён |
| `supabase.*` | в production — да | в dev-режиме конструктор работает, форма ничего не сохраняет |
| `notification_bot.*` | нет | без уведомлений Инне, но лиды всё равно в Supabase |

## Поля формы-конструктора (для посетителя)

Порядок отображения и обязательность:

| # | Поле | Тип | Placeholder | Обязательно | Maxlen |
|---|---|---|---|---|---|
| 1 | `name` | text | «Имя (как представляешься клиентам)» | да | 60 |
| 2 | `role` | text | «Кто ты одной фразой» | да | 120 |
| 3 | `achievement` | text | «Главное достижение или цифра результата» | да | 200 |
| 4 | `audience` | text | «Кому помогаешь» | нет | 120 |
| 5 | `contact` | text | «Куда тебе писать (TG/Instagram/сайт)» | нет | 100 |

Кнопка «Забрать готовое» появляется только когда все 3 обязательных заполнены (валидация — непустая строка ≥ 3 символов).

## Поля гейта (после нажатия «Забрать»)

| Платформа | Вариант 1 | Вариант 2 |
|---|---|---|
| browser | TG username (`@...`) | email |
| tma | auto (`tg.initDataUnsafe.user.username`), подтверждение кнопкой | — |
| vk | auto через `VKWebAppGetEmail` | — |

## Таблица `inna_leads` в Supabase

```sql
create table inna_leads (
  id             uuid primary key default gen_random_uuid(),
  created_at     timestamptz not null default now(),
  platform       text not null check (platform in ('browser','tma','vk')),
  visitor_name   text not null,
  visitor_role   text not null,
  visitor_achievement text not null,
  visitor_audience    text,
  visitor_contact     text,
  tg_username    text,
  tg_user_id     bigint,
  vk_id          bigint,
  vk_email       text,
  user_agent     text,
  source         text  /* UTM / startapp для трекинга трафика */
);

/* RLS: insert открыт, select — только для service_role */
alter table inna_leads enable row level security;
create policy "anon insert" on inna_leads for insert with check (true);
```
