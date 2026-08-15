-- ============================================================
--  Categories in alphabetical order
--  Safe to re-run.
--
--  sort_order was a hand-picked sequence. With eleven categories a
--  reader scans for a name rather than following a curated order, so
--  it now simply mirrors the alphabet and stays in step with the app.
-- ============================================================

with ordered as (
  select id, row_number() over (order by name) * 10 as n
    from categories
)
update categories c
   set sort_order = o.n
  from ordered o
 where o.id = c.id
   and c.sort_order is distinct from o.n;
