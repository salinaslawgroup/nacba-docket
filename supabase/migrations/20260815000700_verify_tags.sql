-- Assertions about the season tagging. Changes nothing.
do $$
declare live int; tagged int; total int; sep int; nov int;
begin
  select count(*) into live from programs where not archived;
  if live = 0 then raise notice 'no live programs — skipping'; return; end if;

  select count(distinct p.id) into tagged
    from programs p join program_categories pc on pc.program_id = p.id
   where not p.archived;
  select count(*) into total
    from program_categories pc join programs p on p.id = pc.program_id
   where not p.archived;

  -- 17 Sep must be ABLI; 5 Nov must not be
  select count(*) into sep from program_categories pc
    join programs p on p.id = pc.program_id join categories c on c.id = pc.category_id
   where p.event_date = date '2026-09-17' and c.name = 'ABLI';
  select count(*) into nov from program_categories pc
    join programs p on p.id = pc.program_id join categories c on c.id = pc.category_id
   where p.event_date = date '2026-11-05' and c.name = 'ABLI';

  if tagged <> live then
    raise exception 'Only % of % live programs are tagged', tagged, live;
  end if;
  if total < 16 then
    raise exception 'Expected at least 16 tags across the season, found %', total;
  end if;
  if sep <> 1 then raise exception '17 Sep should be tagged ABLI'; end if;
  if nov <> 0 then raise exception '5 Nov should not be tagged ABLI'; end if;

  raise notice 'season tagged: % of % programs, % tags', tagged, live, total;
end $$;
