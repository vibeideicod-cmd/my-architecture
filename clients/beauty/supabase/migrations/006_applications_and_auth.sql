-- ============================================================
-- Beauty TMA — Миграция 006: Заявки мастеров и токены авторизации
--
-- Multi-tenant SaaS v2: мастера с улицы могут подавать заявку,
-- Инна как админ одобряет/отклоняет, одобренный мастер получает
-- токен и работает в своём кабинете.
--
-- Паттерн взят из МГ (clients/mastergroup/supabase/migrations/200_*).
--
-- Что добавляется:
--   • таблица beauty_applications — анкеты мастеров со статусом
--   • колонка token_hash в masters — SHA-256(plain_token) для auth
--   • колонка is_approved в masters — мастер виден в каталоге или нет
--   • RLS политики
-- ============================================================

-- ── Заявки мастеров ──────────────────────────────────────
create table if not exists beauty_applications (
  id              bigserial primary key,
  name            text not null,                      -- ФИО
  city            text not null,
  specialty       text not null,                      -- 'Маникюр', 'Брови', 'Массаж'
  telegram        text,                               -- '@nickname'
  phone           text,
  portfolio_url   text,                               -- ссылка на Instagram/сайт/папку
  about           text,                               -- о себе
  agreed_pd       boolean not null default false,     -- согласие на обработку ПД

  status          text not null default 'pending'
                  check (status in ('pending','approved','rejected')),
  master_slug     text references masters(id),        -- заполняется при одобрении
  token_hash      text,                               -- SHA-256(plain_token), выдаётся при одобрении
  moderator_note  text,                               -- причина отказа или комментарий

  created_at      timestamptz default now(),
  moderated_at    timestamptz
);

create index if not exists idx_beauty_apps_status
  on beauty_applications(status);
create index if not exists idx_beauty_apps_token_hash
  on beauty_applications(token_hash) where token_hash is not null;

-- ── Расширение masters: авторизация и видимость ─────────
alter table masters
  add column if not exists token_hash  text,
  add column if not exists is_approved boolean default false;

create index if not exists idx_masters_token_hash
  on masters(token_hash) where token_hash is not null;

-- Анна уже в базе — помечаем её как одобренную (она наш эталонный мастер)
update masters set is_approved = true where id = 'anna';

-- ── RLS: всё закрыто, данные меняются только через RPC ──
alter table beauty_applications enable row level security;

-- По умолчанию RLS без policy = доступ запрещён всем anon.
-- Все модификации через RPC-функции с SECURITY DEFINER (миграция 007).

-- Публичное чтение masters уже есть (public_read_masters, миграция 002).
-- Но теперь стоит ограничить только одобренными мастерами, чтобы
-- заявки не появлялись в публичном каталоге до одобрения.
drop policy if exists "public_read_masters" on masters;
create policy "public_read_masters"
  on masters for select using (is_approved = true);
