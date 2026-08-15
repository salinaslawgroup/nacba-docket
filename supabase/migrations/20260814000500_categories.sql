-- ============================================================
--  NACBA Webinar Docket — programming categories
--  Safe to re-run.
--
--  One flat list, applied to BOTH programs and speakers. These are
--  NACBA's actual programming tracks rather than a legal taxonomy:
--  some are subject matter (Chapter 13, Taxes), some are audience
--  (Paralegal), some are level (Bankruptcy Basics), some are a named
--  series (ABLI, AI Advantage). Tagging speakers with the same list
--  is what makes "who could speak on this?" answerable.
-- ============================================================

create table if not exists categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  description text not null default '',
  sort_order  int  not null default 100,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

create table if not exists program_categories (
  program_id  uuid not null references programs(id)   on delete cascade,
  category_id uuid not null references categories(id) on delete cascade,
  primary key (program_id, category_id)
);

create table if not exists speaker_categories (
  speaker_id  uuid not null references speakers(id)   on delete cascade,
  category_id uuid not null references categories(id) on delete cascade,
  primary key (speaker_id, category_id)
);

create index if not exists program_categories_cat_idx on program_categories (category_id);
create index if not exists speaker_categories_cat_idx on speaker_categories (category_id);

alter table categories         enable row level security;
alter table program_categories enable row level security;
alter table speaker_categories enable row level security;

do $$
declare tbl text;
begin
  foreach tbl in array array['categories','program_categories','speaker_categories'] loop
    execute format('drop policy if exists %I_read  on %I', tbl, tbl);
    execute format('drop policy if exists %I_write on %I', tbl, tbl);
    execute format(
      'create policy %I_read on %I for select to authenticated using (public.is_allowed())', tbl, tbl);
    execute format(
      'create policy %I_write on %I for all to authenticated using (public.is_allowed()) with check (public.is_allowed())', tbl, tbl);
  end loop;
end $$;

insert into categories (name, description, sort_order) values
  ('Chapter 13',                    '',                                                    10),
  ('Student Loans',                 '',                                                    20),
  ('Practice Management / Marketing','',                                                   30),
  ('AI Advantage',                  'NACBA''s AI programming series',                      40),
  ('Paralegal',                     'Programs written for paralegals and support staff',   50),
  ('Bankruptcy Basics',             'Foundational programs for newer practitioners',       60),
  ('ABLI',                          'American Bankruptcy Law Institute — litigation',      70),
  ('Taxes',                         '',                                                    80),
  ('Hot Topics',                    'Timely programs that do not sit in a standing track', 90)
on conflict (name) do update
  set description = excluded.description,
      sort_order  = excluded.sort_order;

-- Who could speak on this? — for the roster screen.
create or replace view speaker_expertise
with (security_invoker = true) as
select s.id as speaker_id, s.full_name, s.firm, s.email,
       c.id as category_id, c.name as category, c.sort_order
  from speakers s
  join speaker_categories sc on sc.speaker_id = s.id
  join categories c          on c.id = sc.category_id
 where c.active;

-- ============================================================
--  Speaker type
--  Deliberately NOT a debtor/creditor split beyond one line: NACBA
--  distinguishes debtor's counsel from everyone else, and otherwise
--  cares about role — trustee, judge, paralegal, other professional.
--  One value per speaker; the topic categories above carry expertise.
-- ============================================================

alter table speakers
  add column if not exists speaker_type text;

do $$
begin
  alter table speakers drop constraint if exists speakers_speaker_type_check;
  alter table speakers add constraint speakers_speaker_type_check
    check (speaker_type is null or speaker_type in
      ('debtor_attorney','non_debtor_attorney','trustee','judge','paralegal','other'));
end $$;

comment on column speakers.speaker_type is
  'debtor_attorney | non_debtor_attorney | trustee (7 or 13) | judge | paralegal | other';
