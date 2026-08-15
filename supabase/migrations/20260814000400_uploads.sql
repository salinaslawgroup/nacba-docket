-- ============================================================
--  NACBA Webinar Docket — speaker uploads and co-panelist contacts
--  Run AFTER 04_speaker_links.sql. Safe to re-run.
--
--  Files are stored in Postgres rather than Supabase Storage. Storage
--  would need either an anonymous write policy on the bucket — which
--  the publishable key makes world-writable — or an Edge Function to
--  mint signed URLs, which needs deploy access. Holding the bytes in a
--  table keeps every write behind the same token check as everything
--  else the speaker can reach. Swap to Storage + an Edge Function if
--  volume ever justifies it; the table is the migration source.
-- ============================================================

create table if not exists speaker_uploads (
  id                 uuid primary key default gen_random_uuid(),
  program_speaker_id uuid not null references program_speakers(id) on delete cascade,
  kind               text not null default 'other'
                     check (kind in ('bio','headshot','outline','powerpoint','other')),
  filename           text not null,
  mime               text not null default '',
  size_bytes         int  not null default 0,
  data               bytea not null,
  uploaded_at        timestamptz not null default now(),
  reviewed           boolean not null default false
);

create index if not exists speaker_uploads_ps_idx
  on speaker_uploads (program_speaker_id, uploaded_at desc);

alter table speaker_uploads enable row level security;

-- Staff read and manage. Speakers never touch the table directly —
-- they go through the security-definer function below.
drop policy if exists speaker_uploads_read  on speaker_uploads;
drop policy if exists speaker_uploads_write on speaker_uploads;
create policy speaker_uploads_read on speaker_uploads
  for select to authenticated using (public.is_allowed());
create policy speaker_uploads_write on speaker_uploads
  for all to authenticated
  using (public.is_allowed()) with check (public.is_allowed());

-- ============================================================
--  Upload, by token
-- ============================================================

create or replace function public.speaker_upload(
  tok      text,
  kind     text,
  filename text,
  mime     text,
  b64      text
)
returns jsonb
language plpgsql
security definer
volatile
set search_path = public
as $$
declare
  link   speaker_links%rowtype;
  bytes  bytea;
  sz     int;
  v_name text;
  v_id   uuid;
  v_at   timestamptz;
begin
  if tok is null or length(tok) < 16 then
    return jsonb_build_object('ok', false, 'error', 'Link not recognized.');
  end if;

  select * into link from speaker_links where token = tok and revoked = false;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'This link is no longer active.');
  end if;

  if coalesce(filename, '') = '' then
    return jsonb_build_object('ok', false, 'error', 'That file has no name.');
  end if;

  if kind not in ('bio','headshot','outline','powerpoint','other') then
    kind := 'other';
  end if;

  begin
    bytes := decode(b64, 'base64');
  exception when others then
    return jsonb_build_object('ok', false, 'error', 'That file could not be read.');
  end;

  sz := octet_length(bytes);
  if sz = 0 then
    return jsonb_build_object('ok', false, 'error', 'That file is empty.');
  end if;
  if sz > 10 * 1024 * 1024 then
    return jsonb_build_object('ok', false,
      'error', 'That file is larger than 10 MB. Please email it to your coordinator instead.');
  end if;

  v_name := left(regexp_replace(filename, '[\r\n\t]', '', 'g'), 200);

  -- Plain INSERT ... RETURNING INTO, deliberately.
  --
  -- A data-modifying CTE is only legal at the top level of a query, so
  -- wrapping the INSERT in "return (with ins as (...) select ...)" fails at
  -- runtime with "WITH clause containing a data-modifying statement must be
  -- at the top level" — the function creates cleanly and only breaks when a
  -- speaker actually uploads.
  --
  -- RETURNING lists only id and uploaded_at: kind, filename, and mime are
  -- also parameter names, and those columns are in scope inside RETURNING,
  -- so naming them there raises "column reference is ambiguous".
  insert into speaker_uploads (program_speaker_id, kind, filename, mime, size_bytes, data)
  values (link.program_speaker_id, kind, v_name,
          left(coalesce(mime, ''), 120), sz, bytes)
  returning id, uploaded_at into v_id, v_at;

  return jsonb_build_object('ok', true, 'upload', jsonb_build_object(
    'id',          v_id,
    'kind',        kind,
    'filename',    v_name,
    'size_bytes',  sz,
    'uploaded_at', v_at));
end $$;

revoke all on function public.speaker_upload(text,text,text,text,text) from public;
grant execute on function public.speaker_upload(text,text,text,text,text) to anon, authenticated;

-- ============================================================
--  Replaces the version in 04_speaker_links.sql.
--  Adds: co-panelist contact details, and the speaker's own uploads.
--  Still withheld: the internal note, the staff docket, every other
--  program, and the file bytes themselves.
-- ============================================================

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

  select * into link from speaker_links
   where token = tok and revoked = false;

  if not found then
    return null;
  end if;

  -- Count the speaker's own visits only. Staff previewing a packet before
  -- sending it are signed in and on the allowlist, so their visits are not
  -- recorded — otherwise "has the speaker opened it yet?" stops meaning
  -- anything the moment a coordinator checks their work.
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
      'email',           s.email,
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

-- ============================================================
--  Staff retrieval. The bytes are never included in list queries —
--  a coordinator asks for one file at a time, by id.
-- ============================================================

create or replace function public.upload_bytes(uid uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare u speaker_uploads%rowtype;
begin
  if not public.is_allowed() then
    return null;
  end if;
  select * into u from speaker_uploads where id = uid;
  if not found then
    return null;
  end if;
  return jsonb_build_object(
    'filename', u.filename,
    'mime',     coalesce(nullif(u.mime, ''), 'application/octet-stream'),
    'b64',      encode(u.data, 'base64')
  );
end $$;

revoke all on function public.upload_bytes(uuid) from public;
grant execute on function public.upload_bytes(uuid) to authenticated;

-- Convenience for staff: what has arrived, without the bytes.
create or replace view upload_inbox
with (security_invoker = true) as
select u.id, u.program_speaker_id, u.kind, u.filename, u.size_bytes,
       u.uploaded_at, u.reviewed,
       s.full_name as speaker, p.title as program_title, p.event_date
  from speaker_uploads u
  join program_speakers ps on ps.id = u.program_speaker_id
  join speakers s on s.id = ps.speaker_id
  join programs p on p.id = ps.program_id
 order by u.uploaded_at desc;
