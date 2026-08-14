-- ============================================================
--  NACBA Webinar Docket — speaker links
--  Run AFTER 01_schema.sql. Safe to re-run.
--
--  Speakers are not staff and are never on the allowlist, so they
--  cannot sign in. Each speaker instead gets an unguessable link.
--
--  The link does NOT grant table access. Anonymous visitors have no
--  policy on any table and can read nothing. They may only call one
--  security-definer function, which takes a token, returns that one
--  speaker's own row, and records the visit.
-- ============================================================

create table if not exists speaker_links (
  id                 uuid primary key default gen_random_uuid(),
  program_speaker_id uuid not null unique
                     references program_speakers(id) on delete cascade,
  token              text not null unique
                     default encode(gen_random_bytes(16), 'hex'),
  created_at         timestamptz not null default now(),
  created_by         text not null default '',
  first_opened_at    timestamptz,
  last_opened_at     timestamptz,
  open_count         int not null default 0,
  revoked            boolean not null default false
);

create index if not exists speaker_links_token_idx on speaker_links (token);

alter table speaker_links enable row level security;

-- Staff on the allowlist manage links. Anonymous visitors get nothing
-- here — their entire surface is the function below.
drop policy if exists speaker_links_read  on speaker_links;
drop policy if exists speaker_links_write on speaker_links;
create policy speaker_links_read on speaker_links
  for select to authenticated using (public.is_allowed());
create policy speaker_links_write on speaker_links
  for all to authenticated
  using (public.is_allowed()) with check (public.is_allowed());

-- stamp who issued the link
create or replace function public.stamp_link()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.created_by = '' then
    new.created_by := coalesce(nullif(auth.jwt() ->> 'email', ''), '');
  end if;
  return new;
end $$;

drop trigger if exists trg_stamp_link on speaker_links;
create trigger trg_stamp_link before insert on speaker_links
  for each row execute function public.stamp_link();

-- ============================================================
--  The speaker's entire view of the system.
--  Returns one speaker's own packet, or null for a bad/revoked token.
--  Deliberately omits: other speakers' contact details, the internal
--  note, the staff docket, and every other program.
-- ============================================================

create or replace function public.speaker_packet(tok text)
returns jsonb
language plpgsql
security definer
volatile
set search_path = public
as $$
declare
  link  speaker_links%rowtype;
  out   jsonb;
begin
  if tok is null or length(tok) < 16 then
    return null;
  end if;

  select * into link from speaker_links
   where token = tok and revoked = false;

  if not found then
    return null;
  end if;

  update speaker_links
     set open_count      = open_count + 1,
         last_opened_at  = now(),
         first_opened_at = coalesce(first_opened_at, now())
   where id = link.id;

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
      select jsonb_agg(s2.full_name order by ps2.sort_order)
        from program_speakers ps2
        join speakers s2 on s2.id = ps2.speaker_id
       where ps2.program_id = p.id and ps2.id <> ps.id
    ), '[]'::jsonb),
    'deliverables', coalesce((
      select jsonb_agg(jsonb_build_object(
               'item', d.item, 'received', d.received, 'received_on', d.received_on)
             order by d.item)
        from deliverables d where d.program_speaker_id = ps.id
    ), '[]'::jsonb)
  )
  into out
  from program_speakers ps
  join speakers s on s.id = ps.speaker_id
  join programs  p on p.id = ps.program_id
  where ps.id = link.program_speaker_id;

  return out;
end $$;

-- The one thing an anonymous visitor may do.
revoke all on function public.speaker_packet(text) from public;
grant execute on function public.speaker_packet(text) to anon, authenticated;
