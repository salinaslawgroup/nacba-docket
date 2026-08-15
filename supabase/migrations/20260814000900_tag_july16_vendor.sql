-- ============================================================
--  July 16 is a vendor program
--  Safe to re-run. Does nothing on a database where the program
--  does not exist.
--
--  Life Settlements & Bankruptcy was presented by Scott Etish of
--  Coventry — a sponsor presenting their own product. Typed as a paid
--  CLE webinar it would issue the neutrality agreement, which forbids
--  promoting your own product and so cannot apply to him.
--
--  A one-off data correction. Ongoing tagging belongs in the app,
--  where the change is attributed to the person who made it.
-- ============================================================

update programs
   set kind = 'vendor'
 where event_date = date '2026-07-16'
   and kind is distinct from 'vendor';

insert into program_categories (program_id, category_id)
select p.id, c.id
  from programs p
  cross join categories c
 where p.event_date = date '2026-07-16'
   and c.name = 'Vendor'
on conflict do nothing;
