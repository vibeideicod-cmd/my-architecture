-- ============================================================
-- МГ-платформа — Миграция 215: служба поддержки (Этап 5E)
-- Форма «Написать команде» на публичных страницах → сообщения
-- падают в админку. Инна закрепляет админку как «пульт управления».
-- Никаких уведомлений — всё читается в вкладке «Поддержка».
-- ============================================================

create table if not exists mg_support_messages (
  id           bigserial primary key,
  from_name    text,
  from_contact text,
  message      text not null,
  source_page  text,
  status       text not null default 'new'
                 check (status in ('new','read','resolved')),
  admin_note   text,
  created_at   timestamptz default now()
);

create index if not exists mg_support_messages_status_idx
  on mg_support_messages(status, created_at desc);

alter table mg_support_messages enable row level security;

-- Подача сообщения (публично, anon)
create or replace function mg_submit_support_message(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id bigint;
begin
  if coalesce(trim(payload->>'message'), '') = '' then
    raise exception 'Пустое сообщение';
  end if;
  if length(payload->>'message') > 4000 then
    raise exception 'Сообщение слишком длинное';
  end if;

  insert into mg_support_messages (from_name, from_contact, message, source_page)
  values (
    nullif(trim(payload->>'from_name'), ''),
    nullif(trim(payload->>'from_contact'), ''),
    trim(payload->>'message'),
    nullif(trim(payload->>'source_page'), '')
  )
  returning id into new_id;

  return jsonb_build_object('id', new_id, 'status', 'ok');
end;
$$;

grant execute on function mg_submit_support_message(jsonb) to anon;

-- Список сообщений для админа
create or replace function mg_admin_list_support_messages(admin_secret text)
returns setof mg_support_messages
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
    select * from mg_support_messages
    order by case status when 'new' then 0 when 'read' then 1 else 2 end,
             created_at desc;
end;
$$;

grant execute on function mg_admin_list_support_messages(text) to anon;

-- Обновление статуса сообщения
create or replace function mg_admin_update_support_status(
  admin_secret text,
  msg_id bigint,
  new_status text,
  p_note text default null
)
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
  if new_status not in ('new','read','resolved') then
    raise exception 'Недопустимый статус: %', new_status;
  end if;
  update mg_support_messages
    set status = new_status,
        admin_note = coalesce(p_note, admin_note)
    where id = msg_id;
end;
$$;

grant execute on function mg_admin_update_support_status(text, bigint, text, text) to anon;

-- Включаем realtime для вкладки "Поддержка"
alter publication supabase_realtime add table mg_support_messages;
