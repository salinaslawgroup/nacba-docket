-- ============================================================
--  NACBA Webinar Docket — the back catalogue and in-person programs
--  Safe to re-run.
--
--  Three things this adds:
--
--  1. Conference and workshop kinds, so in-person programming lives
--     alongside the webinars instead of somewhere else.
--  2. Somewhere to record what a past program IS — where it is sold,
--     where the recording lives, and for in-person, where it happened.
--  3. Archived programs generate no docket. A 2023 webinar entered for
--     the record is a catalogue entry, not sixteen overdue tasks.
-- ============================================================

do $$
begin
  alter table programs drop constraint if exists programs_kind_check;
  alter table programs add constraint programs_kind_check
    check (kind in ('paid','vendor','marketing_minute','bk_talk','conference','workshop'));
end $$;

comment on column programs.kind is
  'paid = ticketed CLE webinar | vendor = sponsor pays, free to members, no CLE | '
  'marketing_minute, bk_talk = quarterly free member benefit | '
  'conference, workshop = in person';

alter table programs add column if not exists venue         text not null default '';
alter table programs add column if not exists location      text not null default '';
alter table programs add column if not exists store_url     text not null default '';
alter table programs add column if not exists recording_url text not null default '';

comment on column programs.archived is
  'A catalogue entry recorded for the history rather than a program being run. '
  'Archived programs generate no docket and stay out of the season view.';

-- ---------- archived programs get no docket ----------
create or replace function public.generate_docket()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if coalesce(new.archived, false) then
    return new;                       -- catalogue entry, not work to be done
  end if;
  insert into tasks (program_id, offset_days, seq, task, owner_role, source_ref, is_gate, gate_key)
  select new.id, t.offset_days, t.seq, t.task, t.owner_role, t.source_ref, t.is_gate, t.gate_key
    from docket_template t
  on conflict (program_id, offset_days, seq) do nothing;
  return new;
end $$;

-- Archiving a program after the fact clears a docket nobody will work.
create or replace function public.clear_docket_on_archive()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.archived and not coalesce(old.archived, false) then
    delete from tasks where program_id = new.id and done = false;
  end if;
  return new;
end $$;

drop trigger if exists trg_clear_docket_on_archive on programs;
create trigger trg_clear_docket_on_archive
  before update on programs
  for each row execute function public.clear_docket_on_archive();

-- ---------- who spoke on what, and when ----------
create or replace view speaker_programs
with (security_invoker = true) as
select s.id            as speaker_id,
       s.full_name,
       s.speaker_type,
       p.id            as program_id,
       p.title,
       p.event_date,
       p.kind,
       p.archived,
       p.store_url,
       p.location,
       ps.topic,
       ps.confirmation
  from speakers s
  join program_speakers ps on ps.speaker_id = s.id
  join programs p          on p.id = ps.program_id;

-- A roster line per speaker: how many programs, when they last spoke.
create or replace view speaker_roster
with (security_invoker = true) as
select s.id, s.full_name, s.preferred_title, s.firm, s.email, s.phone,
       s.pronunciation, s.speaker_type,
       count(ps.id)          as program_count,
       max(p.event_date)     as last_spoke,
       min(p.event_date)     as first_spoke
  from speakers s
  left join program_speakers ps on ps.speaker_id = s.id
  left join programs p          on p.id = ps.program_id
 group by s.id;
