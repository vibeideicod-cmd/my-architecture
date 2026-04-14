-- ============================================================
-- МГ-платформа — Миграция 101: RLS и realtime
-- MVP-режим: широкое публичное чтение + insert. UPDATE/DELETE
-- запрещены через анонимный ключ. Кабинет гейтится токеном
-- на UI-уровне (хэш сравнивается в браузере).
-- ============================================================

alter table mg_masters      enable row level security;
alter table mg_participants enable row level security;
alter table mg_materials    enable row level security;
alter table mg_tasks        enable row level security;
alter table mg_messages     enable row level security;
alter table mg_cases        enable row level security;

-- ── Мастера: читать всем, писать только service_role ──────
drop policy if exists "mg_masters_read" on mg_masters;
create policy "mg_masters_read" on mg_masters for select using (true);

-- ── Участники: читать и создавать всем ────────────────────
drop policy if exists "mg_participants_read"   on mg_participants;
drop policy if exists "mg_participants_insert" on mg_participants;
create policy "mg_participants_read"   on mg_participants for select using (true);
create policy "mg_participants_insert" on mg_participants for insert with check (true);

-- ── Материалы: читать и создавать всем ────────────────────
drop policy if exists "mg_materials_read"   on mg_materials;
drop policy if exists "mg_materials_insert" on mg_materials;
create policy "mg_materials_read"   on mg_materials for select using (true);
create policy "mg_materials_insert" on mg_materials for insert with check (true);

-- ── Задания ───────────────────────────────────────────────
drop policy if exists "mg_tasks_read"   on mg_tasks;
drop policy if exists "mg_tasks_insert" on mg_tasks;
create policy "mg_tasks_read"   on mg_tasks for select using (true);
create policy "mg_tasks_insert" on mg_tasks for insert with check (true);

-- ── Сообщения ─────────────────────────────────────────────
drop policy if exists "mg_messages_read"   on mg_messages;
drop policy if exists "mg_messages_insert" on mg_messages;
create policy "mg_messages_read"   on mg_messages for select using (true);
create policy "mg_messages_insert" on mg_messages for insert with check (true);

-- ── Кейсы ─────────────────────────────────────────────────
drop policy if exists "mg_cases_read"   on mg_cases;
drop policy if exists "mg_cases_insert" on mg_cases;
create policy "mg_cases_read"   on mg_cases for select using (true);
create policy "mg_cases_insert" on mg_cases for insert with check (true);

-- ── Realtime publication ──────────────────────────────────
-- Чтобы кабинет мог в реальном времени ловить «записался новый человек»
-- и новые сообщения чата.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'mg_participants'
  ) then
    alter publication supabase_realtime add table mg_participants;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'mg_messages'
  ) then
    alter publication supabase_realtime add table mg_messages;
  end if;
end $$;
