-- ============================================================
--  Link speakers to the back catalogue
--  Safe to re-run.
--
--  Names verified from each product page, not from the listing —
--  the listing truncates. Issue Preclusion, for example, shows two
--  names in the list and has three on its own page.
--
--  Canonical spelling wins. The store bills the same person several
--  ways — Jenny Doling / Jenny L. Doling, Tara Salinas / Tara
--  Gaschler Salinas, Lisa Thompson / Lisa C. Thompson — and each
--  variant would otherwise become a separate person with a fragment
--  of the history.
-- ============================================================

-- ---------- 1. merge the surname-only records already in the roster ----------
-- The 13 Aug 2026 program was seeded with 'Doling' and 'Salinas' as the
-- schedule wrote them. Both are people who already exist in full.
do $$
declare pair record;
begin
  for pair in select * from (values
      ('Doling','Jenny L. Doling, Esq.'),
      ('Salinas','Tara Salinas, Esq.')
    ) as t(dup, canon)
  loop
    if exists (select 1 from speakers where full_name = pair.dup)
       and exists (select 1 from speakers where full_name = pair.canon) then

      update program_speakers ps
         set speaker_id = c.id
        from speakers d, speakers c
       where d.full_name = pair.dup and c.full_name = pair.canon
         and ps.speaker_id = d.id
         and not exists (select 1 from program_speakers x
                          where x.program_id = ps.program_id and x.speaker_id = c.id);

      insert into speaker_categories (speaker_id, category_id)
      select c.id, sc.category_id from speaker_categories sc, speakers d, speakers c
       where d.full_name = pair.dup and c.full_name = pair.canon and sc.speaker_id = d.id
      on conflict do nothing;

      delete from speakers where full_name = pair.dup;
      raise notice 'merged % into %', pair.dup, pair.canon;
    end if;
  end loop;
end $$;

-- ---------- 2. every speaker named on the catalogue ----------
insert into speakers (full_name) values
  ('Abelardo Limon'),
  ('Ahren Tiller, Esq.'),
  ('Alexander Berry-Santoro, Esq.'),
  ('Ashley Morgan, Esq.'),
  ('Belisa Pang'),
  ('Brian D. Flick, Esq.'),
  ('Carey Ebert'),
  ('Christopher P. Burke, Esq.'),
  ('Claude Ducloux, Esq.'),
  ('David Chapman'),
  ('David Cox, Esq.'),
  ('David Fleck, Esq.'),
  ('Deepalie Milie Joshi, Esq.'),
  ('Dianne C. Kerns'),
  ('Ed Boltz, Esq.'),
  ('Hon. Dan Collins'),
  ('Hon. Elizabeth L. Gunn'),
  ('Hon. Laura Taylor (Ret.)'),
  ('Hon. Meredith Jury (Ret.)'),
  ('Hon. Neil W. Bason'),
  ('James J. Haller'),
  ('Jay Patterson'),
  ('Jen Lee, Esq.'),
  ('Jenny L. Doling, Esq.'),
  ('John T. O''Neil'),
  ('Kara Bruce'),
  ('Kara Gendron, Esq.'),
  ('Karen Kellett'),
  ('Kelli Stanley'),
  ('Koury Hicks, Esq.'),
  ('Latife Neu, Esq.'),
  ('Lawrence J. Kotler, Esq.'),
  ('Lisa C. Thompson, Esq.'),
  ('Luke Homen, Esq.'),
  ('M. Jonathan Hayes, Esq.'),
  ('Malissa Giles'),
  ('Marc Stern, Esq.'),
  ('Michael Gouveia, Esq.'),
  ('Michael Primus, Esq.'),
  ('Mike Assad, Esq.'),
  ('Nicole Novak, Esq.'),
  ('O. Max Gardner'),
  ('Rachel Lynn Foley, Esq.'),
  ('Randy Nussbaum, Esq.'),
  ('Rashad Blossom, Esq.'),
  ('Richard Cook, Esq.'),
  ('Ryan Spengler, Esq.'),
  ('Samantha Tirado, Esq.'),
  ('Sean Cloyes, Esq.'),
  ('Stephen E. Berken, Esq.'),
  ('Tara Salinas, Esq.'),
  ('Thad Bartholow'),
  ('Théda Page, Esq.'),
  ('Tracy Giles')
