-- ============================================================
--  NACBA Webinar Docket — schema
--  Run this FIRST, in the SQL editor of the NACBA Supabase
--  project (lgrdkinplhwucqshrfqg). Safe to re-run.
-- ============================================================

-- ---------- who is allowed in ----------
-- Magic-link sign-in lets anyone REQUEST a link. This table is what
-- decides whether the resulting account can see anything at all.
create table if not exists allowed_emails (
  email      text primary key,
  role       text not null default 'staff'
             check (role in ('admin','coordinator','moderator','marketing','emc_chair','staff')),
  full_name  text default '',
  added_at   timestamptz not null default now()
);

create or replace function public.is_allowed()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from allowed_emails
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

create or replace function public.my_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role from allowed_emails
      where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))),
    'none'
  );
$$;

-- ---------- programs ----------
create table if not exists programs (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null,
  event_date  date not null,
  start_time  time not null default '12:00',
  end_time    time not null default '13:30',
  tz          text not null default 'America/Los_Angeles',
  title       text not null,
  description text not null default '',
  kind        text not null default 'paid'
              check (kind in ('paid','marketing_minute','bk_talk')),
  note        text not null default '',
  archived    boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ---------- speakers (persistent roster, §4.3) ----------
create table if not exists speakers (
  id                uuid primary key default gen_random_uuid(),
  full_name         text not null unique,
  preferred_title   text not null default '',
  firm              text not null default '',
  email             text not null default '',
  phone             text not null default '',
  pronunciation     text not null default '',
  headshot_location text not null default '',
  bio_location      text not null default '',
  notes             text not null default '',
  created_at        timestamptz not null default now()
);

-- ---------- program ↔ speaker ----------
create table if not exists program_speakers (
  id           uuid primary key default gen_random_uuid(),
  program_id   uuid not null references programs(id) on delete cascade,
  speaker_id   uuid not null references speakers(id) on delete cascade,
  topic        text not null default '',
  confirmation text not null default 'invited'
               check (confirmation in ('invited','asked','confirmed','declined')),
  confirmed_on date,
  sort_order   int not null default 0,
  unique (program_id, speaker_id)
);

-- ---------- speaker package (§2.1) ----------
create table if not exists deliverables (
  id                 uuid primary key default gen_random_uuid(),
  program_speaker_id uuid not null references program_speakers(id) on delete cascade,
  item               text not null
                     check (item in ('bio','headshot','agreement','outline','powerpoint')),
  received           boolean not null default false,
  received_on        date,
  file_location      text not null default '',
  unique (program_speaker_id, item)
);

-- ---------- the docket template ----------
-- One row per canonical deadline. Editing a row here changes the
-- rule for every FUTURE program; existing tasks are untouched.
create table if not exists docket_template (
  id          serial primary key,
  offset_days int  not null,
  seq         int  not null default 0,
  task        text not null,
  owner_role  text not null,
  source_ref  text not null default '',
  is_gate     boolean not null default false,
  gate_key    text not null default '',
  unique (offset_days, seq)
);

-- ---------- tasks (a program's generated docket) ----------
create table if not exists tasks (
  id          uuid primary key default gen_random_uuid(),
  program_id  uuid not null references programs(id) on delete cascade,
  offset_days int  not null,
  seq         int  not null default 0,
  task        text not null,
  owner_role  text not null,
  source_ref  text not null default '',
  is_gate     boolean not null default false,
  gate_key    text not null default '',
  done        boolean not null default false,
  done_by     text not null default '',
  done_at     timestamptz,
  unique (program_id, offset_days, seq)
);

create index if not exists tasks_program_idx on tasks (program_id);
create index if not exists prog_speakers_program_idx on program_speakers (program_id);

-- ============================================================
--  THE DOCKET ENGINE
--  Insert a program and its 16 deadlines are created for it.
--  Add a speaker and their 5 package items are created.
-- ============================================================

create or replace function public.generate_docket()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into tasks (program_id, offset_days, seq, task, owner_role, source_ref, is_gate, gate_key)
  select new.id, t.offset_days, t.seq, t.task, t.owner_role, t.source_ref, t.is_gate, t.gate_key
    from docket_template t
  on conflict (program_id, offset_days, seq) do nothing;
  return new;
end $$;

drop trigger if exists trg_generate_docket on programs;
create trigger trg_generate_docket
  after insert on programs
  for each row execute function public.generate_docket();

create or replace function public.generate_deliverables()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into deliverables (program_speaker_id, item)
  select new.id, unnest(array['bio','headshot','agreement','outline','powerpoint'])
  on conflict (program_speaker_id, item) do nothing;
  return new;
end $$;

drop trigger if exists trg_generate_deliverables on program_speakers;
create trigger trg_generate_deliverables
  after insert on program_speakers
  for each row execute function public.generate_deliverables();

-- keep updated_at honest
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists trg_touch_programs on programs;
create trigger trg_touch_programs
  before update on programs
  for each row execute function public.touch_updated_at();

-- stamp who completed a task
create or replace function public.stamp_task()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.done is distinct from old.done then
    if new.done then
      new.done_at = now();
      new.done_by = coalesce(auth.jwt() ->> 'email', '');
    else
      new.done_at = null;
      new.done_by = '';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists trg_stamp_task on tasks;
create trigger trg_stamp_task
  before update on tasks
  for each row execute function public.stamp_task();

-- ---------- a convenient read view: real calendar dates ----------
create or replace view task_board
with (security_invoker = true) as
select
  t.id, t.program_id, t.offset_days, t.seq, t.task, t.owner_role,
  t.source_ref, t.is_gate, t.gate_key, t.done, t.done_by, t.done_at,
  p.title       as program_title,
  p.event_date,
  (p.event_date + t.offset_days)::date as due_date
from tasks t
join programs p on p.id = t.program_id;

-- ============================================================
--  ROW LEVEL SECURITY
--  Nothing is readable or writable unless the signed-in user's
--  email appears in allowed_emails.
-- ============================================================

alter table programs         enable row level security;
alter table speakers         enable row level security;
alter table program_speakers enable row level security;
alter table deliverables     enable row level security;
alter table tasks            enable row level security;
alter table docket_template  enable row level security;
alter table allowed_emails   enable row level security;

do $$
declare tbl text;
begin
  foreach tbl in array array[
    'programs','speakers','program_speakers','deliverables','tasks','docket_template'
  ] loop
    execute format('drop policy if exists %I_read  on %I', tbl, tbl);
    execute format('drop policy if exists %I_write on %I', tbl, tbl);
    execute format(
      'create policy %I_read on %I for select to authenticated using (public.is_allowed())',
      tbl, tbl);
    execute format(
      'create policy %I_write on %I for all to authenticated using (public.is_allowed()) with check (public.is_allowed())',
      tbl, tbl);
  end loop;
end $$;

-- The allowlist itself: everyone allowed can see who else is on it,
-- but only an admin can change it.
drop policy if exists allowed_read  on allowed_emails;
drop policy if exists allowed_write on allowed_emails;
create policy allowed_read on allowed_emails
  for select to authenticated using (public.is_allowed());
create policy allowed_write on allowed_emails
  for all to authenticated
  using (public.my_role() = 'admin')
  with check (public.my_role() = 'admin');

-- ============================================================
--  THE CANONICAL DOCKET
--  Sources: Operations Checklist, Speaker Agreement, Materials
--  Guidelines. The 14 / 7 / 48-hour conflict is resolved here:
--  materials are DUE at T-14, OVERDUE at T-7, and the 48-hour
--  item is QC review complete — not receipt.
-- ============================================================

insert into docket_template (offset_days, seq, task, owner_role, source_ref, is_gate, gate_key) values
  (-35, 0, 'Signed Speaker Agreement on file for every speaker',                              'Coordinator', '§2.1',        true,  'agreements'),
  (-28, 0, 'Registration opens — automated emails and calendar invite tested and proofread',  'Coordinator', '§1.2',        false, 'registration'),
  (-21, 0, 'Speaker package requested: bio, headshot, branded outline, PowerPoint',           'Coordinator', '§2.1',        false, 'package'),
  (-14, 0, '"I am speaking at NACBA" graphics and post copy delivered to speakers',           'Marketing',   '§2.2',        false, 'marketing'),
  (-14, 1, 'Materials due — target date',                                                     'Speaker',     'Agreement',   false, ''),
  ( -7, 0, 'Materials final deadline, set by CLE filing requirements',                        'Speaker',     'Agreement',   true,  'materials'),
  ( -7, 1, 'Reminder email one to registrants',                                               'Coordinator', '§1.2',        false, ''),
  ( -7, 2, 'Registration count to EMC Chair — member / non-member split, names and emails',   'Coordinator', '§3.1',        false, ''),
  ( -2, 0, 'Materials QC complete and Run of Show distributed to staff and moderators',       'Coordinator', '§5.1 §6.2',   true,  'runofshow'),
  ( -1, 0, 'Every hyperlink tested, tech check with speakers, reminder email two',            'Coordinator', '§6.3 §1.2',   false, ''),
  (  0, 0, 'Reminder email three, morning registration count to EMC Chair',                   'Coordinator', '§1.2 §3.1',   false, ''),
  (  0, 1, 'Open 30 minutes early, admit speakers, confirm recording is running',             'Moderator',   '§6.4',        true,  ''),
  (  0, 2, 'Live program',                                                                    'Moderator',   '§6.4',        false, ''),
  (  0, 3, 'Statistics recorded in the shared record, then EMC Chair debrief sent',           'Coordinator', '§3.2',        true,  ''),
  (  1, 0, 'Follow-up email: recording, materials, CLE information, evaluation survey',       'Coordinator', '§6.5',        false, ''),
  ( 14, 0, 'Store discount code from the NACBA Handout expires',                              'Marketing',   '§4.1',        false, '')
on conflict (offset_days, seq) do nothing;
