-- ============================================================
--  NACBA Webinar Docket — post-event statistics
--  Safe to re-run.
--
--  The five figures §3.2 requires, plus the member/non-member split
--  §3.1 asks for, plus the one nothing has ever recorded: how many
--  non-members actually joined after the EMC Chair's outreach.
--
--  Every count is NULLABLE on purpose. "Not recorded yet" and "zero"
--  are different facts, and averaging them together would quietly
--  understate every season figure.
--
--  Entered by hand for now. When registration data becomes reachable
--  this is the table an import fills — nothing downstream changes.
-- ============================================================

create table if not exists program_metrics (
  id                      uuid primary key default gen_random_uuid(),
  program_id              uuid not null unique references programs(id) on delete cascade,
  registrations_total     int,
  registrations_member    int,
  registrations_nonmember int,
  live_attendees          int,
  gross_revenue           numeric(10,2),
  survey_responses        int,
  survey_score            numeric(3,2),
  nonmember_joined        int,
  tech_issues             text not null default '',
  notes                   text not null default '',
  recorded_by             text not null default '',
  recorded_at             timestamptz,
  updated_at              timestamptz not null default now()
);

comment on column program_metrics.nonmember_joined is
  'Non-members who joined NACBA after the EMC Chair''s outreach. The number the '
  'webinar programme has never been able to show.';
comment on column program_metrics.survey_score is
  'Average rating out of 5, to two decimals.';

alter table program_metrics enable row level security;
drop policy if exists program_metrics_read  on program_metrics;
drop policy if exists program_metrics_write on program_metrics;
create policy program_metrics_read on program_metrics
  for select to authenticated using (public.is_allowed());
create policy program_metrics_write on program_metrics
  for all to authenticated
  using (public.is_allowed()) with check (public.is_allowed());

create or replace function public.stamp_metrics()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.updated_at := now();
  if new.recorded_by = '' then
    new.recorded_by := coalesce(nullif(auth.jwt() ->> 'email', ''), '');
  end if;
  if new.recorded_at is null then new.recorded_at := now(); end if;
  return new;
end $$;

drop trigger if exists trg_stamp_metrics on program_metrics;
create trigger trg_stamp_metrics before insert or update on program_metrics
  for each row execute function public.stamp_metrics();

-- the change log resolves a label per table
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
  elsif tg_table_name in ('program_ideas','program_metrics') then
    pid := (cur ->> 'program_id')::uuid;
    if tg_table_name = 'program_ideas' then
      lbl := cur ->> 'title';
    else
      select p.title into lbl from programs p where p.id = pid;
    end if;
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

drop trigger if exists trg_log_metrics on program_metrics;
create trigger trg_log_metrics
  after insert or update or delete on program_metrics
  for each row execute function public.log_changes();

-- ---------- derived figures, computed rather than typed ----------
create or replace view program_performance
with (security_invoker = true) as
select p.id as program_id, p.title, p.event_date, p.kind, p.archived,
       m.registrations_total, m.registrations_member, m.registrations_nonmember,
       m.live_attendees, m.gross_revenue, m.survey_responses, m.survey_score,
       m.nonmember_joined, m.tech_issues, m.notes, m.recorded_by, m.recorded_at,
       case when m.registrations_total > 0 and m.live_attendees is not null
            then round(100.0 * m.live_attendees / m.registrations_total, 1) end
         as attendance_rate,
       case when m.live_attendees > 0 and m.gross_revenue is not null
            then round(m.gross_revenue / m.live_attendees, 2) end
         as revenue_per_attendee,
       case when m.registrations_total > 0 and m.registrations_member is not null
            then round(100.0 * m.registrations_member / m.registrations_total, 1) end
         as member_share,
       case when m.registrations_nonmember > 0 and m.nonmember_joined is not null
            then round(100.0 * m.nonmember_joined / m.registrations_nonmember, 1) end
         as conversion_rate
  from programs p
  left join program_metrics m on m.program_id = p.id;
