# Backend Plan: МГ-платформа v2 — анкета, модерация, конструктор

**Фаза:** 3 — Plan (бэкенд-часть).
**Playbook:** [product-creation.md](../../knowledge/playbooks/product-creation.md) раздел 3.2 + [templates-backend.md](../../knowledge/prompting/templates-backend.md).
**Инструмент:** Supabase (тот же проект `my-architecture`), мигратор `node scripts/supabase-migrate.mjs --client mastergroup`.

---

## Ключевая задача

Принять анкеты кандидатов в мастера, дать Инне одобрить их, сгенерировать каждому мастер-токен и slug, хранить JSON-конфиг его страницы, публиковать страницы, опционально собирать leads с публичных страниц.

**НЕ цель:** управлять участниками, материалами, заданиями, чатами — это работа v1 `mg_masters/participants/materials/tasks/messages/cases`, их не трогаем.

---

## Новые таблицы

Добавляются к существующим `mg_*` (v1). Никаких `ALTER` на v1-таблицах.

### 1. `mg_applications` — анкеты кандидатов

| Поле | Тип | Ограничения / комментарий |
|---|---|---|
| `id` | `bigserial` | PK |
| `master_number` | `int` | `unique not null`, присваивается триггером из `mg_master_number_seq` |
| `application_token` | `text` | `unique not null`, 32 hex, генерится в БД через `encode(gen_random_bytes(16), 'hex')` |
| `full_name` | `text` | `not null` |
| `contact` | `text` | `not null`, свободная строка (tg/email/phone в одной) |
| `city` | `text` | |
| `niche` | `text` | |
| `business_desc` | `text` | «чем занимаешься в своём бизнесе» |
| `mg_context` | `text` | «что делаешь в МГ УБ», опционально |
| `goal` | `text` | «чего хочешь от приложения» |
| `experience` | `text` | `check in ('<1', '1-3', '>3')` |
| `consent_pd` | `boolean` | `not null`, `check (consent_pd = true)` |
| `status` | `text` | `not null default 'submitted'`, `check in ('submitted','under_review','approved','rejected')` |
| `moderation_note` | `text` | комментарий Инны |
| `reviewed_at` | `timestamptz` | |
| `reviewed_by` | `text` | `'inna'` (захардкожено) |
| `created_at` | `timestamptz` | `default now()` |

**Индексы:**
- `unique (application_token)`
- `unique (master_number)`
- `(status, created_at desc)` — для очереди анкет в админке

### 2. `mg_master_pages` — конфиг страницы одобренного мастера

| Поле | Тип | Комментарий |
|---|---|---|
| `slug` | `text` | PK, генерится при одобрении как `'master-' || master_number` |
| `application_id` | `bigint` | FK → `mg_applications(id) on delete restrict` |
| `master_number` | `int` | денорм, equals `applications.master_number` |
| `token_hash` | `text` | `not null`, SHA-256 от мастер-токена (как v1) |
| `display_name` | `text` | ФИО если мастер разрешил, иначе пусто |
| `use_real_name` | `boolean` | `default false` |
| `page_config` | `jsonb` | `not null default '{}'::jsonb`, см. структуру ниже |
| `published` | `boolean` | `default false` |
| `published_at` | `timestamptz` | |
| `version` | `int` | `not null default 1`, bump при каждом save |
| `updated_at` | `timestamptz` | `default now()` |
| `created_at` | `timestamptz` | `default now()` |

**Индексы:**
- PK (slug)
- `(token_hash)` — для auth
- `(published) where published = true` — для публичного рендера
- `(master_number)`
- `unique (application_id)` — one-to-one с анкетой

**Структура `page_config`:**

```json
{
  "hero": {
    "display_name": "Алиса",
    "headline": "Школа гитары для взрослых в центре Москвы",
    "photo_url": "https://disk.yandex.ru/..."
  },
  "about": {
    "bio": "Играю 15 лет, преподаю 7. Занималась в Гнесинке..."
  },
  "offer": {
    "title": "Первое занятие бесплатно",
    "description": "Приходи на первый урок, это 60 минут...",
    "benefits": [
      "Индивидуальный подход",
      "Любой уровень",
      "Удобное время"
    ]
  },
  "cta": {
    "text": "Записаться на первый урок",
    "link_type": "telegram",
    "link_value": "@alisa_guitar"
  }
}
```

