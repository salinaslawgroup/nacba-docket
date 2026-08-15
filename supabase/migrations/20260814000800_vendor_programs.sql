-- ============================================================
--  NACBA Webinar Docket — vendor programs
--  Safe to re-run.
--
--  Vendor programs are sponsored, free to members, and carry no CLE
--  credit. That changes the WORDING, not the workflow: materials still
--  have a deadline, because NACBA still reviews them and still gets
--  them out to the membership before the program.
--
--  So there is one docket for every program kind. What differs is the
--  agreement a vendor signs and the reason given for the deadline.
--
--  (An earlier draft of this migration created a separate vendor
--  docket. If it ran, the cleanup below removes it.)
-- ============================================================

-- ---------- allow the new kind ----------
do $$
begin
  alter table programs drop constraint if exists programs_kind_check;
  alter table programs add constraint programs_kind_check
    check (kind in ('paid','vendor','marketing_minute','bk_talk'));
end $$;

comment on column programs.kind is
  'paid = ticketed CLE webinar | vendor = sponsor pays, free to members, no CLE | '
  'marketing_minute and bk_talk = quarterly free member benefit';

-- ---------- undo the per-kind docket, if the earlier draft applied ----------
do $$
begin
  if exists (
    select 1 from information_schema.columns
     where table_name = 'docket_template' and column_name = 'kind'
  ) then
    delete from docket_template where kind <> 'paid';
    alter table docket_template drop column kind;
  end if;
end $$;

drop index if exists docket_template_kind_offset_seq_idx;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'docket_template_offset_days_seq_key'
  ) then
    alter table docket_template
      add constraint docket_template_offset_days_seq_key unique (offset_days, seq);
  end if;
end $$;

-- one docket, every kind
create or replace function public.generate_docket()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into tasks (program_id, offset_days, seq, task, owner_role, source_ref, is_gate, gate_key)
  select new.id, t.offset_days, t.seq, t.task, t.owner_role, t.source_ref, t.is_gate, t.gate_key
    from docket_template t
  on conflict (program_id, offset_days, seq) do nothing;
  return new;
end $$;

-- ---------- the materials deadline, said properly ----------
-- CLE is one reason among several, and it does not apply to every
-- program. Review and getting materials to members always do.
update docket_template
   set task = 'Materials final deadline — review, distribution to members, and CLE filing where it applies'
 where offset_days = -7 and seq = 0;

update docket_template
   set task = 'Materials due — target date, leaving room for a revision after review'
 where offset_days = -14 and seq = 1;

-- ---------- speaker_packet, now carrying the program kind ----------
create or replace function public.speaker_packet(tok text)
returns jsonb
language plpgsql security definer volatile set search_path = public
as $$
declare
  link speaker_links%rowtype;
  out  jsonb;
begin
  if tok is null or length(tok) < 16 then return null; end if;

  select * into link from speaker_links where token = tok and revoked = false;
  if not found then return null; end if;

  if not public.is_allowed() then
    update speaker_links
       set open_count      = open_count + 1,
           last_opened_at  = now(),
           first_opened_at = coalesce(first_opened_at, now())
     where id = link.id;
  end if;

  select jsonb_build_object(
    'speaker', jsonb_build_object(
      'full_name', s.full_name, 'preferred_title', s.preferred_title,
      'firm', s.firm, 'address', s.address, 'email', s.email,
      'phone', s.phone, 'pronunciation', s.pronunciation),
    'program', jsonb_build_object(
      'title', p.title, 'description', p.description,
      'event_date', p.event_date, 'kind', p.kind),
    'topic', ps.topic,
    'confirmation', ps.confirmation,
    'co_speakers', coalesce((
      select jsonb_agg(jsonb_build_object(
               'full_name', s2.full_name, 'preferred_title', s2.preferred_title,
               'firm', s2.firm, 'email', s2.email, 'phone', s2.phone,
               'topic', ps2.topic, 'confirmed', (ps2.confirmation = 'confirmed'))
             order by ps2.sort_order)
        from program_speakers ps2
        join speakers s2 on s2.id = ps2.speaker_id
       where ps2.program_id = p.id and ps2.id <> ps.id), '[]'::jsonb),
    'deliverables', coalesce((
      select jsonb_agg(jsonb_build_object(
               'item', d.item, 'received', d.received, 'received_on', d.received_on)
             order by d.item)
        from deliverables d where d.program_speaker_id = ps.id), '[]'::jsonb),
    'uploads', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', u.id, 'kind', u.kind, 'filename', u.filename,
               'size_bytes', u.size_bytes, 'uploaded_at', u.uploaded_at)
             order by u.uploaded_at desc)
        from speaker_uploads u where u.program_speaker_id = ps.id), '[]'::jsonb)
  )
  into out
  from program_speakers ps
  join speakers s on s.id = ps.speaker_id
  join programs  p on p.id = ps.program_id
  where ps.id = link.program_speaker_id;

  return out;
end $$;

revoke all on function public.speaker_packet(text) from public;
grant execute on function public.speaker_packet(text) to anon, authenticated;
