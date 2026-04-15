-- ============================================================
-- Beauty TMA — Миграция 008: Fix search_path для pgcrypto
--
-- В Supabase pgcrypto устанавливается в схему 'extensions',
-- а не в 'public'. Функции из миграции 007 были объявлены
-- с `set search_path = public` — поэтому не находят
-- gen_random_bytes и digest.
--
-- Фикс: меняем search_path на `public, extensions`.
-- CREATE OR REPLACE заменяет существующие функции.
-- ============================================================

-- 1. submit_application
create or replace function beauty_submit_application(
  p_name          text,
  p_city          text,
  p_specialty     text,
  p_telegram      text default null,
  p_phone         text default null,
  p_portfolio_url text default null,
  p_about         text default null,
  p_agreed_pd     boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_plain_token text;
  v_token_hash  text;
  v_app_id      bigint;
begin
  if not p_agreed_pd then
    raise exception 'Требуется согласие на обработку персональных данных';
  end if;

  if length(coalesce(p_name, '')) < 2 then
    raise exception 'Имя должно быть минимум 2 символа';
  end if;

  v_plain_token := encode(gen_random_bytes(16), 'hex');
  v_token_hash  := encode(digest(v_plain_token, 'sha256'), 'hex');

  insert into beauty_applications (
    name, city, specialty, telegram, phone, portfolio_url, about, agreed_pd, token_hash
  )
  values (
    p_name, p_city, p_specialty, p_telegram, p_phone, p_portfolio_url, p_about, p_agreed_pd, v_token_hash
  )
  returning id into v_app_id;

  return jsonb_build_object(
    'app_id', v_app_id,
    'token',  v_plain_token
  );
end;
$$;

-- 2. application_status
create or replace function beauty_application_status(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_app beauty_applications%rowtype;
  v_hash text;
begin
  if p_token is null or length(p_token) < 8 then
    return jsonb_build_object('found', false);
  end if;
  v_hash := encode(digest(p_token, 'sha256'), 'hex');

  select * into v_app
  from beauty_applications
  where token_hash = v_hash;

  if not found then
    return jsonb_build_object('found', false);
  end if;

  return jsonb_build_object(
    'found',           true,
    'app_id',          v_app.id,
    'name',            v_app.name,
    'city',            v_app.city,
    'specialty',       v_app.specialty,
    'status',          v_app.status,
    'master_slug',     v_app.master_slug,
    'moderator_note',  v_app.moderator_note,
    'created_at',      v_app.created_at,
    'moderated_at',    v_app.moderated_at
  );
end;
$$;

-- 3. list_applications
create or replace function beauty_list_applications(p_admin_password text)
returns setof beauty_applications
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if encode(digest(p_admin_password, 'sha256'), 'hex')
     <> '99d51339e3892ec2ef9e0a19ac9b7982908a5c45459259ba9cb6c1b816b5a274'
  then
    raise exception 'Неверный админ-пароль';
  end if;

  return query
    select * from beauty_applications
    order by
      case status when 'pending' then 0 when 'approved' then 1 else 2 end,
      created_at desc;
end;
$$;

-- 4. moderate_application
create or replace function beauty_moderate_application(
  p_admin_password text,
  p_app_id         bigint,
  p_decision       text,
  p_slug           text default null,
  p_note           text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_app beauty_applications%rowtype;
begin
  if encode(digest(p_admin_password, 'sha256'), 'hex')
     <> '99d51339e3892ec2ef9e0a19ac9b7982908a5c45459259ba9cb6c1b816b5a274'
  then
    raise exception 'Неверный админ-пароль';
  end if;

  if p_decision not in ('approved','rejected') then
    raise exception 'decision должен быть approved или rejected';
  end if;

  select * into v_app from beauty_applications where id = p_app_id;
  if not found then
    raise exception 'Заявка % не найдена', p_app_id;
  end if;

  if v_app.status <> 'pending' then
    raise exception 'Заявка уже промодерирована (статус: %)', v_app.status;
  end if;

  if p_decision = 'approved' then
    if p_slug is null or length(p_slug) < 2 then
      raise exception 'При одобрении нужен slug (минимум 2 символа)';
    end if;
    if p_slug !~ '^[a-z0-9-]+$' then
      raise exception 'slug должен содержать только lowercase латиницу, цифры и дефис';
    end if;
    if exists(select 1 from masters where id = p_slug) then
      raise exception 'Мастер со slug % уже существует', p_slug;
    end if;

    insert into masters (id, name, specialty, city, token_hash, is_approved)
    values (p_slug, v_app.name, v_app.specialty, v_app.city, v_app.token_hash, true);

    update beauty_applications
       set status         = 'approved',
           master_slug    = p_slug,
           moderator_note = p_note,
           moderated_at   = now()
     where id = p_app_id;
  else
    update beauty_applications
       set status         = 'rejected',
           moderator_note = coalesce(p_note, 'Отклонено без комментария'),
           moderated_at   = now()
     where id = p_app_id;
  end if;

  return jsonb_build_object('ok', true, 'decision', p_decision, 'slug', p_slug);
end;
$$;

-- 5. save_profile
create or replace function beauty_save_profile(
  p_slug    text,
  p_token   text,
  p_name    text default null,
  p_bio     text default null,
  p_avatar  text default null,
  p_accent  text default null,
  p_status  text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_hash text;
begin
  v_hash := encode(digest(p_token, 'sha256'), 'hex');

  if not exists(
    select 1 from masters
    where id = p_slug and token_hash = v_hash
  ) then
    raise exception 'Неверный токен для мастера %', p_slug;
  end if;

  update masters set
    name         = coalesce(p_name,   name),
    bio          = coalesce(p_bio,    bio),
    avatar_url   = coalesce(p_avatar, avatar_url),
    accent_color = coalesce(p_accent, accent_color),
    status_text  = coalesce(p_status, status_text)
  where id = p_slug;

  return jsonb_build_object('ok', true);
end;
$$;
