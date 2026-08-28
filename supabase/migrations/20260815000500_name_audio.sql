-- ============================================================
--  NACBA Webinar Docket — spoken name
--  Safe to re-run.
--
--  A phonetic spelling is a guess at a sound. A recording is the
--  sound. §6.1 asks the moderator to confirm pronunciation before
--  going live; this gives them something to actually listen to.
--
--  Stored on the SPEAKER, not on a program: how someone says their
--  own name does not change between webinars, so one recording
--  follows them everywhere.
-- ============================================================

alter table speakers add column if not exists name_audio      bytea;
alter table speakers add column if not exists name_audio_mime text not null default '';
alter table speakers add column if not exists name_audio_at   timestamptz;

comment on column speakers.name_audio is
  'A few seconds of the speaker saying their own name. Recorded by them, from their packet.';

-- ------------------------------------------------------------
--  The speaker records it, by token.
--  Parameters are p_-prefixed: naming one `mime` would collide
--  with the column of the same name inside UPDATE ... SET.
-- ------------------------------------------------------------
create or replace function public.speaker_record_name(
  tok text, p_mime text, p_b64 text
)
returns jsonb
language plpgsql security definer volatile set search_path = public
as $$
declare
  link  speaker_links%rowtype;
  sid   uuid;
  bytes bytea;
  sz    int;
begin
  if tok is null or length(tok) < 16 then
    return jsonb_build_object('ok', false, 'error', 'Link not recognized.');
  end if;

  select * into link from speaker_links where token = tok and revoked = false;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'This link is no longer active.');
  end if;

  select ps.speaker_id into sid from program_speakers ps where ps.id = link.program_speaker_id;
  if sid is null then
    return jsonb_build_object('ok', false, 'error', 'We could not find your record.');
  end if;

  -- an empty payload clears the recording
  if p_b64 is null or p_b64 = '' then
    update speakers set name_audio = null, name_audio_mime = '', name_audio_at = null
     where id = sid;
    return jsonb_build_object('ok', true, 'cleared', true);
  end if;

  begin
    bytes := decode(p_b64, 'base64');
  exception when others then
    return jsonb_build_object('ok', false, 'error', 'That recording could not be read.');
  end;

  sz := octet_length(bytes);
  if sz = 0 then
    return jsonb_build_object('ok', false, 'error', 'That recording is empty.');
  end if;
  -- a spoken name is seconds long; anything larger is a mistake
  if sz > 2 * 1024 * 1024 then
    return jsonb_build_object('ok', false,
      'error', 'That recording is larger than 2 MB. A few seconds is all we need.');
  end if;

  update speakers
     set name_audio      = bytes,
         name_audio_mime = left(coalesce(p_mime, 'audio/webm'), 60),
         name_audio_at   = now()
   where id = sid;

  return jsonb_build_object('ok', true, 'size', sz);
end $$;

revoke all on function public.speaker_record_name(text,text,text) from public;
grant execute on function public.speaker_record_name(text,text,text) to anon, authenticated;

-- ------------------------------------------------------------
--  Playback. Two doors: the speaker via their token, staff via
--  the allowlist. Neither returns anything else about the record.
-- ------------------------------------------------------------
create or replace function public.speaker_name_audio(tok text)
returns jsonb
language plpgsql security definer stable set search_path = public
as $$
declare link speaker_links%rowtype; r record;
begin
  if tok is null or length(tok) < 16 then return null; end if;
  select * into link from speaker_links where token = tok and revoked = false;
  if not found then return null; end if;
  select s.name_audio, s.name_audio_mime into r
    from program_speakers ps join speakers s on s.id = ps.speaker_id
   where ps.id = link.program_speaker_id;
  if r.name_audio is null then return null; end if;
  return jsonb_build_object('mime', coalesce(nullif(r.name_audio_mime,''),'audio/webm'),
                            'b64', encode(r.name_audio, 'base64'));
end $$;

revoke all on function public.speaker_name_audio(text) from public;
grant execute on function public.speaker_name_audio(text) to anon, authenticated;

create or replace function public.name_audio(p_speaker uuid)
returns jsonb
language plpgsql security definer stable set search_path = public
as $$
declare r record;
begin
  if not public.is_allowed() then return null; end if;
  select s.name_audio, s.name_audio_mime, s.full_name into r
    from speakers s where s.id = p_speaker;
  if r.name_audio is null then return null; end if;
  return jsonb_build_object('mime', coalesce(nullif(r.name_audio_mime,''),'audio/webm'),
                            'name', r.full_name,
                            'b64', encode(r.name_audio, 'base64'));
end $$;

revoke all on function public.name_audio(uuid) from public;
grant execute on function public.name_audio(uuid) to authenticated;

-- ------------------------------------------------------------
--  speaker_packet gains a flag. The bytes are never in the packet
--  payload — every page load would carry the audio otherwise.
-- ------------------------------------------------------------
create or replace function public.speaker_packet(tok text)
returns jsonb
language plpgsql security definer volatile set search_path = public
as $$
declare link speaker_links%rowtype; out jsonb;
begin
  if tok is null or length(tok) < 16 then return null; end if;
  select * into link from speaker_links where token = tok and revoked = false;
  if not found then return null; end if;

  if not public.is_allowed() then
    update speaker_links
       set open_count = open_count + 1, last_opened_at = now(),
           first_opened_at = coalesce(first_opened_at, now())
     where id = link.id;
  end if;

  select jsonb_build_object(
    'speaker', jsonb_build_object(
      'full_name', s.full_name, 'preferred_title', s.preferred_title,
      'firm', s.firm, 'address', s.address, 'email', s.email,
      'phone', s.phone, 'pronunciation', s.pronunciation,
      'has_name_audio', (s.name_audio is not null)),
    'program', jsonb_build_object(
      'title', p.title, 'description', p.description,
      'event_date', p.event_date, 'kind', p.kind),
    'topic', ps.topic, 'confirmation', ps.confirmation,
    'co_speakers', coalesce((
      select jsonb_agg(jsonb_build_object(
               'full_name', s2.full_name, 'preferred_title', s2.preferred_title,
               'firm', s2.firm, 'email', s2.email, 'phone', s2.phone,
               'topic', ps2.topic, 'confirmed', (ps2.confirmation = 'confirmed'))
             order by ps2.sort_order)
        from program_speakers ps2 join speakers s2 on s2.id = ps2.speaker_id
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
  ) into out
  from program_speakers ps
  join speakers s on s.id = ps.speaker_id
  join programs  p on p.id = ps.program_id
  where ps.id = link.program_speaker_id;

  return out;
end $$;

revoke all on function public.speaker_packet(text) from public;
grant execute on function public.speaker_packet(text) to anon, authenticated;
