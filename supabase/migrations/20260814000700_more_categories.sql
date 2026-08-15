-- ============================================================
--  Two more programming categories
--  Safe to re-run.
--
--  A separate migration rather than an edit to 000500: if that one has
--  already been applied, the CLI will not re-run it and the new rows
--  would never land.
--
--  Case Law   — the standing case law update programs.
--  Vendor     — programs presented by, or built around, a vendor.
--               July 16 (Life Settlements, Coventry) is one of these.
--
--  Deliberately NOT added: Chapter 7. It is most of consumer
--  bankruptcy, so tagging it would mark nearly everything and
--  distinguish nothing.
-- ============================================================

insert into categories (name, description, sort_order) values
  ('Case Law', 'Recent decisions and case law update programs', 85),
  ('Vendor',   'Programs presented by, or built around, a vendor', 88)
on conflict (name) do update
  set description = excluded.description,
      sort_order  = excluded.sort_order;
