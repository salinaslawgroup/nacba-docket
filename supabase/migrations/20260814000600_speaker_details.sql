-- ============================================================
--  NACBA Webinar Docket — speaker-supplied contact details
--  Safe to re-run.
--
--  The agreement asked for a firm, address, and phone that NACBA did
--  not hold, and gave the speaker nowhere to put them. They can now
--  fill those in from the agreement page; the values land on the
--  speaker record and are reused everywhere — packet, bio, staff app.
-- ============================================================

alter table speakers add column if not exists address text not null default '';

-- ------------------------------------------------------------
--  Update by token.
--
--  Parameters are p_-prefixed on purpose. Naming them firm/address/
--  phone would collide with the columns of the same name inside
--  UPDATE ... SET, which raises "column reference is ambiguous".
-- ------------------------------------------------------------
create or replace function public.speaker_update_details(
  tok             text,
  p_firm          text,
  p_address       text,
  p_phone         text,
  p_pronunciation text
)
returns jsonb
language plpgsql
security definer
volatile
set search_path = public
as $$
declare
  link speaker_links%rowtype;
  sid  uuid;
begin
  if tok is null or length(tok) < 16 then
    return jsonb_build_object('ok', false, 'error', 'Link not recognized.');
  end if;

  select * into link from speaker_links where token = tok and revoked = false;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'This link is no longer active.');
  end if;

  select ps.speaker_id into sid
    from program_speakers ps where ps.id = link.program_speaker_id;
  if sid is null then
    return jsonb_build_object('ok', false, 'error', 'We could not find your record.');
  end if;

  -- Name, email, and speaker type are deliberately not writable here:
  -- they are how NACBA identifies and introduces the speaker, and an
  -- unauthenticated link should not be able to change them.
  update speakers
     set firm          = left(coalesce(p_firm, ''), 200),
         address       = left(coalesce(p_address, ''), 400),
         phone         = left(coalesce(p_phone, ''), 60),
         pronunciation = left(coalesce(p_pronunciation, ''), 120)
   where id = sid;

  return jsonb_build_object('ok', true);
end $$;

revoke all on function public.speaker_update_details(text,text,text,text,text) from public;
grant execute on function public.speaker_update_details(text,text,text,text,text) to anon, authenticated;

-- ------------------------------------------------------------
--  speaker_packet, now returning the address as well.
--  Replaces the version in 20260814000400_uploads.sql.
-- ------------------------------------------------------------
create or replace function public.speaker_packet(tok text)
returns jsonb
language plpgsql
security definer
volatile
set search_path = public
as $$
declare
  link speaker_links%rowtype;
  out  jsonb;
begin
  if tok is null or length(tok) < 16 then
    return null;
  end if;

  select * into link from speaker_links where token = tok and revoked = false;
  if not found then
    return null;
  end if;

  -- Staff previews are not counted; only the speaker's own visits.
  if not public.is_allowed() then
    update speaker_links
       set open_count      = open_count + 1,
           last_opened_at  = now(),
           first_opened_at = coalesce(first_opened_at, now())
     where id = link.id;
  end if;

  select jsonb_build_object(
    'speaker', jsonb_build_object(
      'full_name',       s.full_name,
      'preferred_title', s.preferred_title,
      'firm',            s.firm,
      'address',         s.address,
      'email',           s.email,
      'phone',           s.phone,
      'pronunciation',   s.pronunciation
    ),
    'program', jsonb_build_object(
      'title',       p.title,
      'description', p.description,
      'event_date',  p.event_date
    ),
    'topic',        ps.topic,
    'confirmation', ps.confirmation,
    'co_speakers',  coalesce((
      select jsonb_agg(jsonb_build_object(
               'full_name',       s2.full_name,
               'preferred_title', s2.preferred_title,
               'firm',            s2.firm,
               'email',           s2.email,
               'phone',           s2.phone,
               'topic',           ps2.topic,
               'confirmed',       (ps2.confirmation = 'confirmed')
             ) order by ps2.sort_order)
        from program_speakers ps2
        join speakers s2 on s2.id = ps2.speaker_id
       where ps2.program_id = p.id and ps2.id <> ps.id
    ), '[]'::jsonb),
    'deliverables', coalesce((
      select jsonb_agg(jsonb_build_object(
               'item', d.item, 'received', d.received, 'received_on', d.received_on)
             order by d.item)
        from deliverables d where d.program_speaker_id = ps.id
    ), '[]'::jsonb),
    'uploads', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', u.id, 'kind', u.kind, 'filename', u.filename,
               'size_bytes', u.size_bytes, 'uploaded_at', u.uploaded_at)
             order by u.uploaded_at desc)
        from speaker_uploads u where u.program_speaker_id = ps.id
    ), '[]'::jsonb)
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
