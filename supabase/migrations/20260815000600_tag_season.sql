-- ============================================================
--  Categorise the 2026 season
--  Safe to re-run.
--
--  16 July is already tagged Vendor and is left alone.
--
--  Two judgement calls worth seeing:
--    - 5 Nov (private student loan trials) is NOT tagged ABLI. ABLI
--      reads as a branded series — 17 Sep is literally titled for it —
--      rather than a label for any litigation program.
--    - 24 Sep is Chapter 13 because cramdown runs through
--      1325(a)(5)(B), not because the program says 'Chapter 13'.
--
--  Every one of these is a chip on the program page. Change any that
--  read wrong; nothing here is load-bearing.
-- ============================================================

-- 2026-07-30 — Sommer and Haller on recent decisions — the standing case law update.
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-07-30' and not p.archived and c.name = 'Case Law'
on conflict do nothing;

-- 2026-08-06 — Debt settlement companies. Your call: a one-off, so Hot Topics.
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-08-06' and not p.archived and c.name = 'Hot Topics'
on conflict do nothing;

-- 2026-08-13 — Titled around NACBA's AI Advantage, plus funding travel, staff training and marketing.
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-08-13' and not p.archived and c.name = 'AI Advantage'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-08-13' and not p.archived and c.name = 'Practice Management / Marketing'
on conflict do nothing;

-- 2026-09-17 — Titled 'ABLI: In Depth Escrow Accounting' — an ABLI-branded program.
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-09-17' and not p.archived and c.name = 'ABLI'
on conflict do nothing;

-- 2026-09-24 — Manufactured home cramdowns turn on 11 U.S.C. 1325(a)(5)(B), a Chapter 13 mechanism.
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-09-24' and not p.archived and c.name = 'Chapter 13'
on conflict do nothing;

-- 2026-10-22 — SLAP workflows, and the title says 'for Attorneys and Their Paralegals'.
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-10-22' and not p.archived and c.name = 'Student Loans'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-10-22' and not p.archived and c.name = 'Paralegal'
on conflict do nothing;

-- 2026-11-05 — Private student loan trials. NOT tagged ABLI — that looks like a branded series, not any litigation.
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-11-05' and not p.archived and c.name = 'Student Loans'
on conflict do nothing;

-- 2026-11-19 — Reading tax returns; the description addresses attorneys and their paralegals.
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-11-19' and not p.archived and c.name = 'Taxes'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-11-19' and not p.archived and c.name = 'Paralegal'
on conflict do nothing;

-- 2026-12-03 — The Go-To Paralegal — career development plus firm systems and workflows.
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-12-03' and not p.archived and c.name = 'Paralegal'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-12-03' and not p.archived and c.name = 'Practice Management / Marketing'
on conflict do nothing;

-- 2026-12-10 — Profitability, fee agreements, staffing, marketing, and time-saving AI tools.
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-12-10' and not p.archived and c.name = 'Practice Management / Marketing'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-12-10' and not p.archived and c.name = 'AI Advantage'
on conflict do nothing;