`link_type` ∈ `'telegram' | 'whatsapp' | 'phone' | 'form'`.

### 3. `mg_config_questions` — справочник вопросов конструктора

**Зачем отдельная таблица:** чтобы менять формулировки вопросов без миграции кода.

| Поле | Тип | Комментарий |
|---|---|---|
| `id` | `smallserial` | PK |
| `block` | `text` | `'hero' / 'about' / 'offer' / 'cta'` |
| `order_idx` | `int` | |
| `code` | `text` | `unique`, ключ в page_config (например `display_name`, `benefits`) |
| `label` | `text` | текст вопроса |
| `hint` | `text` | подсказка |
| `example` | `text` | живой пример ответа |
| `required` | `boolean` | |
| `type` | `text` | `'text' / 'textarea' / 'url' / 'select' / 'list' / 'cta_choice'` |
| `max_length` | `int` | опциональный мягкий лимит (счётчик показываем, не блокируем) |
| `options` | `jsonb` | для `select` |

**Индексы:** PK, `unique (code)`, `(block, order_idx)`

### 4. `mg_leads` — заявки от посетителей публичных страниц

(Только если мастер выбрал `link_type = 'form'`.)

| Поле | Тип |
|---|---|
| `id` | `bigserial` PK |
| `master_slug` | `text` FK → `mg_master_pages(slug)` |
| `visitor_name` | `text not null` |
| `visitor_contact` | `text not null` |
| `message` | `text` |
| `created_at` | `timestamptz default now()` |

**Индексы:** PK, `(master_slug, created_at desc)`

---

## Sequence + триггер «Мастер N»

```sql
create sequence if not exists mg_master_number_seq start 1;

create or replace function mg_assign_master_number()
returns trigger
language plpgsql
as $$
begin
  if new.master_number is null then
    new.master_number := nextval('mg_master_number_seq');
  end if;
  return new;
end;
$$;

create trigger mg_applications_master_number_bi
  before insert on mg_applications
  for each row execute function mg_assign_master_number();
```

Номер присваивается **при insert анкеты**, не при одобрении (подтверждение из голосового Инны). Если анкета отклонена — номер «сгорает» (мастер 5 может быть пропущен в БД, это нормально).

---

## RPC-функции (security definer)

Все модификации идут через RPC. Никаких прямых `INSERT/UPDATE/DELETE` с anon-ключа на `mg_applications` и `mg_master_pages`.

### 1. `mg_submit_application(payload jsonb) returns jsonb`

```sql
create or replace function mg_submit_application(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id bigint;
  new_token text;
  new_number int;
begin
  if (payload->>'consent_pd')::boolean is not true then
    raise exception 'Согласие на обработку ПД обязательно';
  end if;

  new_token := encode(gen_random_bytes(16), 'hex');

  insert into mg_applications (
    application_token, full_name, contact, city, niche,
    business_desc, mg_context, goal, experience, consent_pd
  )
  values (
    new_token,
    payload->>'full_name',
    payload->>'contact',
    payload->>'city',
    payload->>'niche',
    payload->>'business_desc',
    payload->>'mg_context',
    payload->>'goal',
    payload->>'experience',
    true
  )
  returning id, master_number into new_id, new_number;

  return jsonb_build_object(
    'application_id', new_id,
    'master_number', new_number,
    'application_token', new_token
  );
end;
$$;

grant execute on function mg_submit_application(jsonb) to anon;
```

### 2. `mg_get_application_by_token(token text) returns jsonb`

Для `status.html` — возвращает поля анкеты + статус + `moderation_note`. Только по совпадающему `application_token`.

```sql
create or replace function mg_get_application_by_token(token text)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'full_name', full_name,
    'niche', niche,
    'status', status,
    'moderation_note', moderation_note,
    'created_at', created_at,
    'reviewed_at', reviewed_at,
    'master_slug', (select slug from mg_master_pages where application_id = a.id),
    'master_token_note', case
      when a.status = 'approved'
        then 'token_delivered_separately'
      else null
    end
  )
  from mg_applications a
  where application_token = token
  limit 1;
$$;

grant execute on function mg_get_application_by_token(text) to anon;
```

**Важно:** мастер-токен в этой функции НЕ возвращается. Его Инна копирует один раз после approve и отправляет в Telegram вручную (см. пункт 3 ниже).

