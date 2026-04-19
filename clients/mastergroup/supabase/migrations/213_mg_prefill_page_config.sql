-- ============================================================
-- МГ-платформа — Миграция 213: предзаполнение page_config из анкеты
-- Этап 5B:
-- При финальном одобрении автоматически переносим в page_config:
-- • hero.display_name ← full_name из анкеты
-- • hero.headline     ← пусто (мастер заполнит название МГ)
-- • about.bio         ← business_desc (чем занимаешься в бизнесе)
-- • program.program_content ← mg_context (тема мастер-группы)
-- Мастер открывает конструктор и видит часть полей уже заполненными.
-- Может править всё.
-- ============================================================

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
  v_full_name text;
  v_business_desc text;
  v_mg_context text;
  new_slug text;
  new_token text;
  new_token_hash text;
  new_page_config jsonb;
  existing_slug text;
  existing_token text;
begin
  if encode(digest(admin_secret, 'sha256'), 'hex') <> correct_hash then
    raise exception 'Неверный админ-ключ';
  end if;

  if new_status not in ('pre_approved', 'approved', 'rejected') then
    raise exception 'Недопустимый статус: % (ожидается pre_approved / approved / rejected)', new_status;
  end if;

  select master_number, stage_1_approved_at, full_name, business_desc, mg_context
    into master_number_val, stage_1_val, v_full_name, v_business_desc, v_mg_context
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

  -- pre_approved — даём ссылку на рабочую группу
  if new_status = 'pre_approved' then
    update mg_applications
    set status = 'under_review',
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

  -- rejected
  if new_status = 'rejected' then
    update mg_applications
    set status = 'rejected',
        moderation_note = note,
        reviewed_at = now(),
        reviewed_by = 'admin'
    where id = app_id;
    return jsonb_build_object('status', 'rejected');
  end if;

  -- approved (финальное): требует pre_approved
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

  -- Собираем предзаполненный page_config из анкеты
  new_page_config := jsonb_build_object(
    'hero', jsonb_build_object(
      'display_name', coalesce(v_full_name, ''),
      'headline',     ''  -- мастер впишет название своей мастер-группы
    ),
    'about', jsonb_build_object(
      'bio', coalesce(v_business_desc, '')
    ),
    'program', jsonb_build_object(
      'program_content', coalesce(v_mg_context, '')
    )
  );

  insert into mg_master_pages (slug, application_id, master_number, token_hash, token_plain, page_config)
  values (new_slug, app_id, master_number_val, new_token_hash, new_token, new_page_config);

  return jsonb_build_object(
    'status', 'approved',
    'slug', new_slug,
    'master_token', new_token,
    'master_number', master_number_val
  );
end;
$$;
