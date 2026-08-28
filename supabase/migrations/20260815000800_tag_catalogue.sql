-- ============================================================
--  Categorise the back catalogue, and correct 24 September
--  Safe to re-run.
--
--  24 Sep moves from Chapter 13 to Hot Topics, per the Education
--  Committee. Cramdown runs through 1325(a)(5)(B), but the program
--  exists because of a fresh 9th Circuit win, which is what Hot
--  Topics is for.
--
--  5 Nov is deliberately left without ABLI — confirmed.
-- ============================================================

-- ---------- 24 September ----------
delete from program_categories pc
 using programs p, categories c
 where pc.program_id = p.id and pc.category_id = c.id
   and p.event_date = date '2026-09-24' and c.name = 'Chapter 13';

insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.event_date = date '2026-09-24' and not p.archived and c.name = 'Hot Topics'
on conflict do nothing;

-- ---------- the catalogue ----------

insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-27487665' and c.name = 'AI Advantage'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-27006072' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-26714823' and c.name = 'Practice Management / Marketing'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-26714802' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
-- ? exemptions + litigating the objection; no exemptions track
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-26714781' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
-- description says ABLI's Solar Panels
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-26714718' and c.name = 'ABLI'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-26709888' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
-- ? liens and cramdown; tax liens also discussed
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-26280312' and c.name = 'Chapter 13'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-26152884' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-25956177' and c.name = 'Paralegal'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-25855314' and c.name = 'Chapter 13'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-25617216' and c.name = 'Hot Topics'
on conflict do nothing;
-- ? 541 property of the estate — doctrine, not basics exactly
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-25721439' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-25725366' and c.name = 'Hot Topics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-25714299' and c.name = 'Hot Topics'
on conflict do nothing;
-- ? exemption planning with an ethics angle
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-25279893' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-25149987' and c.name = 'Hot Topics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-24881376' and c.name = 'Practice Management / Marketing'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-24881313' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-24881229' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-24881082' and c.name = 'Student Loans'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-24881019' and c.name = 'Practice Management / Marketing'
on conflict do nothing;
-- Google Ads for bankruptcy attorneys
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-26016762' and c.name = 'Vendor'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-26016762' and c.name = 'Practice Management / Marketing'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-24554028' and c.name = 'Hot Topics'
on conflict do nothing;
-- ? issue preclusion with two retired judges — advanced doctrine
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-24449322' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-24328425' and c.name = 'Hot Topics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-23640591' and c.name = 'Practice Management / Marketing'
on conflict do nothing;
-- ? client handling through layoffs, divorce, death
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-23997759' and c.name = 'Practice Management / Marketing'
on conflict do nothing;
-- ? litigating cost-effectively
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-23609910' and c.name = 'Practice Management / Marketing'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-23609700' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-23446467' and c.name = 'Chapter 13'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-23261037' and c.name = 'Hot Topics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-23150514' and c.name = 'AI Advantage'
on conflict do nothing;
-- ? 523(a)(2) fraud discharge litigation
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-22755462' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-22446993' and c.name = 'Chapter 13'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-22446993' and c.name = 'Practice Management / Marketing'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-18485532' and c.name = 'Hot Topics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-18486036' and c.name = 'Hot Topics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-27526935' and c.name = 'AI Advantage'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-26916822' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
-- ? escrow ABCs; the 17 Sep escrow program is ABLI-branded, this one is not
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-27420906' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-27154395' and c.name = 'Taxes'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-26875809' and c.name = 'Vendor'
on conflict do nothing;
insert into program_categories (program_id, category_id)
select p.id, c.id from programs p, categories c
 where p.slug like '%%-18486267' and c.name = 'Bankruptcy Basics'
on conflict do nothing;
