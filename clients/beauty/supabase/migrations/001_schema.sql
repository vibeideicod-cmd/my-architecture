-- ============================================================
-- Beauty TMA — Миграция 001: Схема базы данных
-- Назначение: создать все таблицы под клиентскую часть TMA
-- (мастера, категории, услуги, фото, расписание, записи).
-- Запускать в Supabase → SQL Editor → кнопка Run.
-- ============================================================

-- ── Мастера ──────────────────────────────────────────────
-- Каждый мастер — это аккаунт владельца кабинета (Анна, Мария и т.д.)
-- id — текстовый slug, используется в deep link бота и в URL
create table if not exists masters (
  id            text primary key,                    -- 'anna', 'masha-nails'
  telegram_id   bigint unique,                       -- tg user id мастера (null пока нет онбординга)
  name          text not null,                       -- 'Анна Смирнова'
  specialty     text,                                -- 'Бьюти-мастер'
  city          text,                                -- 'Москва'
  bio           text,
  avatar_url    text,                                -- ссылка на фото в Storage
  accent_color  text default '#b49fd4',              -- hex, брендинг UI
  status_text   text,                                -- 'Принимаю записи на май 🌸'
  created_at    timestamptz default now()
);

-- ── Категории услуг ──────────────────────────────────────
-- Маникюр / Педикюр / Дизайн / Уход — привязаны к конкретному мастеру
create table if not exists categories (
  id          bigserial primary key,
  master_id   text not null references masters(id) on delete cascade,
  name        text not null,                         -- 'Маникюр'
  icon        text,                                  -- emoji '💅'
  position    int default 0,                         -- порядок в списке
  is_active   boolean default true,
  created_at  timestamptz default now()
);

-- ── Услуги ───────────────────────────────────────────────
-- Конкретные услуги в категории с ценой и длительностью
create table if not exists services (
  id           bigserial primary key,
  master_id    text not null references masters(id) on delete cascade,
  category_id  bigint references categories(id) on delete set null,
  name         text not null,
  description  text,
  price_from   int not null,                         -- в рублях
  price_exact  boolean default true,                 -- false = «от X ₽»
  duration     int not null,                         -- в минутах
  tags         text[],                               -- массив тегов ['Гель-лак','Классика']
  position     int default 0,
  is_active    boolean default true,
  created_at   timestamptz default now()
);

-- ── Фото услуг ───────────────────────────────────────────
-- Несколько фото на услугу, URL из Supabase Storage или CDN
create table if not exists service_photos (
  id          bigserial primary key,
  service_id  bigint not null references services(id) on delete cascade,
  url         text not null,
  position    int default 0,
  created_at  timestamptz default now()
);

-- ── Расписание мастера ───────────────────────────────────
-- По дням недели: Пн=1, Вс=7. Выходной = is_working false.
create table if not exists schedules (
  id             bigserial primary key,
  master_id      text not null references masters(id) on delete cascade,
  day_of_week    int not null check (day_of_week between 1 and 7),
  start_time     time not null default '10:00',
  end_time       time not null default '18:00',
  slot_duration  int default 60,                     -- длина слота в минутах
  is_working     boolean default true,
  unique (master_id, day_of_week)
);

-- ── Записи клиентов ──────────────────────────────────────
-- Создаётся когда клиент жмёт «Записаться» в TMA
create table if not exists bookings (
  id                  bigserial primary key,
  master_id           text not null references masters(id) on delete cascade,
  service_id          bigint references services(id),
  client_telegram_id  bigint,                        -- tg user id клиента
  client_name         text,
  client_phone        text,
  scheduled_at        timestamptz not null,
  duration_min        int not null,
  status              text default 'confirmed'
                      check (status in ('confirmed','cancelled','completed')),
  created_at          timestamptz default now()
);

-- ── Индексы для скорости ─────────────────────────────────
-- PostgreSQL без индексов тупит на фильтрациях — добавляем там, где частые выборки
create index if not exists idx_categories_master    on categories(master_id);
create index if not exists idx_services_master      on services(master_id);
create index if not exists idx_services_category    on services(category_id);
create index if not exists idx_service_photos_svc   on service_photos(service_id);
create index if not exists idx_schedules_master     on schedules(master_id);
create index if not exists idx_bookings_master_time on bookings(master_id, scheduled_at);
