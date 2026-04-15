-- ============================================================
-- МГ-платформа v2 — Миграция 204: админский доступ к лидам
-- Добавляет RPC mg_admin_list_leads (с именем мастера через join)
-- и включает mg_leads в realtime publication.
-- ============================================================

-- ── RPC: список лидов для админки Инны ────────────────────
create or replace function mg_admin_list_leads(admin_secret text)
returns table (
  id              bigint,
  master_slug     text,
  master_name     text,
  master_number   int,
  visitor_name    text,
  visitor_contact text,
  message         text,
  created_at      timestamptz
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
    select l.id,
           l.master_slug,
           coalesce(p.display_name, a.full_name) as master_name,
           p.master_number,
           l.visitor_name,
           l.visitor_contact,
           l.message,
           l.created_at
    from mg_leads l
    left join mg_master_pages p on p.slug = l.master_slug
    left join mg_applications a on a.id = p.application_id
    order by l.created_at desc;
end;
$$;

grant execute on function mg_admin_list_leads(text) to anon;

-- ── Realtime publication на mg_leads ──────────────────────
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'mg_leads'
  ) then
    alter publication supabase_realtime add table mg_leads;
  end if;
end $$;