### 3. `mg_moderate(app_id bigint, new_status text, note text, admin_secret text) returns jsonb`

Одобрение или отклонение. Проверяет admin_secret против захардкоженного хэша. На approved создаёт запись в `mg_master_pages` и возвращает мастер-токен **один раз**.

```sql
create or replace function mg_moderate(
  app_id bigint,
  new_status text,
  note text,
  admin_secret text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  correct_hash text := 'a5b4f151eae19e3decba7a00c66c1d487062791e3deb0d690594ad7923fac6a5'; -- SHA-256 от 'nbcccp-2026'
  master_number_val int;
  new_slug text;
  new_token text;
  new_token_hash text;
begin
  if encode(digest(admin_secret, 'sha256'), 'hex') <> correct_hash then
    raise exception 'Неверный админ-ключ';
  end if;

  if new_status not in ('approved', 'rejected') then
    raise exception 'Недопустимый статус: %', new_status;
  end if;

  select master_number into master_number_val from mg_applications where id = app_id;
  if not found then
    raise exception 'Анкета % не найдена', app_id;
  end if;

  update mg_applications
  set status = new_status,
      moderation_note = note,
      reviewed_at = now(),
      reviewed_by = 'inna'
  where id = app_id;

  if new_status = 'rejected' then
    return jsonb_build_object('status', 'rejected');
  end if;

  -- approved: создаём mg_master_pages
  new_slug := 'master-' || master_number_val;
  new_token := encode(gen_random_bytes(16), 'hex');
  new_token_hash := encode(digest(new_token, 'sha256'), 'hex');

  insert into mg_master_pages (slug, application_id, master_number, token_hash)
  values (new_slug, app_id, master_number_val, new_token_hash);

  return jsonb_build_object(
    'status', 'approved',
    'slug', new_slug,
    'master_token', new_token,
    'master_number', master_number_val
  );
end;
$$;

grant execute on function mg_moderate(bigint, text, text, text) to anon;
```

**Критично:** `master_token` возвращается **один раз**. Дальше в БД только `token_hash`. Если Инна потеряет — надо генерить новый через отдельную RPC.

### 4. `mg_save_page(slug text, token text, patch jsonb) returns void`

```sql
create or replace function mg_save_page(slug text, token text, patch jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  stored_hash text;
begin
  select token_hash into stored_hash from mg_master_pages where mg_master_pages.slug = mg_save_page.slug;
  if not found then
    raise exception 'Страница % не найдена', slug;
  end if;

  if encode(digest(token, 'sha256'), 'hex') <> stored_hash then
    raise exception 'Неверный токен';
  end if;

  update mg_master_pages
  set page_config = page_config || patch,
      version = version + 1,
      updated_at = now()
  where mg_master_pages.slug = mg_save_page.slug;
end;
$$;

grant execute on function mg_save_page(text, text, jsonb) to anon;
```

Merge-семантика: `page_config || patch` — новые ключи заменяют старые, остальные остаются. Подходит для пошагового заполнения.

### 5. `mg_publish_page(slug text, token text) returns jsonb`

Проверяет обязательные поля, ставит `published = true`.

```sql
create or replace function mg_publish_page(slug text, token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  stored_hash text;
  cfg jsonb;
  missing text[];
begin
  select token_hash, page_config into stored_hash, cfg
  from mg_master_pages where mg_master_pages.slug = mg_publish_page.slug;
  if not found then
    raise exception 'Страница % не найдена', slug;
  end if;

  if encode(digest(token, 'sha256'), 'hex') <> stored_hash then
    raise exception 'Неверный токен';
  end if;

  -- Проверка обязательных полей
  missing := array[]::text[];
  if coalesce(cfg->'hero'->>'display_name', '') = '' then missing := array_append(missing, 'display_name'); end if;
  if coalesce(cfg->'hero'->>'headline', '') = '' then missing := array_append(missing, 'headline'); end if;
  if coalesce(cfg->'about'->>'bio', '') = '' then missing := array_append(missing, 'bio'); end if;
  if coalesce(cfg->'offer'->>'title', '') = '' then missing := array_append(missing, 'offer_title'); end if;
  if coalesce(cfg->'offer'->>'description', '') = '' then missing := array_append(missing, 'offer_desc'); end if;
  if coalesce(cfg->'cta'->>'text', '') = '' then missing := array_append(missing, 'cta_text'); end if;
  if coalesce(cfg->'cta'->>'link_value', '') = '' then missing := array_append(missing, 'cta_link_value'); end if;

  if array_length(missing, 1) > 0 then
    return jsonb_build_object('published', false, 'missing', to_jsonb(missing));
  end if;

  update mg_master_pages
  set published = true,
      published_at = now()
  where mg_master_pages.slug = mg_publish_page.slug;

  return jsonb_build_object('published', true, 'slug', slug);
end;
$$;

grant execute on function mg_publish_page(text, text) to anon;
```

