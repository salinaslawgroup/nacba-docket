-- Assertions: everything tagged, and the two corrections landed.
do $$
declare untagged int; sep13 int; sephot int; novabli int; cat_tagged int;
begin
  if (select count(*) from programs) = 0 then
    raise notice 'no programs — skipping'; return;
  end if;

  select count(*) into untagged from programs p
   where not exists (select 1 from program_categories pc where pc.program_id = p.id);

  select count(*) into cat_tagged from programs p
   where p.archived
     and exists (select 1 from program_categories pc where pc.program_id = p.id);

  select count(*) into sep13 from program_categories pc
    join programs p on p.id = pc.program_id join categories c on c.id = pc.category_id
   where p.event_date = date '2026-09-24' and not p.archived and c.name = 'Chapter 13';
  select count(*) into sephot from program_categories pc
    join programs p on p.id = pc.program_id join categories c on c.id = pc.category_id
   where p.event_date = date '2026-09-24' and not p.archived and c.name = 'Hot Topics';
  select count(*) into novabli from program_categories pc
    join programs p on p.id = pc.program_id join categories c on c.id = pc.category_id
   where p.event_date = date '2026-11-05' and c.name = 'ABLI';

  if untagged <> 0 then
    raise exception '% programs still carry no category', untagged;
  end if;
  if cat_tagged <> 43 then
    raise exception 'Expected 43 catalogue programs tagged, found %', cat_tagged;
  end if;
  if sep13 <> 0 then raise exception '24 Sep should no longer be Chapter 13'; end if;
  if sephot <> 1 then raise exception '24 Sep should be Hot Topics'; end if;
  if novabli <> 0 then raise exception '5 Nov should not be ABLI'; end if;

  raise notice 'all programs tagged; 24 Sep corrected; 5 Nov clear of ABLI';
end $$;
