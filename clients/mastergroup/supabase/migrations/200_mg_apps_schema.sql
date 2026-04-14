-- ============================================================
-- МГ-платформа v2 — Миграция 200: схема анкет, страниц, конструктора
-- Добавляется рядом с v1 (таблицы mg_* остаются нетронутыми).
-- Playbook Фаза 4 Build, plan: clients/mastergroup/BACKEND-PLAN.md
-- ============================================================

create extension if not exists pgcrypto;

-- ── Sequence для номеров мастеров ─────────────────────────
create sequence if not exists mg_master_number_seq start 1;

-- ── Анкеты кандидатов в мастера ───────────────────────────
create table if not exists mg_applications (
  id                  bigserial primary key,
  master_number       int unique not null,
  application_token   text unique not null,
  full_name           text not null,
  contact             text not null,
  city                text,
  niche               text,
  business_desc       text,
  mg_context          text,
  goal                text,
  experience          text,
  consent_pd          boolean not null check (consent_pd = true),
  status              text not null default 'submitted'
                        check (status in ('submitted','under_review','approved','rejected')),
  moderation_note     text,
  reviewed_at         timestamptz,
  reviewed_by         text,
  created_at          timestamptz default now()
);

create index if not exists mg_applications_status_idx on mg_applications(status, created_at desc);

-- ── Автоприсвоение номера мастера при подаче анкеты ───────
create or replace function mg_assign_master_number()
returns trigger
language plpgsql
as $$
begin
  if new.master_number is null then
    new.master_number := nextval('mg_master_number_seq');
  end if;
  if new.application_token is null then
    new.application_token := encode(gen_random_bytes(16), 'hex');
  end if;
  return new;
end;
$$;

drop trigger if exists mg_applications_master_number_bi on mg_applications;
create trigger mg_applications_master_number_bi
  before insert on mg_applications
  for each row execute function mg_assign_master_number();

-- ── Страницы одобренных мастеров (JSON-конфиг) ────────────
create table if not exists mg_master_pages (
  slug             text primary key,
  application_id   bigint not null unique references mg_applications(id),
  master_number    int not null,
  token_hash       text not null,
  display_name     text,
  use_real_name    boolean default false,
  page_config      jsonb not null default '{}'::jsonb
                     check (jsonb_typeof(page_config) = 'object'),
  published        boolean default false,
  published_at     timestamptz,
  version          int not null default 1,
  updated_at       timestamptz default now(),
  created_at       timestamptz default now()
);

create index if not exists mg_master_pages_token_hash_idx on mg_master_pages(token_hash);
create index if not exists mg_master_pages_published_idx on mg_master_pages(published) where published = true;
create index if not exists mg_master_pages_master_number_idx on mg_master_pages(master_number);

-- ── Справочник вопросов конструктора ──────────────────────
-- Можно менять/добавлять вопросы без миграции кода
create table if not exists mg_config_questions (
  id          smallserial primary key,
  block       text not null check (block in ('hero','about','offer','cta')),
  order_idx   int not null,
  code        text unique not null,
  label       text not null,
  hint        text,
  example     text,
  required    boolean default false,
  type        text not null check (type in ('text','textarea','url','select','list','cta_choice')),
  max_length  int,
  options     jsonb
);

create index if not exists mg_config_questions_block_order_idx on mg_config_questions(block, order_idx);

-- ── Заявки от посетителей публичных страниц ───────────────
-- Только если мастер выбрал link_type = 'form'
create table if not exists mg_leads (
  id              bigserial primary key,
  master_slug     text not null references mg_master_pages(slug) on delete cascade,
  visitor_name    text not null,
  visitor_contact text not null,
  message         text,
  created_at      timestamptz default now()
);

create index if not exists mg_leads_master_slug_idx on mg_leads(master_slug, created_at desc);
