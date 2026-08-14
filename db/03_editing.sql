-- ============================================================
--  NACBA Webinar Docket — change history
--  Run AFTER 01_schema.sql. Safe to re-run.
--
--  Records every content edit to programs, speakers, and speaker
--  assignments: which field, old value, new value, who, when.
--
--  Task checkboxes and package items are NOT logged here — they
--  already carry their own done_by / received_on stamps, and
--  logging them would bury real edits under routine ticking.
-- ============================================================

create table if not exists change_log (
  id          bigserial primary key,
  table_name  text not null,
  record_id   uuid not null,
  program_id  uuid,                 -- lets history be shown per program
  label       text not null default '',
  field       text not null,
  old_value   text,
  new_value   text,
  changed_by  text not null default '',
  changed_at  timestamptz not null default now()
);

create index if not exists change_log_program_idx on change_log (program_id, changed_at desc);
create index if not exists change_log_recent_idx  on change_log (changed_at desc);

-- Fields that carry no meaning for a reader.
create or replace function public.is_noise_field(f text)
returns boolean language sql immutable as $$
  select f in ('id','created_at','updated_at','sort_order','slug');
$$;

create or replace function public.log_changes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  k    text;
  o    jsonb;
  n    jsonb;
  cur  jsonb;      -- the surviving row: NEW normally, OLD on delete
  who  text;
  pid  uuid;
  rid  uuid;
  lbl  text;
begin
  who := coalesce(nullif(auth.jwt() ->> 'email', ''), 'system');

  -- On DELETE, PL/pgSQL leaves NEW unassigned — touching NEW.anything
  -- raises. Work from jsonb so one code path serves all three ops.
  if tg_op = 'DELETE' then cur := to_jsonb(old); else cur := to_jsonb(new); end if;

  rid := (cur ->> 'id')::uuid;

  -- resolve the owning program and a human label for this row
  if tg_table_name = 'programs' then
    pid := rid;
    lbl := cur ->> 'title';
  elsif tg_table_name = 'program_speakers' then
    pid := (cur ->> 'program_id')::uuid;
    select s.full_name into lbl from speakers s
     where s.id = (cur ->> 'speaker_id')::uuid;
  else -- speakers (roster-level, not tied to one program)
    pid := null;
    lbl := cur ->> 'full_name';
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

  o := to_jsonb(old);
  n := cur;
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

drop trigger if exists trg_log_programs on programs;
create trigger trg_log_programs
  after insert or update or delete on programs
  for each row execute function public.log_changes();

drop trigger if exists trg_log_speakers on speakers;
create trigger trg_log_speakers
  after insert or update or delete on speakers
  for each row execute function public.log_changes();

drop trigger if exists trg_log_program_speakers on program_speakers;
create trigger trg_log_program_speakers
  after insert or update or delete on program_speakers
  for each row execute function public.log_changes();

-- ---------- security ----------
-- Anyone on the allowlist can read history. Nobody can edit or
-- delete it from the app: the log is append-only, written only by
-- the security-definer trigger above.
alter table change_log enable row level security;

drop policy if exists change_log_read on change_log;
create policy change_log_read on change_log
  for select to authenticated using (public.is_allowed());

-- deliberately no insert / update / delete policy

-- ---------- convenience view ----------
create or replace view recent_changes
with (security_invoker = true) as
select c.*, p.title as program_title, p.event_date
  from change_log c
  left join programs p on p.id = c.program_id
 order by c.changed_at desc;
