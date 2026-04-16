-- ============================================================
-- МГ-платформа v2 — Миграция 206: Storage bucket для фото мастеров
-- Мастера загружают фото через конструктор, файл летит в Supabase Storage.
-- Публичный bucket — фото доступны всем (они на публичных страницах).
-- ============================================================

-- ── Создаём bucket (если ещё нет) ─────────────────────────
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'mg-photos',
  'mg-photos',
  true,
  5242880, -- 5 MB
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do nothing;

-- ── RLS: кто угодно может загрузить (anon через publishable key) ──
create policy "mg_photos_upload" on storage.objects
  for insert
  with check (bucket_id = 'mg-photos');

-- ── RLS: кто угодно может читать (публичные фото) ─────────
create policy "mg_photos_read" on storage.objects
  for select
  using (bucket_id = 'mg-photos');

-- ── RLS: обновление (перезаливка фото) ────────────────────
create policy "mg_photos_update" on storage.objects
  for update
  using (bucket_id = 'mg-photos');
