-- ============================================================
-- МГ-платформа v2 — Миграция 203: fix search_path для pgcrypto
-- Supabase устанавливает pgcrypto в схему `extensions`, а не public.
-- Добавляем extensions в search_path во все функции, которые
-- используют gen_random_bytes / digest.
-- ============================================================

-- ── Триггерная функция автонумерации ──────────────────────
create or replace function mg_assign_master_number()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
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

-- ── mg_submit_application ─────────────────────────────────
create or replace function mg_submit_application(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  new_id bigint;
  new_token text;
  new_number int;
begin
  if (payload->>'consent_pd')::boolean is not true then
    raise exception 'Согласие на обработку персональных данных обязательно';
  end if;

  if coalesce(trim(payload->>'full_name'), '') = '' then
    raise exception 'Укажи имя';
  end if;

  if coalesce(trim(payload->>'contact'), '') = '' then
    raise exception 'Укажи контакт — куда с тобой связаться';
  end if;

  insert into mg_applications (
    full_name, contact, city, niche,
    business_desc, mg_context, goal, experience, consent_pd
  )
  values (
    trim(payload->>'full_name'),
    trim(payload->>'contact'),
    nullif(trim(payload->>'city'), ''),
    nullif(trim(payload->>'niche'), ''),
    nullif(trim(payload->>'business_desc'), ''),
    nullif(trim(payload->>'mg_context'), ''),
    nullif(trim(payload->>'goal'), ''),
    nullif(trim(payload->>'experience'), ''),
    true
  )
  returning id, master_number, application_token
  into new_id, new_number, new_token;

  return jsonb_build_object(
    'application_id', new_id,
    'master_number', new_number,
    'application_token', new_token
  );
end;
$$;

-- ── mg_moderate ───────────────────────────────────────────
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
  new_slug text;
  new_token text;
  new_token_hash text;
  existing_slug text;
begin
  if encode(digest(admin_secret, 'sha256'), 'hex') <> correct_hash then
    raise exception 'Неверный админ-ключ';
  end if;

  if new_status not in ('approved', 'rejected') then
    raise exception 'Недопустимый статус: %', new_status;
  end if;

  select master_number into master_number_val from mg_applications where id = app_id;
  if not found then
    raise exception 'Анкета % не найдена', app_id;
  end if;

  select slug into existing_slug from mg_master_pages where application_id = app_id;
  if existing_slug is not null and new_status = 'approved' then
    return jsonb_build_object(
      'status', 'already_approved',
      'slug', existing_slug,
      'master_number', master_number_val
    );
  end if;

  update mg_applications
  set status = new_status,
      moderation_note = note,
      reviewed_at = now(),
      reviewed_by = 'inna'
  where id = app_id;

  if new_status = 'rejected' then
    return jsonb_build_object('status', 'rejected');
  end if;

  new_slug := 'master-' || master_number_val;
  new_token := encode(gen_random_bytes(16), 'hex');
  new_token_hash := encode(digest(new_token, 'sha256'), 'hex');

  insert into mg_master_pages (slug, application_id, master_number, token_hash)
  values (new_slug, app_id, master_number_val, new_token_hash);

  return jsonb_build_object(
    'status', 'approved',
    'slug', new_slug,
    'master_token', new_token,
    'master_number', master_number_val
  );
end;
$$;

-- ── mg_save_page ──────────────────────────────────────────
create or replace function mg_save_page(
  p_slug text,
  p_token text,
  p_patch jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  stored_hash text;
  new_version int;
begin
  select token_hash into stored_hash from mg_master_pages where slug = p_slug;
  if not found then
    raise exception 'Страница % не найдена', p_slug;
  end if;

  if encode(digest(p_token, 'sha256'), 'hex') <> stored_hash then
    raise exception 'Неверный токен';
  end if;

  update mg_master_pages
  set page_config = page_config || p_patch,
      version = version + 1,
      updated_at = now()
  where slug = p_slug
  returning version into new_version;

  return jsonb_build_object('version', new_version);
end;
$$;

-- ── mg_publish_page ───────────────────────────────────────
create or replace function mg_publish_page(p_slug text, p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  stored_hash text;
  cfg jsonb;
  missing text[];
begin
  select token_hash, page_config into stored_hash, cfg
  from mg_master_pages where slug = p_slug;
  if not found then
    raise exception 'Страница % не найдена', p_slug;
  end if;

  if encode(digest(p_token, 'sha256'), 'hex') <> stored_hash then
    raise exception 'Неверный токен';
  end if;

  missing := array[]::text[];
  if coalesce(cfg->'hero'->>'display_name', '') = '' then missing := array_append(missing, 'display_name'); end if;
  if coalesce(cfg->'hero'->>'headline', '') = '' then missing := array_append(missing, 'headline'); end if;
  if coalesce(cfg->'about'->>'bio', '') = '' then missing := array_append(missing, 'bio'); end if;
  if coalesce(cfg->'offer'->>'title', '') = '' then missing := array_append(missing, 'offer_title'); end if;
  if coalesce(cfg->'offer'->>'description', '') = '' then missing := array_append(missing, 'offer_desc'); end if;
  if coalesce(cfg->'cta'->>'text', '') = '' then missing := array_append(missing, 'cta_text'); end if;
  if coalesce(cfg->'cta'->>'link_type', '') = '' then missing := array_append(missing, 'cta_link_type'); end if;
  if (cfg->'cta'->>'link_type') <> 'form' and coalesce(cfg->'cta'->>'link_value', '') = '' then
    missing := array_append(missing, 'cta_link_value');
  end if;

  if array_length(missing, 1) > 0 then
    return jsonb_build_object('published', false, 'missing', to_jsonb(missing));
  end if;

  update mg_master_pages
  set published = true,
      published_at = now()
  where slug = p_slug;

  return jsonb_build_object('published', true, 'slug', p_slug);
end;
$$;

-- ── mg_admin_list_applications ────────────────────────────
create or replace function mg_admin_list_applications(admin_secret text)
returns setof mg_applications
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
  return query select * from mg_applications order by created_at desc;
end;
$$;

-- ── mg_admin_list_pages ───────────────────────────────────
create or replace function mg_admin_list_pages(admin_secret text)
returns table (
  slug text,
  master_number int,
  display_name text,
  published boolean,
  published_at timestamptz,
  version int,
  updated_at timestamptz,
  full_name text,
  niche text
)
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
  return query
    select p.slug, p.master_number, p.display_name, p.published, p.published_at,
           p.version, p.updated_at, a.full_name, a.niche
    from mg_master_pages p
    join mg_applications a on a.id = p.application_id
    order by p.created_at desc;
end;
$$;
