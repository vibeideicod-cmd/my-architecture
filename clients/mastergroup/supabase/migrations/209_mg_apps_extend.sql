-- ============================================================
-- МГ-платформа — Миграция 209: расширение анкеты мастера
-- Этап 4 плана доработок:
-- • Новые поля: ожидания от команды, уровень AI, график встреч,
--   готовность к встречам мастеров во вторник 20:00 МСК.
-- • Семантика mg_context теперь — «тема МГ», city — «город + ЧП».
-- • RPC mg_submit_application расширена под новые поля с жёсткой
--   валидацией готовности к вторнику (без неё — rejection).
-- ============================================================

-- 1. Новые колонки в mg_applications (nullable для обратной совместимости
--    со старыми анкетами; обязательность проверяется в RPC при новой подаче)
alter table mg_applications
  add column if not exists team_expectations         text,
  add column if not exists ai_level                  text
    check (ai_level is null or ai_level in ('none','beginner','confident','advanced')),
  add column if not exists meetings_per_week         text,
  add column if not exists program_duration_weeks    text,
  add column if not exists tuesday_20_msk_commitment boolean default false;

comment on column mg_applications.city is
  'Город и часовой пояс (пример: Омск, +3 МСК)';
comment on column mg_applications.mg_context is
  'Тема мастер-группы, которую мастер будет вести';
comment on column mg_applications.goal is
  'Зачем мастер идёт в МГ, что должно измениться после участия';
comment on column mg_applications.team_expectations is
  'Что мастер ожидает от команды — какая конкретно помощь нужна';
comment on column mg_applications.ai_level is
  'Уровень владения нейросетями: none | beginner | confident | advanced';
comment on column mg_applications.meetings_per_week is
  'Сколько раз в неделю мастер планирует встречи с участниками';
comment on column mg_applications.program_duration_weeks is
  'На сколько недель рассчитана программа мастер-группы';
comment on column mg_applications.tuesday_20_msk_commitment is
  'Готовность приходить на встречу мастеров каждый вторник в 20:00 МСК';

-- 2. Обновление RPC подачи анкеты — принимаем расширенный payload
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
  v_ai_level text;
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

  if coalesce(trim(payload->>'city'), '') = '' then
    raise exception 'Укажи город и часовой пояс';
  end if;

  if coalesce(trim(payload->>'niche'), '') = '' then
    raise exception 'Укажи нишу — как ты сам называешь своё дело';
  end if;

  if coalesce(trim(payload->>'business_desc'), '') = '' then
    raise exception 'Опиши, чем занимаешься в своём бизнесе';
  end if;

  if coalesce(trim(payload->>'mg_context'), '') = '' then
    raise exception 'Укажи тему, на которую будешь проводить мастер-группу';
  end if;

  if coalesce(trim(payload->>'goal'), '') = '' then
    raise exception 'Опиши, зачем идёшь в мастер-группу — какая цель';
  end if;

  if coalesce(trim(payload->>'team_expectations'), '') = '' then
    raise exception 'Опиши, какая помощь от команды нужна';
  end if;

  v_ai_level := nullif(trim(payload->>'ai_level'), '');
  if v_ai_level is null then
    raise exception 'Выбери уровень владения нейросетями';
  end if;
  if v_ai_level not in ('none','beginner','confident','advanced') then
    raise exception 'Некорректный уровень владения нейросетями';
  end if;

  if coalesce(trim(payload->>'meetings_per_week'), '') = '' then
    raise exception 'Укажи, сколько раз в неделю планируешь встречаться с участниками';
  end if;

  if coalesce(trim(payload->>'program_duration_weeks'), '') = '' then
    raise exception 'Укажи длительность программы (в неделях)';
  end if;

  -- Жёсткое условие — без готовности к вторнику 20:00 МСК анкета не принимается
  if (payload->>'tuesday_20_msk_commitment')::boolean is not true then
    raise exception 'Встреча мастеров каждый вторник в 20:00 МСК — обязательное условие. Если не можешь присутствовать — к сожалению, анкета не может быть принята.';
  end if;

  insert into mg_applications (
    full_name, contact, city, niche,
    business_desc, mg_context, goal, experience, consent_pd,
    team_expectations, ai_level,
    meetings_per_week, program_duration_weeks,
    tuesday_20_msk_commitment
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
    true,
    nullif(trim(payload->>'team_expectations'), ''),
    v_ai_level,
    nullif(trim(payload->>'meetings_per_week'), ''),
    nullif(trim(payload->>'program_duration_weeks'), ''),
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
