-- ============================================================
--  Assertions about the catalogue import.
--  This migration changes nothing. It fails loudly if the import
--  did not land as intended — the only way to check from outside,
--  since row-level security hides the data from an anonymous read.
-- ============================================================

do $$
declare
  total     int; arch int; live int;
  tasks_n   int; arch_tasks int;
  placehold int; store_set int; july_store int;
begin
  select count(*) into total from programs;

  -- On a database rebuilt from migrations alone there is no seed data,
  -- so there is nothing to assert. Skip rather than fail the rebuild.
  if total = 0 then
    raise notice 'no programs present — skipping catalogue assertions';
    return;
  end if;
  select count(*) into arch  from programs where archived;
  select count(*) into live  from programs where not archived;
  select count(*) into tasks_n from tasks;
  select count(*) into arch_tasks
    from tasks t join programs p on p.id = t.program_id where p.archived;
  select count(*) into placehold from programs where note like '%PLACEHOLDER DATE%';
  select count(*) into store_set from programs where store_url <> '';
  select count(*) into july_store
    from programs where event_date = date '2026-07-30' and store_url <> '';

  if arch <> 43 then
    raise exception 'Expected 43 archived catalogue rows, found %', arch;
  end if;
  if live > 0 and live <> 11 then
    raise exception 'Expected the 11 live 2026 programs to be untouched, found %', live;
  end if;
  if arch_tasks <> 0 then
    raise exception 'Archived programs generated % tasks; they should generate none', arch_tasks;
  end if;
  if live = 11 and tasks_n <> 176 then
    raise exception 'Expected 176 tasks for the live season, found %', tasks_n;
  end if;
  if placehold <> 7 then
    raise exception 'Expected 7 placeholder-dated rows, found %', placehold;
  end if;
  if july_store <> 1 then
    raise exception 'The 30 July program did not get its store link';
  end if;

  raise notice 'catalogue ok: % programs (% archived, % live), % tasks, % with store links, % placeholder dates',
    total, arch, live, tasks_n, store_set, placehold;
end $$;
