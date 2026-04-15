-- ============================================================
-- Beauty TMA — Миграция 007: RPC-функции для multi-tenant v2
--
-- Все модификации beauty_applications и masters идут через эти
-- функции. Прямой INSERT/UPDATE через anon ключ невозможен
-- (таблица beauty_applications закрыта RLS без policy).
--
-- Функции SECURITY DEFINER — выполняются с правами postgres,
-- могут писать и читать всё, но ВНУТРИ функции проверяют токен
-- (SHA-256 сырого токена должен совпасть с token_hash в БД).
--
-- Паттерн взят из МГ (clients/mastergroup/supabase/migrations/201_*).
--
-- ВАЖНО — админский пароль:
-- В функции beauty_moderate_application и beauty_list_applications
-- проверяется SHA-256 хэш пароля. Сейчас зашит хэш пароля
-- 'LavenderDream2026'. Если надо сменить — пересчитай SHA-256
-- нового пароля и ALTER этой функции (или сделай новую миграцию).
-- ============================================================

-- Для SHA-256 нам нужен pgcrypto
create extension if not exists pgcrypto;

-- ── Админ-пароль (хэш захардкожен) ──────────────────────
-- SHA-256('LavenderDream2026') = 99d51339e3892ec2ef9e0a19ac9b7982908a5c45459259ba9cb6c1b816b5a274
--
-- Проверка в функциях: encode(digest(p_admin_password, 'sha256'), 'hex')
-- должно совпасть с этой константой.

-- ── 1. submit_application — подать заявку ────────────────
-- Возвращает: app_id (номер заявки) и plain_token (показать мастеру ОДИН РАЗ)
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
set search_path = public
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

  -- Генерим сырой токен (32 hex символа = 128 бит случайности)
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
    'token',  v_plain_token  -- показываем мастеру один раз, в БД только хэш
  );
end;
$$;

-- ── 2. application_status — проверить статус по токену ──
-- Клиентское использование: status.html?t=<plain_token>
create or replace function beauty_application_status(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
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

-- ── 3. list_applications — админ-список всех заявок ─────
create or replace function beauty_list_applications(p_admin_password text)
returns setof beauty_applications
language plpgsql
security definer
set search_path = public
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

-- ── 4. moderate_application — одобрить или отклонить ────
-- При одобрении создаётся запись в masters с тем же token_hash.
-- Мастер сможет войти в кабинет по своему сохранённому plain_token.
create or replace function beauty_moderate_application(
  p_admin_password text,
  p_app_id         bigint,
  p_decision       text,  -- 'approved' | 'rejected'
  p_slug           text default null,  -- обязателен если approved
  p_note           text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
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

    -- Создаём мастера с тем же token_hash, что был в заявке
    insert into masters (id, name, specialty, city, token_hash, is_approved)
    values (p_slug, v_app.name, v_app.specialty, v_app.city, v_app.token_hash, true);

    -- Обновляем заявку
    update beauty_applications
       set status         = 'approved',
           master_slug    = p_slug,
           moderator_note = p_note,
           moderated_at   = now()
     where id = p_app_id;
  else
    -- rejected
    update beauty_applications
       set status         = 'rejected',
           moderator_note = coalesce(p_note, 'Отклонено без комментария'),
           moderated_at   = now()
     where id = p_app_id;
  end if;

  return jsonb_build_object('ok', true, 'decision', p_decision, 'slug', p_slug);
end;
$$;

-- ── 5. save_profile — мастер сохраняет свой профиль ──────
-- (Полноценный кабинет — задача Этапа 2. Заглушка для того
--  чтобы архитектура была готова к нему сейчас.)
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
set search_path = public
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

-- ── Доступы ──────────────────────────────────────────────
grant execute on function beauty_submit_application(text,text,text,text,text,text,text,boolean) to anon, authenticated;
grant execute on function beauty_application_status(text)                                         to anon, authenticated;
grant execute on function beauty_list_applications(text)                                          to anon, authenticated;
grant execute on function beauty_moderate_application(text,bigint,text,text,text)                 to anon, authenticated;
grant execute on function beauty_save_profile(text,text,text,text,text,text,text)                 to anon, authenticated;

-- ── Smoke-test (выполнить руками в SQL Editor) ───────────
-- 1. select beauty_submit_application('Тестовый Мастер','Москва','Маникюр',null,null,null,'Тест',true);
--    → {app_id: N, token: 'abc123...'} — сохрани токен!
-- 2. select beauty_application_status('abc123...');
--    → {found: true, status: 'pending', ...}
-- 3. select beauty_list_applications('LavenderDream2026');
--    → список всех заявок
-- 4. select beauty_moderate_application('LavenderDream2026', N, 'approved', 'test-master');
--    → {ok: true, decision: 'approved', slug: 'test-master'}
-- 5. select beauty_application_status('abc123...');
--    → {found: true, status: 'approved', master_slug: 'test-master'}
