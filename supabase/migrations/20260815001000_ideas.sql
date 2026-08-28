-- ============================================================
--  NACBA Webinar Docket — future program ideas
--  Safe to re-run.
--
--  Ideas live in their own table, not in programs. An idea has no
--  date, and a dateless row in programs would either generate a
--  nonsense docket or sit in the catalogue pretending to be
--  something that already happened.
--
--  When an idea becomes real it is scheduled, which creates a
--  program and records the link — so the season can always say
--  where a program came from.
-- ============================================================

create table if not exists program_ideas (
  id            uuid primary key default gen_random_uuid(),
  title         text not null,
  description   text not null default '',
  rationale     text not null default '',
  speakers_idea text not null default '',
  target_period text not null default '',
  status        text not null default 'idea'
                check (status in ('idea','considering','approved','scheduled','declined')),
  source        text not null default '',
  suggested_by  text not null default '',
  program_id    uuid references programs(id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table if not exists idea_categories (
  idea_id     uuid not null references program_ideas(id) on delete cascade,
  category_id uuid not null references categories(id)    on delete cascade,
  primary key (idea_id, category_id)
);

create index if not exists idea_categories_cat_idx on idea_categories (category_id);
create index if not exists program_ideas_status_idx on program_ideas (status, created_at desc);

alter table program_ideas   enable row level security;
alter table idea_categories enable row level security;

do $$
declare tbl text;
begin
  foreach tbl in array array['program_ideas','idea_categories'] loop
    execute format('drop policy if exists %I_read  on %I', tbl, tbl);
    execute format('drop policy if exists %I_write on %I', tbl, tbl);
    execute format(
      'create policy %I_read on %I for select to authenticated using (public.is_allowed())', tbl, tbl);
    execute format(
      'create policy %I_write on %I for all to authenticated using (public.is_allowed()) with check (public.is_allowed())', tbl, tbl);
  end loop;
end $$;

-- who suggested it, and when it last moved
create or replace function public.stamp_idea()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' and new.suggested_by = '' then
    new.suggested_by := coalesce(nullif(auth.jwt() ->> 'email', ''), '');
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists trg_stamp_idea on program_ideas;
create trigger trg_stamp_idea before insert or update on program_ideas
  for each row execute function public.stamp_idea();

-- ------------------------------------------------------------
--  The change log resolves a label per table. Without a branch for
--  ideas it would look for full_name and record an empty label.
-- ------------------------------------------------------------
create or replace function public.log_changes()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  k text; o jsonb; n jsonb; cur jsonb; who text; pid uuid; rid uuid; lbl text;
begin
  who := coalesce(nullif(auth.jwt() ->> 'email', ''), 'system');
  if tg_op = 'DELETE' then cur := to_jsonb(old); else cur := to_jsonb(new); end if;
  rid := (cur ->> 'id')::uuid;

  if tg_table_name = 'programs' then
    pid := rid; lbl := cur ->> 'title';
  elsif tg_table_name = 'program_speakers' then
    pid := (cur ->> 'program_id')::uuid;
    select s.full_name into lbl from speakers s where s.id = (cur ->> 'speaker_id')::uuid;
  elsif tg_table_name = 'program_ideas' then
    pid := (cur ->> 'program_id')::uuid;      -- null until it is scheduled
    lbl := cur ->> 'title';
  else
    pid := null; lbl := cur ->> 'full_name';
  end if;

  if tg_op = 'INSERT' then
    insert into change_log (table_name, record_id, program_id, label, field, old_value, new_value, changed_by)
    values (tg_table_name, rid, pid, coalesce(lbl,''), 'added', null, coalesce(lbl,''), who);
    return new;
  end if;

  if tg_op = 'DELETE' then
    insert into change_log (table_name, record_id, program_id, label, field, old_value, new_value, changed_by)
    values (tg_table_name, rid, pid, coalesce(lbl,''), 'removed', coalesce(lbl,''), null, who);
    return old;
  end if;

  o := to_jsonb(old); n := cur;
  for k in select jsonb_object_keys(n) loop
    if public.is_noise_field(k) then continue; end if;
    if (o -> k) is distinct from (n -> k) then
      insert into change_log (table_name, record_id, program_id, label, field, old_value, new_value, changed_by)
      values (tg_table_name, rid, pid, coalesce(lbl,''), k,
              nullif(o ->> k, ''), nullif(n ->> k, ''), who);
    end if;
  end loop;
  return new;
end $$;

drop trigger if exists trg_log_ideas on program_ideas;
create trigger trg_log_ideas
  after insert or update or delete on program_ideas
  for each row execute function public.log_changes();

-- what is in the pipeline, with its categories rolled up
create or replace view idea_board
with (security_invoker = true) as
select i.*,
       coalesce((select string_agg(c.name, ', ' order by c.name)
                   from idea_categories ic join categories c on c.id = ic.category_id
                  where ic.idea_id = i.id), '') as category_names,
       p.event_date as scheduled_for
  from program_ideas i
  left join programs p on p.id = i.program_id;
