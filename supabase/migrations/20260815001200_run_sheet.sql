-- ============================================================
--  NACBA Webinar Docket — the moderator's run sheet
--  Safe to re-run.
--
--  What a moderator holds while the webinar is live. Every step is
--  drawn from the Operations Checklist — §6.1 through §6.5 — rather
--  than invented.
--
--  Items are generated on first use, not by a trigger on every
--  program. Forty-three catalogue entries will never run a run sheet
--  and do not need 23 rows each.
-- ============================================================

create table if not exists run_sheet_template (
  id      serial primary key,
  phase   text not null check (phase in ('before','start','during','close')),
  seq     int  not null,
  step    text not null,
  source  text not null default '',
  unique (phase, seq)
);

create table if not exists run_sheet_items (
  id         uuid primary key default gen_random_uuid(),
  program_id uuid not null references programs(id) on delete cascade,
  phase      text not null,
  seq        int  not null,
  step       text not null,
  source     text not null default '',
  done       boolean not null default false,
  done_by    text not null default '',
  done_at    timestamptz,
  unique (program_id, phase, seq)
);

create index if not exists run_sheet_items_program_idx on run_sheet_items (program_id);

alter table run_sheet_template enable row level security;
alter table run_sheet_items    enable row level security;

do $$
declare tbl text;
begin
  foreach tbl in array array['run_sheet_template','run_sheet_items'] loop
    execute format('drop policy if exists %I_read  on %I', tbl, tbl);
    execute format('drop policy if exists %I_write on %I', tbl, tbl);
    execute format('create policy %I_read on %I for select to authenticated using (public.is_allowed())', tbl, tbl);
    execute format('create policy %I_write on %I for all to authenticated using (public.is_allowed()) with check (public.is_allowed())', tbl, tbl);
  end loop;
end $$;

create or replace function public.stamp_run_step()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.done is distinct from old.done then
    if new.done then
      new.done_at := now();
      new.done_by := coalesce(nullif(auth.jwt() ->> 'email',''), '');
    else
      new.done_at := null; new.done_by := '';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists trg_stamp_run_step on run_sheet_items;
create trigger trg_stamp_run_step before update on run_sheet_items
  for each row execute function public.stamp_run_step();

-- generated the first time a moderator opens the sheet
create or replace function public.ensure_run_sheet(p_program uuid)
returns int
language plpgsql security definer volatile set search_path = public
as $$
declare n int;
begin
  if not public.is_allowed() then return 0; end if;
  insert into run_sheet_items (program_id, phase, seq, step, source)
  select p_program, t.phase, t.seq, t.step, t.source
    from run_sheet_template t
  on conflict (program_id, phase, seq) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;

revoke all on function public.ensure_run_sheet(uuid) from public;
grant execute on function public.ensure_run_sheet(uuid) to authenticated;

-- ---------- the steps ----------
insert into run_sheet_template (phase, seq, step, source) values
  ('before',10,'Open the webinar 30 minutes before the start time','§6.4'),
  ('before',20,'Admit the speakers early for a final check','§6.4'),
  ('before',30,'Check the microphone for every presenter','§6.2 §6.4'),
  ('before',40,'Check camera, lighting, and that backgrounds are professional','§6.2 §6.4'),
  ('before',50,'Test screen sharing for anyone presenting slides','§6.4'),
  ('before',60,'Confirm the recording has started','§6.4'),
  ('before',70,'Confirm the backup recording plan','§6.3'),
  ('before',80,'Confirm presentation order and timing cues with the speakers','§6.1'),
  ('before',90,'Confirm how questions will be handled — Q&A, not chat','§5.1 §6.1'),
  ('start', 10,'Begin on time','§6.4'),
  ('start', 20,'Welcome, and disclose the sponsorship if this is a vendor program','§6.4'),
  ('start', 30,'Introduce the speakers — conversationally, not read aloud','§6.6'),
  ('start', 40,'Keep attendee microphones muted','§6.4'),
  ('during',10,'Monitor Q&A and chat throughout','§6.4'),
  ('during',20,'Launch the polls at the planned points','§6.4'),
  ('during',30,'Watch the clock and give discreet time warnings','§6.4'),
  ('during',40,'Group similar questions before putting them to the panel','§6.4'),
  ('during',50,'Highlight upcoming NACBA events and webinars','§5.1'),
  ('during',60,'Encourage feedback and survey participation, including any contest','§5.1'),
  ('close', 10,'Confirm CLE attendance-tracking requirements are satisfied','§6.4'),
  ('close', 20,'Thank the speakers and the attendees','§6.5'),
  ('close', 30,'Stop the recording','§6.5'),
  ('close', 40,'Verify the recording uploaded successfully','§6.5')
on conflict (phase, seq) do update
  set step = excluded.step, source = excluded.source;
