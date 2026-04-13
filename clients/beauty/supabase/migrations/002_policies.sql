-- ============================================================
-- Beauty TMA — Миграция 002: Row Level Security (замки)
-- Supabase по умолчанию блокирует ВСЁ. Мы сами открываем нужные двери.
--
-- Правила доступа для MVP:
--   • каталог (мастер, категории, услуги, фото, расписание) — читать всем
--   • брони — создавать может кто угодно, читать нельзя никому извне
--     (бронями будем управлять через Supabase Dashboard или service_role ключ)
-- ============================================================

-- Включаем RLS на всех таблицах
alter table masters        enable row level security;
alter table categories     enable row level security;
alter table services       enable row level security;
alter table service_photos enable row level security;
alter table schedules      enable row level security;
alter table bookings       enable row level security;

-- ── Публичное чтение каталога ───────────────────────────
-- Любой, у кого есть anon key, может читать эти таблицы.
-- Это нормально — это публичная витрина мастера.

drop policy if exists "public_read_masters"        on masters;
drop policy if exists "public_read_categories"     on categories;
drop policy if exists "public_read_services"       on services;
drop policy if exists "public_read_service_photos" on service_photos;
drop policy if exists "public_read_schedules"      on schedules;

create policy "public_read_masters"
  on masters        for select using (true);

create policy "public_read_categories"
  on categories     for select using (is_active = true);

create policy "public_read_services"
  on services       for select using (is_active = true);

create policy "public_read_service_photos"
  on service_photos for select using (true);

create policy "public_read_schedules"
  on schedules      for select using (true);

-- ── Брони ────────────────────────────────────────────────
-- INSERT разрешён всем (клиенты записываются анонимно).
-- SELECT / UPDATE / DELETE запрещены полностью — через anon key
-- брони не читаются и не правятся. Мастер видит их через Dashboard
-- или через service_role ключ (когда позже будет админ-кабинет).

drop policy if exists "public_create_bookings" on bookings;

create policy "public_create_bookings"
  on bookings for insert
  with check (true);