### 6. `mg_submit_lead(master_slug text, visitor_name text, visitor_contact text, message text) returns void`

Простая вставка в `mg_leads`. Обёрнута в RPC, чтобы не открывать `INSERT` на таблицу всем.

### 7. `mg_admin_list_applications(admin_secret text) returns setof mg_applications`

Возвращает все анкеты для админки (проверка пароля).

### 8. `mg_admin_list_pages(admin_secret text) returns setof mg_master_pages`

Аналогично для таба «Собранные страницы».

---

## RLS политики

Все таблицы — RLS enabled. Публичные политики — **только через view** или **только на безопасные операции**.

### `mg_applications`

```sql
alter table mg_applications enable row level security;
-- Никаких публичных политик. Доступ только через RPC security definer.
```

### `mg_master_pages`

```sql
alter table mg_master_pages enable row level security;
-- Публичных политик нет. Читать через view + RPC.
```

### View `mg_master_pages_public`

```sql
create or replace view mg_master_pages_public as
  select slug, display_name, page_config, published, published_at
  from mg_master_pages
  where published = true;

grant select on mg_master_pages_public to anon;
```

`master-page.html` читает из этого view — нет риска утечки `token_hash` или draft-страниц.

### `mg_config_questions`

```sql
alter table mg_config_questions enable row level security;

create policy "public_read_questions" on mg_config_questions
  for select using (true);
```

Публичное чтение (справочник не секретен).

### `mg_leads`

```sql
alter table mg_leads enable row level security;
-- insert только через RPC mg_submit_lead
```

### Realtime publication

```sql
alter publication supabase_realtime add table mg_applications;
```

Админка подписывается на INSERT и UPDATE, чтобы новые анкеты всплывали без F5.

---

## Миграции

Три файла в `clients/mastergroup/supabase/migrations/`:

### `200_mg_apps_schema.sql`

- `create extension if not exists pgcrypto;` (для `gen_random_bytes` и `digest`)
- `create sequence mg_master_number_seq`
- `create table mg_applications`
- `create table mg_master_pages`
- `create table mg_config_questions`
- `create table mg_leads`
- Индексы
- Триггер `mg_assign_master_number`

### `201_mg_apps_policies.sql`

- `alter table ... enable row level security` на все
- View `mg_master_pages_public`
- Policy `public_read_questions`
- RPC функции: `mg_submit_application`, `mg_get_application_by_token`, `mg_moderate`, `mg_save_page`, `mg_publish_page`, `mg_submit_lead`, `mg_admin_list_applications`, `mg_admin_list_pages`
- `grant execute ... to anon` на все RPC
- `alter publication supabase_realtime add table mg_applications`

### `202_mg_apps_seed_questions.sql`

Заполнение справочника вопросов конструктора (8 вопросов из `brief.md` раздел 1.4):

