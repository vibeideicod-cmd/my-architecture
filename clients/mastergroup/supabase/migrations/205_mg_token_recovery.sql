-- ============================================================
-- МГ-платформа v2 — Миграция 205: восстановление ссылки конструктора
-- Проблема: мастер-токен раньше показывался один раз в модалке админки,
-- а в БД лежал только SHA-256 hash. Если мастер терял ссылку — ему
-- приходилось подавать анкету заново. Плохой UX.
--
-- Решение: храним raw token в отдельной колонке token_plain, доступ
-- только через admin RPC. Для старых страниц — fallback на регенерацию.
-- ============================================================

-- ── Добавляем колонку для raw токена ──────────────────────
alter table mg_master_pages
  add column if not exists token_plain text;

-- ── Обновляем mg_moderate: сохраняем raw токен тоже ───────
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
  existing_token text;
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

  -- Уже одобрена? Возвращаем существующий токен (если сохранён) — идемпотентно
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

  update mg_applications
  set status = new_status,
      moderation_note = note,
      reviewed_at = now(),
      reviewed_by = 'admin'
  where id = app_id;

  if new_status = 'rejected' then
    return jsonb_build_object('status', 'rejected');
  end if;

  -- approved: создаём страницу мастера с сохранением raw токена
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

-- ── RPC: получить ссылку на конструктор по slug ───────────
-- Возвращает raw токен. Если token_plain NULL (старые страницы
-- до миграции 205) — возвращает null, тогда админ должен перевыпустить.
create or replace function mg_admin_get_master_link(
  admin_secret text,
  p_slug text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  correct_hash text := 'a5b4f151eae19e3decba7a00c66c1d487062791e3deb0d690594ad7923fac6a5';
  found_token text;
  found_name text;
  found_number int;
begin
  if encode(digest(admin_secret, 'sha256'), 'hex') <> correct_hash then
    raise exception 'Неверный админ-ключ';
  end if;

  select p.token_plain, coalesce(p.display_name, a.full_name), p.master_number
  into found_token, found_name, found_number
  from mg_master_pages p
  left join mg_applications a on a.id = p.application_id
  where p.slug = p_slug;

  if not found then
    raise exception 'Страница % не найдена', p_slug;
  end if;

  return jsonb_build_object(
    'slug', p_slug,
    'master_token', found_token,
    'master_name', found_name,
    'master_number', found_number,
    'needs_regenerate', found_token is null
  );
end;
$$;

grant execute on function mg_admin_get_master_link(text, text) to anon;

-- ── RPC: перевыпустить токен (fallback для старых страниц) ────
-- Генерирует новый токен, обновляет token_hash + token_plain.
-- Старая ссылка перестаёт работать.
create or replace function mg_admin_regenerate_token(
  admin_secret text,
  p_slug text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  correct_hash text := 'a5b4f151eae19e3decba7a00c66c1d487062791e3deb0d690594ad7923fac6a5';
  new_token text;
  new_token_hash text;
begin
  if encode(digest(admin_secret, 'sha256'), 'hex') <> correct_hash then
    raise exception 'Неверный админ-ключ';
  end if;

  if not exists (select 1 from mg_master_pages where slug = p_slug) then
    raise exception 'Страница % не найдена', p_slug;
  end if;

  new_token := encode(gen_random_bytes(16), 'hex');
  new_token_hash := encode(digest(new_token, 'sha256'), 'hex');

  update mg_master_pages
  set token_hash = new_token_hash,
      token_plain = new_token,
      updated_at = now()
  where slug = p_slug;

  return jsonb_build_object(
    'slug', p_slug,
    'master_token', new_token
  );
end;
$$;

grant execute on function mg_admin_regenerate_token(text, text) to anon;
