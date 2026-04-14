-- ============================================================
-- МГ-платформа — Миграция 100: схема
-- Таблицы для мастер-групп: masters, participants, materials,
-- tasks, messages, cases. Все с префиксом mg_ чтобы не конфликтовать
-- с beauty в том же Supabase-проекте.
-- ============================================================

create extension if not exists pgcrypto;

-- ── Мастера ────────────────────────────────────────────────
create table if not exists mg_masters (
  id               text primary key,        -- slug (например "inna")
  name             text not null,
  niche            text,
  city             text,
  bio              text,
  photo_url        text,
  accent           text default '#e86c3a',

  program_title    text not null,
  program_tagline  text,
  program_desc     text,
  what_you_get     text,                    -- маркированный список, текст
  who_for          text,
  weeks            int default 5,
  meetings_per_week int default 2,
  start_date       date,
  format           text,                    -- "Zoom + Telegram"

  token_hash       text not null,           -- SHA-256 от секретного токена доступа к кабинету

  created_at       timestamptz default now()
);

create index if not exists mg_masters_token_hash_idx on mg_masters(token_hash);

-- ── Участники ─────────────────────────────────────────────
create table if not exists mg_participants (
  id          bigserial primary key,
  master_id   text not null references mg_masters(id) on delete cascade,
  name        text not null,
  contact     text,                         -- email / телефон / телеграм — что прислали
  created_at  timestamptz default now()
);

create index if not exists mg_participants_master_idx on mg_participants(master_id);

-- ── Материалы ─────────────────────────────────────────────
create table if not exists mg_materials (
  id          bigserial primary key,
  master_id   text not null references mg_masters(id) on delete cascade,
  week        int default 1,
  title       text not null,
  body        text,                         -- текст или markdown
  url         text,                         -- ссылка на видео/PDF
  created_at  timestamptz default now()
);

create index if not exists mg_materials_master_idx on mg_materials(master_id);

-- ── Задания ───────────────────────────────────────────────
create table if not exists mg_tasks (
  id          bigserial primary key,
  master_id   text not null references mg_masters(id) on delete cascade,
  week        int default 1,
  title       text not null,
  description text,
  deadline    date,
  created_at  timestamptz default now()
);

create index if not exists mg_tasks_master_idx on mg_tasks(master_id);

-- ── Сообщения чата ────────────────────────────────────────
create table if not exists mg_messages (
  id           bigserial primary key,
  master_id    text not null references mg_masters(id) on delete cascade,
  author_name  text not null,
  author_kind  text not null check (author_kind in ('master','participant')),
  body         text not null,
  created_at   timestamptz default now()
);

create index if not exists mg_messages_master_idx on mg_messages(master_id);

-- ── Кейсы / результаты ────────────────────────────────────
create table if not exists mg_cases (
  id               bigserial primary key,
  master_id        text not null references mg_masters(id) on delete cascade,
  participant_name text not null,
  result           text not null,
  contact          text,
  created_at       timestamptz default now()
);

create index if not exists mg_cases_master_idx on mg_cases(master_id);
