-- ============================================================
--  Assertions about the speaker linking. Changes nothing; fails
--  loudly if the links did not land, since row-level security
--  hides the data from an outside read.
-- ============================================================
do $$
declare
  spk int; links int; dupes int; jenny int; tara int; orphan int;
begin
  select count(*) into spk from speakers;
  if spk = 0 then
    raise notice 'no speakers present — skipping';
    return;
  end if;

  select count(*) into links from program_speakers ps
    join programs p on p.id = ps.program_id where p.archived;

  -- the surname-only records must be gone
  select count(*) into dupes from speakers where full_name in ('Doling','Salinas');

  select count(*) into jenny from program_speakers ps
    join speakers s on s.id = ps.speaker_id
   where s.full_name = 'Jenny L. Doling, Esq.';
  select count(*) into tara from program_speakers ps
    join speakers s on s.id = ps.speaker_id
   where s.full_name = 'Tara Salinas, Esq.';

  -- no link may point at a speaker that no longer exists
  select count(*) into orphan from program_speakers ps
   where not exists (select 1 from speakers s where s.id = ps.speaker_id);

  if dupes <> 0 then
    raise exception 'Surname-only records still present: %', dupes;
  end if;
  if links <> 77 then
    raise exception 'Expected 77 catalogue speaker links, found %', links;
  end if;
  if jenny < 6 then
    raise exception 'Jenny L. Doling should hold at least 6 programs, found %', jenny;
  end if;
  if tara < 6 then
    raise exception 'Tara Salinas should hold at least 6 programs, found %', tara;
  end if;
  if orphan <> 0 then
    raise exception '% links point at a missing speaker', orphan;
  end if;

  raise notice 'links ok: % speakers, % catalogue links, Doling %, Salinas %',
    spk, links, jenny, tara;
end $$;
