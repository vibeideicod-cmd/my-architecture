-- ============================================================
-- МГ-платформа — Миграция 210: двухэтапное одобрение мастера
-- Этап 5A:
-- • pre_approve — Инна одобряет анкету, мастер получает ссылку
--   на рабочую группу мастеров в Telegram (пока, в будущем может
--   мигрировать в VK/MAX — ссылку держим в mg_config чтобы менять
--   без деплоя).
-- • approved (финальное одобрение) — после общения в рабочей
--   группе мастер получает доступ к конструктору.
-- • rejected — без изменений.
-- ============================================================

-- 1. Таблица mg_config — простые key-value настройки платформы
create table if not exists mg_config (
  key   text primary key,
  value text not null,
  updated_at timestamptz default now()
);

comment on table mg_config is
  'Key-value конфиг МГ-платформы. Публично читаемые через mg_get_config_public, приватные — через mg_admin_get_config.';

-- Какие ключи разрешено читать анонимно (публично)
create table if not exists mg_config_public_keys (
  key text primary key
);

insert into mg_config_public_keys (key) values
  ('working_group_url')
on conflict (key) do nothing;

-- Дефолтное значение ссылки на рабочую группу мастеров
insert into mg_config (key, value) values
  ('working_group_url', 'https://t.me/+s6crmZGMv_cyZjc6')
on conflict (key) do nothing;

-- RLS: закрываем прямой доступ, работаем через RPC
alter table mg_config enable row level security;
alter table mg_config_public_keys enable row level security;

-- 2. Колонка времени первого одобрения
alter table mg_applications
  add column if not exists stage_1_approved_at timestamptz;

comment on column mg_applications.stage_1_approved_at is
  'Время первого одобрения (Инна дала ссылку на рабочую группу). Финальное одобрение — status = approved.';

-- 3. Публичное чтение конфига (только разрешённые ключи)
create or replace function mg_get_config_public(p_key text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_value text;
begin
  if not exists (select 1 from mg_config_public_keys where key = p_key) then
    raise exception 'Ключ % не разрешён для публичного чтения', p_key;
  end if;

  select value into v_value from mg_config where key = p_key;
  return v_value;
end;
$$;

grant execute on function mg_get_config_public(text) to anon;

-- 4. Админское чтение любого ключа конфига
create or replace function mg_admin_get_config(admin_secret text, p_key text)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  correct_hash text := 'a5b4f151eae19e3decba7a00c66c1d487062791e3deb0d690594ad7923fac6a5';
  v_value text;
begin
  if encode(digest(admin_secret, 'sha256'), 'hex') <> correct_hash then
    raise exception 'Неверный админ-ключ';
  end if;
  select value into v_value from mg_config where key = p_key;
  return v_value;
end;
$$;

grant execute on function mg_admin_get_config(text, text) to anon;

-- 5. Админское обновление конфига
create or replace function mg_admin_set_config(admin_secret text, p_key text, p_value text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  correct_hash text := 'a5b4f151eae19e3decba7a00c66c1d487062791e3deb0d690594ad7923fac6a5';
begin
  if encode(digest(admin_secret, 'sha256'), 'hex') <> correct_hash then
    raise exception 'Неверный админ-ключ';
  end if;
  insert into mg_config (key, value, updated_at)
    values (p_key, p_value, now())
    on conflict (key) do update set value = excluded.value, updated_at = now();
end;
$$;

grant execute on function mg_admin_set_config(text, text, text) to anon;

-- 6. Обновляем mg_moderate: добавляем статус 'pre_approved'
create or replace function mg_moderate(
  app_id bigint,
  new_status text,
  note text,
  admin_secret text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  correct_hash text := 'a5b4f151eae19e3decba7a00c66c1d487062791e3deb0d690594ad7923fac6a5';
  master_number_val int;
  stage_1_val timestamptz;
  new_slug text;
  new_token text;
  new_token_hash text;
  existing_slug text;
  existing_token text;
begin
  if encode(digest(admin_secret, 'sha256'), 'hex') <> correct_hash then
    raise exception 'Неверный админ-ключ';
  end if;

  if new_status not in ('pre_approved', 'approved', 'rejected') then
    raise exception 'Недопустимый статус: % (ожидается pre_approved / approved / rejected)', new_status;
  end if;

  select master_number, stage_1_approved_at
    into master_number_val, stage_1_val
    from mg_applications where id = app_id;
  if not found then
    raise exception 'Анкета % не найдена', app_id;
  end if;

  -- Идемпотентность финального одобрения
  select slug, token_plain into existing_slug, existing_token
  from mg_master_pages where application_id = app_id;

  if existing_slug is not null and new_status = 'approved' then
    return jsonb_build_object(
      'status', 'already_approved',
      'slug', existing_slug,
      'master_token', existing_token,
      'master_number', master_number_val
    );
  end if;

  -- Ветка 1: pre_approved — даём ссылку на рабочую группу
  if new_status = 'pre_approved' then
    update mg_applications
    set status = 'under_review',      -- для админской фильтрации оставляем under_review
        stage_1_approved_at = coalesce(stage_1_approved_at, now()),
        moderation_note = coalesce(note, moderation_note),
        reviewed_at = now(),
        reviewed_by = 'admin'
    where id = app_id;

    return jsonb_build_object(
      'status', 'pre_approved',
      'working_group_url', (select value from mg_config where key = 'working_group_url'),
      'master_number', master_number_val
    );
  end if;

  -- Ветка 2: rejected
  if new_status = 'rejected' then
    update mg_applications
    set status = 'rejected',
        moderation_note = note,
        reviewed_at = now(),
        reviewed_by = 'admin'
    where id = app_id;
    return jsonb_build_object('status', 'rejected');
  end if;

  -- Ветка 3: approved (финальное) — требует предварительного pre_approved
  if stage_1_val is null then
    raise exception 'Финальное одобрение возможно только после первого одобрения (ссылка на рабочую группу)';
  end if;

  update mg_applications
  set status = 'approved',
      moderation_note = coalesce(note, moderation_note),
      reviewed_at = now(),
      reviewed_by = 'admin'
  where id = app_id;

  new_slug := 'master-' || master_number_val;
  new_token := encode(gen_random_bytes(16), 'hex');
  new_token_hash := encode(digest(new_token, 'sha256'), 'hex');

  insert into mg_master_pages (slug, application_id, master_number, token_hash, token_plain)
  values (new_slug, app_id, master_number_val, new_token_hash, new_token);

  return jsonb_build_object(
    'status', 'approved',
    'slug', new_slug,
    'master_token', new_token,
    'master_number', master_number_val
  );
end;
$$;

-- 7. Обновляем mg_get_application_by_token — возвращаем stage_1_approved_at и ссылку на группу
create or replace function mg_get_application_by_token(token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
  v_working_group_url text;
begin
  select value into v_working_group_url from mg_config where key = 'working_group_url';

  select jsonb_build_object(
    'full_name', full_name,
    'niche', niche,
    'status', status,
    'moderation_note', moderation_note,
    'created_at', created_at,
    'reviewed_at', reviewed_at,
    'stage_1_approved_at', stage_1_approved_at,
    'working_group_url', v_working_group_url,
    'master_slug', (select slug from mg_master_pages where application_id = a.id),
    'master_number', a.master_number
  )
  into result
  from mg_applications a
  where application_token = token
  limit 1;

  return result;
end;
$$;

grant execute on function mg_get_application_by_token(text) to anon;