```sql
insert into mg_config_questions (block, order_idx, code, label, hint, example, required, type, max_length) values
  ('hero',  1, 'display_name', 'Как тебя зовут?',
   'Отображается на странице большими буквами',
   'Алиса', true, 'text', 50),

  ('hero',  2, 'headline', 'Одна фраза о твоём деле',
   'Что ты делаешь и для кого — одним предложением',
   'Школа гитары для взрослых в центре Москвы', true, 'text', 80),

  ('hero',  3, 'photo_url', 'Ссылка на твою фотку',
   'Самый простой способ: Яндекс.Диск → Поделиться → Скопировать ссылку. Можно пропустить.',
   'https://disk.yandex.ru/i/...', false, 'url', null),

  ('about', 1, 'bio', 'Расскажи о себе',
   '2-3 абзаца, всё что важно знать клиенту',
   'Играю на гитаре 15 лет, преподаю 7. Занималась в Гнесинке. Веду индивидуальные уроки и группы в центре Москвы. Помогаю взрослым учиться без страха и быстро.',
   true, 'textarea', 800),

  ('offer', 1, 'offer_title', 'Название твоего предложения',
   'Что ты предлагаешь клиенту, который пришёл',
   'Первое занятие бесплатно', true, 'text', 60),

  ('offer', 2, 'offer_desc', 'Опиши предложение',
   'Что именно происходит, когда клиент откликается',
   'Приходи на первый урок, это 60 минут, бесплатно. Попробуем твою гитару, посмотрим что умеешь, подберём программу если зайдёт.',
   true, 'textarea', 500),

  ('offer', 3, 'benefits', '3 причины выбрать тебя',
   'По одной на строку, минимум 2',
   'Индивидуальный подход\nЛюбой уровень\nУдобное время',
   false, 'list', null),

  ('cta',   1, 'cta_choice', 'Куда написать клиенту, который хочет записаться?',
   'Выбери один способ',
   'Telegram @alisa_guitar', true, 'cta_choice', null);
```

---

## RLS-матрица (сводная)

| Таблица | anon SELECT | anon INSERT | anon UPDATE/DELETE | RPC-доступ |
|---|---|---|---|---|
| `mg_applications` | ❌ | ❌ | ❌ | ✅ `mg_submit_application` (INSERT), `mg_get_application_by_token` (SELECT by token), `mg_moderate` (UPDATE w/ admin_secret), `mg_admin_list_applications` (SELECT w/ admin_secret) |
| `mg_master_pages` | через view `mg_master_pages_public` (только `published=true`) | ❌ | ❌ | ✅ `mg_moderate` (INSERT на approve), `mg_save_page` (UPDATE), `mg_publish_page` (UPDATE), `mg_admin_list_pages` (SELECT w/ admin_secret) |
| `mg_config_questions` | ✅ (справочник) | ❌ | ❌ | — (для будущего админ-UI) |
| `mg_leads` | ❌ | ❌ | ❌ | ✅ `mg_submit_lead` (INSERT), `mg_admin_list_leads` (опц., w/ admin_secret) |

---

## Обоснование `jsonb` для `page_config`

**Почему не отдельные колонки:** конструктор будет эволюционировать (добавим FAQ, галерею, отзывы, видео). Каждый новый вопрос = миграция колонки. В `jsonb` — вставка одной строки в `mg_config_questions` + релоад конструктора, без миграции схемы.

**Почему версионность — `version int` а не отдельная таблица:** для MVP нам нужна только метка «было изменение». История ревизий — в v2.1.

**Минус jsonb — сложнее искать по полям.** Для MVP критичных поисковых запросов нет (только `where slug = ?`). Если потом понадобится — добавим GIN-индекс `using gin (page_config jsonb_path_ops)`.

**Валидация структуры:** check-constraint `jsonb_typeof(page_config) = 'object'` + клиентская валидация перед сохранением.

---

## Риски и ограничения

1. **Производительность RPC** — все модификации через security definer функции. Это нормально до сотен RPS. У нас будут десятки в пике.
2. **Админ-пароль в коде RPC** — хэш `correct_hash` жёстко прописан в `mg_moderate`. Смена пароля = миграция SQL. Приемлемо для MVP, в v2.1 — вынести в отдельную таблицу `mg_admin_config`.
3. **Мастер-токен выдаётся один раз** — если Инна его теряет, нужна отдельная RPC `mg_regenerate_master_token(slug, admin_secret)`. В MVP — отложено.
4. **Search path в RPC** — все функции с `set search_path = public` для безопасности (избегаем SQL injection через temp schemas).
5. **Leads без ограничений** — теоретически можно спамить `mg_submit_lead`. В MVP — принимаем. В v2.1 — rate limiting или CAPTCHA.

---

## Критерий готовности Фазы 3 (бэкенд-часть)

- [x] 4 таблицы спроектированы
- [x] Sequence + триггер номера мастера
- [x] 8 RPC-функций прописаны
- [x] RLS-матрица заполнена
- [x] View `mg_master_pages_public` спроектирован
- [x] 3 миграции спланированы
- [x] Обоснование `jsonb` дано
- [x] Риски зафиксированы
- [ ] Системщик читает и говорит «вопросов нет» (переход к Build)