on conflict (full_name) do nothing;

-- ---------- 3. role, where the store states it plainly ----------
update speakers set speaker_type = 'other' where full_name = 'Belisa Pang' and speaker_type is null;
update speakers set speaker_type = 'trustee' where full_name = 'Carey Ebert' and speaker_type is null;
update speakers set speaker_type = 'other' where full_name = 'David Chapman' and speaker_type is null;
update speakers set speaker_type = 'trustee' where full_name = 'Dianne C. Kerns' and speaker_type is null;
update speakers set speaker_type = 'judge' where full_name = 'Hon. Dan Collins' and speaker_type is null;
update speakers set speaker_type = 'judge' where full_name = 'Hon. Elizabeth L. Gunn' and speaker_type is null;
update speakers set speaker_type = 'judge' where full_name = 'Hon. Laura Taylor (Ret.)' and speaker_type is null;
update speakers set speaker_type = 'judge' where full_name = 'Hon. Meredith Jury (Ret.)' and speaker_type is null;
update speakers set speaker_type = 'judge' where full_name = 'Hon. Neil W. Bason' and speaker_type is null;
update speakers set speaker_type = 'other' where full_name = 'Kara Bruce' and speaker_type is null;
update speakers set speaker_type = 'paralegal' where full_name = 'Kelli Stanley' and speaker_type is null;

