-- ============================================================
-- МГ-платформа — Миграция 214: управление одобрениями
-- • Отозвать одобрение (revoke) — вернуть анкету в submitted,
--   удалить страницу мастера. Инна может одобрить заново или
--   отклонить. Использование: ошибочное одобрение, смена потока.
-- • Архив анкеты (archive) — унести анкету в архив (не показывать
--   в активной очереди), снять страницу с публикации. Страница
--   сохраняется но не доступна.
-- • Восстановить из архива (unarchive) — вернуть в previous status.
-- ============================================================

-- Расширяем check status: добавляем 'archived'
alter table mg_applications
  drop constraint if exists mg_applications_status_check;

alter table mg_applications
  add constraint mg_applications_status_check
    check (status in ('submitted','under_review','approved','rejected','archived'));

-- Колонка previous_status для восстановления из архива
alter table mg_applications
  add column if not exists previous_status text;

-- 1. Отозвать одобрение — DELETE master_page, вернуть анкету в submitted
create or replace function mg_admin_revoke_approval(
  app_id bigint,
  admin_secret text,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  correct_hash text := 'a5b4f151eae19e3decba7a00c66c1d487062791e3deb0d690594ad7923fac6a5';
  v_slug text;
begin
  if encode(digest(admin_secret, 'sha256'), 'hex') <> correct_hash then
    raise exception 'Неверный админ-ключ';
  end if;

  select slug into v_slug from mg_master_pages where application_id = app_id;

  -- Удаляем страницу мастера и всё связанное (leads по CASCADE)
  if v_slug is not null then
    delete from mg_master_pages where application_id = app_id;
  end if;

  -- Возвращаем анкету в начало
  update mg_applications
  set status = 'submitted',
      stage_1_approved_at = null,
      reviewed_at = null,
      reviewed_by = null,
      moderation_note = coalesce(p_note, moderation_note)
  where id = app_id;

  return jsonb_build_object('status', 'revoked', 'deleted_slug', v_slug);
end;
$$;

grant execute on function mg_admin_revoke_approval(bigint, text, text) to anon;

-- 2. Архивировать анкету — status='archived', снять страницу с публикации
create or replace function mg_admin_archive_application(
  app_id bigint,
  admin_secret text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  correct_hash text := 'a5b4f151eae19e3decba7a00c66c1d487062791e3deb0d690594ad7923fac6a5';
  v_current_status text;
begin
  if encode(digest(admin_secret, 'sha256'), 'hex') <> correct_hash then
    raise exception 'Неверный админ-ключ';
  end if;

  select status into v_current_status from mg_applications where id = app_id;
  if v_current_status is null then
    raise exception 'Анкета % не найдена', app_id;
  end if;
  if v_current_status = 'archived' then
    raise exception 'Анкета уже в архиве';
  end if;

  update mg_applications
  set previous_status = v_current_status,
      status = 'archived'
  where id = app_id;

  -- Снимаем страницу с публикации, но сохраняем данные
  update mg_master_pages
  set published = false
  where application_id = app_id;

  return jsonb_build_object('status', 'archived', 'previous_status', v_current_status);
end;
$$;

grant execute on function mg_admin_archive_application(bigint, text) to anon;

-- 3. Восстановить из архива — вернуть previous_status, перепубликовать страницу
create or replace function mg_admin_unarchive_application(
  app_id bigint,
  admin_secret text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  correct_hash text := 'a5b4f151eae19e3decba7a00c66c1d487062791e3deb0d690594ad7923fac6a5';
  v_previous text;
begin
  if encode(digest(admin_secret, 'sha256'), 'hex') <> correct_hash then
    raise exception 'Неверный админ-ключ';
  end if;

  select previous_status into v_previous from mg_applications where id = app_id;
  if v_previous is null then
    v_previous := 'submitted';
  end if;

  update mg_applications
  set status = v_previous,
      previous_status = null
  where id = app_id and status = 'archived';

  return jsonb_build_object('status', 'unarchived', 'restored_to', v_previous);
end;
$$;

grant execute on function mg_admin_unarchive_application(bigint, text) to anon;
