-- ============================================================
-- МГ-платформа v2 — Миграция 201: RLS + RPC + realtime
-- Все модификации mg_applications / mg_master_pages / mg_leads
-- идут через RPC security definer. Прямые INSERT/UPDATE закрыты.
-- ============================================================

-- ── Включаем RLS на всех новых таблицах ───────────────────
alter table mg_applications    enable row level security;
alter table mg_master_pages    enable row level security;
alter table mg_config_questions enable row level security;
alter table mg_leads           enable row level security;

-- ── Справочник вопросов — публичное чтение ────────────────
drop policy if exists "mg_config_questions_public_read" on mg_config_questions;
create policy "mg_config_questions_public_read" on mg_config_questions
  for select using (true);

-- ── Публичная view одобренных страниц ─────────────────────
-- (anon читает только опубликованные страницы, без token_hash)
drop view if exists mg_master_pages_public;
create view mg_master_pages_public as
  select slug, display_name, page_config, published_at, master_number
  from mg_master_pages
  where published = true;

grant select on mg_master_pages_public to anon;
grant select on mg_master_pages_public to authenticated;

-- ── Preview view (draft + published) — для конструктора ───
-- Гейтинг идёт на уровне RPC/JS через токен, здесь view просто
-- чтобы JS мог селектить нужный slug без открытия таблицы
drop view if exists mg_master_pages_preview;
create view mg_master_pages_preview as
  select slug, display_name, page_config, published, master_number
  from mg_master_pages;

grant select on mg_master_pages_preview to anon;

-- ============================================================
-- RPC функции (security definer, безопасная поверхность)
-- ============================================================

-- ── 1. Подача анкеты ──────────────────────────────────────
create or replace function mg_submit_application(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
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

grant execute on function mg_submit_application(jsonb) to anon;

-- ── 2. Получить анкету по токену (для status.html) ────────
create or replace function mg_get_application_by_token(token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  select jsonb_build_object(
    'full_name', full_name,
    'niche', niche,
    'status', status,
    'moderation_note', moderation_note,
    'created_at', created_at,
    'reviewed_at', reviewed_at,
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

-- ── 3. Модерация анкеты (Инна, по паролю) ─────────────────
create or replace function mg_moderate(
  app_id bigint,
  new_status text,
  note text,
  admin_secret text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  correct_hash text := 'a5b4f151eae19e3decba7a00c66c1d487062791e3deb0d690594ad7923fac6a5'; -- SHA-256 от 'nbcccp-2026'
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

  -- Проверка: уже одобрена?
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

  -- approved: создаём страницу мастера
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

grant execute on function mg_moderate(bigint, text, text, text) to anon;

-- ── 4. Сохранить изменения страницы (merge patch) ─────────
create or replace function mg_save_page(
  p_slug text,
  p_token text,
  p_patch jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
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

grant execute on function mg_save_page(text, text, jsonb) to anon;

-- ── 5. Публикация страницы ────────────────────────────────
create or replace function mg_publish_page(p_slug text, p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
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

  -- Проверка обязательных полей
  missing := array[]::text[];
  if coalesce(cfg->'hero'->>'display_name', '') = '' then missing := array_append(missing, 'display_name'); end if;
  if coalesce(cfg->'hero'->>'headline', '') = '' then missing := array_append(missing, 'headline'); end if;
  if coalesce(cfg->'about'->>'bio', '') = '' then missing := array_append(missing, 'bio'); end if;
  if coalesce(cfg->'offer'->>'title', '') = '' then missing := array_append(missing, 'offer_title'); end if;
  if coalesce(cfg->'offer'->>'description', '') = '' then missing := array_append(missing, 'offer_desc'); end if;
  if coalesce(cfg->'cta'->>'text', '') = '' then missing := array_append(missing, 'cta_text'); end if;
  -- cta_link_value может быть пустым если link_type = 'form'
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

grant execute on function mg_publish_page(text, text) to anon;

-- ── 6. Отправка заявки от посетителя ──────────────────────
create or replace function mg_submit_lead(
  p_master_slug text,
  p_visitor_name text,
  p_visitor_contact text,
  p_message text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id bigint;
begin
  if coalesce(trim(p_visitor_name), '') = '' then
    raise exception 'Укажи имя';
  end if;
  if coalesce(trim(p_visitor_contact), '') = '' then
    raise exception 'Укажи контакт';
  end if;

  -- Страница должна существовать и быть опубликована
  if not exists (select 1 from mg_master_pages where slug = p_master_slug and published = true) then
    raise exception 'Страница не найдена';
  end if;

  insert into mg_leads (master_slug, visitor_name, visitor_contact, message)
  values (p_master_slug, trim(p_visitor_name), trim(p_visitor_contact), nullif(trim(p_message), ''))
  returning id into new_id;

  return jsonb_build_object('lead_id', new_id);
end;
$$;

grant execute on function mg_submit_lead(text, text, text, text) to anon;

-- ── 7. Список анкет для админки Инны ──────────────────────
create or replace function mg_admin_list_applications(admin_secret text)
returns setof mg_applications
language plpgsql
security definer
set search_path = public
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

grant execute on function mg_admin_list_applications(text) to anon;

-- ── 8. Список собранных страниц для админки ───────────────
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
set search_path = public
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

grant execute on function mg_admin_list_pages(text) to anon;

-- ── Realtime publication для админки Инны ─────────────────
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'mg_applications'
  ) then
    alter publication supabase_realtime add table mg_applications;
  end if;
end $$;