-- ---------- 4. link each speaker to the program they presented ----------
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2026-05-14%-27487665' and s.full_name = 'Tara Salinas, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2026-03-05%-27006072' and s.full_name = 'Ashley Morgan, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2026-03-05%-27006072' and s.full_name = 'Mike Assad, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2026-01-16%-26714823' and s.full_name = 'Jenny L. Doling, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2026-01-15%-26714802' and s.full_name = 'Ahren Tiller, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2026-01-13%-26714781' and s.full_name = 'Carey Ebert'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2026-01-13%-26714781' and s.full_name = 'Latife Neu, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 2 from programs p, speakers s
 where p.slug like '2026-01-13%-26714781' and s.full_name = 'Marc Stern, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2026-01-13%-26714718' and s.full_name = 'Ed Boltz, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2026-01-13%-26714718' and s.full_name = 'John T. O''Neil'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2026-01-12%-26709888' and s.full_name = 'Tara Salinas, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2026-01-12%-26709888' and s.full_name = 'Samantha Tirado, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-10-30%-26280312' and s.full_name = 'Christopher P. Burke, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-10-30%-26280312' and s.full_name = 'M. Jonathan Hayes, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-09-04%-26152884' and s.full_name = 'Rachel Lynn Foley, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-09-04%-26152884' and s.full_name = 'Jen Lee, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-08-07%-25956177' and s.full_name = 'Kelli Stanley'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-08-07%-25956177' and s.full_name = 'Michael Gouveia, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-07-31%-25855314' and s.full_name = 'Carey Ebert'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-07-31%-25855314' and s.full_name = 'Dianne C. Kerns'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 2 from programs p, speakers s
 where p.slug like '2025-07-31%-25855314' and s.full_name = 'Lisa C. Thompson, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-07-10%-25617216' and s.full_name = 'Richard Cook, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-07-10%-25617216' and s.full_name = 'David Cox, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 2 from programs p, speakers s
 where p.slug like '2025-07-10%-25617216' and s.full_name = 'Kara Bruce'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-06-26%-25721439' and s.full_name = 'Stephen E. Berken, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-06-26%-25721439' and s.full_name = 'Sean Cloyes, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-06-12%-25725366' and s.full_name = 'Brian D. Flick, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-06-12%-25725366' and s.full_name = 'David Fleck, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-05-29%-25714299' and s.full_name = 'Lisa C. Thompson, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-05-29%-25714299' and s.full_name = 'Deepalie Milie Joshi, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-03-20%-25279893' and s.full_name = 'Hon. Elizabeth L. Gunn'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-03-20%-25279893' and s.full_name = 'Ed Boltz, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 2 from programs p, speakers s
 where p.slug like '2025-03-20%-25279893' and s.full_name = 'Jenny L. Doling, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-02-20%-25149987' and s.full_name = 'Hon. Neil W. Bason'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-02-20%-25149987' and s.full_name = 'Lawrence J. Kotler, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 2 from programs p, speakers s
 where p.slug like '2025-02-20%-25149987' and s.full_name = 'Ryan Spengler, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-01-17%-24881376' and s.full_name = 'Claude Ducloux, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-01-16%-24881313' and s.full_name = 'Tara Salinas, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-01-16%-24881313' and s.full_name = 'Alexander Berry-Santoro, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-01-15%-24881229' and s.full_name = 'Kara Gendron, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-01-15%-24881229' and s.full_name = 'Luke Homen, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 2 from programs p, speakers s
 where p.slug like '2025-01-15%-24881229' and s.full_name = 'Nicole Novak, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 3 from programs p, speakers s
 where p.slug like '2025-01-15%-24881229' and s.full_name = 'Hon. Dan Collins'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-01-14%-24881082' and s.full_name = 'Ed Boltz, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-01-14%-24881082' and s.full_name = 'Latife Neu, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 2 from programs p, speakers s
 where p.slug like '2025-01-14%-24881082' and s.full_name = 'Belisa Pang'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-01-13%-24881019' and s.full_name = 'Jenny L. Doling, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-01-13%-24881019' and s.full_name = 'Théda Page, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2025-01-01%-26016762' and s.full_name = 'David Chapman'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2025-01-01%-26016762' and s.full_name = 'Brian D. Flick, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2024-11-14%-24554028' and s.full_name = 'Brian D. Flick, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2024-10-10%-24449322' and s.full_name = 'M. Jonathan Hayes, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2024-10-10%-24449322' and s.full_name = 'Hon. Meredith Jury (Ret.)'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 2 from programs p, speakers s
 where p.slug like '2024-10-10%-24449322' and s.full_name = 'Hon. Laura Taylor (Ret.)'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2024-09-26%-24328425' and s.full_name = 'Lisa C. Thompson, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2024-08-22%-23640591' and s.full_name = 'Jenny L. Doling, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2024-08-22%-23640591' and s.full_name = 'Rachel Lynn Foley, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2024-06-20%-23997759' and s.full_name = 'Tara Salinas, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2024-05-16%-23609910' and s.full_name = 'Stephen E. Berken, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2024-05-16%-23609910' and s.full_name = 'Randy Nussbaum, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2024-04-04%-23609700' and s.full_name = 'Michael Primus, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2024-03-07%-23446467' and s.full_name = 'Stephen E. Berken, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2024-03-07%-23446467' and s.full_name = 'Tara Salinas, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2024-02-15%-23261037' and s.full_name = 'Lisa C. Thompson, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2024-01-18%-23150514' and s.full_name = 'Jenny L. Doling, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2024-01-18%-23150514' and s.full_name = 'Koury Hicks, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2023-11-09%-22755462' and s.full_name = 'Kara Gendron, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2023-11-09%-22755462' and s.full_name = 'Rashad Blossom, Esq.'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2023-08-24%-22446993' and s.full_name = 'James J. Haller'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2020-11-05%-18485532' and s.full_name = 'O. Max Gardner'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2020-11-05%-18485532' and s.full_name = 'Jay Patterson'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 0 from programs p, speakers s
 where p.slug like '2020-08-20%-18486036' and s.full_name = 'O. Max Gardner'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 1 from programs p, speakers s
 where p.slug like '2020-08-20%-18486036' and s.full_name = 'Thad Bartholow'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 2 from programs p, speakers s
 where p.slug like '2020-08-20%-18486036' and s.full_name = 'Karen Kellett'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 3 from programs p, speakers s
 where p.slug like '2020-08-20%-18486036' and s.full_name = 'Malissa Giles'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 4 from programs p, speakers s
 where p.slug like '2020-08-20%-18486036' and s.full_name = 'Tracy Giles'
on conflict (program_id, speaker_id) do nothing;
insert into program_speakers (program_id, speaker_id, confirmation, sort_order)
select p.id, s.id, 'confirmed', 5 from programs p, speakers s
 where p.slug like '2020-08-20%-18486036' and s.full_name = 'Abelardo Limon'
on conflict (program_id, speaker_id) do nothing;
