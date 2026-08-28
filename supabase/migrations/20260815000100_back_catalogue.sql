-- ============================================================
--  Back catalogue — NACBA webinar library
--  Read from nacba.org/store (catid 837538) on 15 Aug 2026.
--  Safe to re-run: matched on slug, nothing overwritten.
--
--  Every row is archived = true, so none generates a docket and none
--  appears in the season view. They exist to give speakers a history.
--
--  Slugs carry the store product ID. Two NACBA Week 2026 sessions are
--  both dated 13 January by the store, and without the ID their slugs
--  would collide and one would be silently dropped.
--
--  Speakers are recorded in `note` as text rather than linked. The
--  store lists names inconsistently and often truncated; creating
--  roster records from that would split one person across several
--  spellings. Attach them by hand from each program page, where the
--  name matches the existing roster entry.
--
--  Not imported: NACBA WEEK MAIN SPONSOR, NACBA WEEK SPONSOR, and
--  Bankruptcy Tech Bonanza Presenter — sponsorship SKUs, not programs.
--  Case Law Update is already on the 2026 schedule for 30 July, so the
--  store link is attached to it below instead of duplicating it.
-- ============================================================

insert into programs (slug, event_date, title, kind, archived, store_url, note) values
  ('2026-05-14-the-ai-advantage-the-27487665', '2026-05-14', 'The AI Advantage: The Clock Is Ticking; AI & the Future of Bankruptcy Part 1', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=27487665', 'Store $399.00. From the NACBA store listing.'),
  ('2026-03-05-bankruptcy-toolbox-part-ii-27006072', '2026-03-05', 'Bankruptcy Toolbox Part II', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=27006072', 'Store $135.00. From the NACBA store listing. Speakers as listed: Ashley Morgan, Esq.; Mike Assad, Esq.'),
  ('2026-01-16-nacba-week-2026-day-26714823', '2026-01-16', 'NACBA Week 2026 Day 5: Are You Prepared for the Recession?', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=26714823', 'Store $85.00. From the NACBA store listing. Speakers as listed: Jenny Doling, Esq.'),
  ('2026-01-15-nacba-week-2026-day-26714802', '2026-01-15', 'NACBA Week 2026 Day 4: A Practical Toolbox for Chapters 7 and 13', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=26714802', 'Store $85.00. From the NACBA store listing. Speakers as listed: Ahren Tiller, Esq.'),
  ('2026-01-13-nacba-week-2026-day-26714781', '2026-01-13', 'NACBA Week 2026 Day 3: Claiming Exemptions and How to Litigate the Objection', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=26714781', 'Store $85.00. From the NACBA store listing. Speakers as listed: Carey Ebert; Latife Neu, Esq.; Marc Stern, Esq.'),
  ('2026-01-13-nacba-week-2026-day-26714718', '2026-01-13', 'NACBA Week 2026 Day 2: Solar Panels in Bankruptcy: Tools, Traps, and Tactics', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=26714718', 'Store $85.00. From the NACBA store listing. Speakers as listed: Ed Boltz, Esq.; John T. O''Neil'),
  ('2026-01-12-nacba-week-2026-day-26709888', '2026-01-12', 'NACBA Week 2026 Day 1: Bankruptcy Bootcamp: Getting Up to Speed Fast', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=26709888', 'Store $85.00. From the NACBA store listing. Speakers as listed: Tara Salinas, Esq.; Samantha Tirado, Esq.'),
  ('2025-10-30-liens-liens-liens-strategies-26280312', '2025-10-30', 'Liens! Liens! Liens! Strategies for Dealing with Liens in Bankruptcy', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=26280312', 'Store $145.00. From the NACBA store listing.'),
  ('2025-09-04-mastering-the-complexities-of-26152884', '2025-09-04', 'Mastering the Complexities of the Bankruptcy Discharge & Dismissal', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=26152884', 'Store $135.00. From the NACBA store listing.'),
  ('2025-08-07-paralegal-wisdom-what-i-25956177', '2025-08-07', 'Paralegal Wisdom: What I Wish I Knew When I Started', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=25956177', 'Store $145.00. From the NACBA store listing.'),
  ('2025-07-31-pulling-back-the-curtain-25855314', '2025-07-31', 'Pulling Back the Curtain on Chapter 13 Trustee Operations', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=25855314', 'Store $145.00. From the NACBA store listing. Speakers as listed: Carey Ebert, Standing Ch 13 Trustee'),
  ('2025-07-10-merchant-cash-advance-mca-25617216', '2025-07-10', 'Merchant Cash Advance (MCA) Problems & Solutions', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=25617216', 'Store $85.00. From the NACBA store listing.'),
  ('2025-06-26-bare-legal-title-v-25721439', '2025-06-26', 'Bare Legal Title v. Equitable Interests 11 U.S.C. § 541: Practical Considerations', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=25721439', 'Store $95.00. From the NACBA store listing.'),
  ('2025-06-12-deed-fraud-encore-panel-25725366', '2025-06-12', 'Deed Fraud Encore Panel', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=25725366', 'Store $95.00. From the NACBA store listing.'),
  ('2025-05-29-post-convention-deep-dive-25714299', '2025-05-29', 'Post-Convention Deep Dive: Navigating SBA Loans as Creditors — EIDLs, PPPs & More', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=25714299', 'Store $85.00. From the NACBA store listing.'),
  ('2025-03-20-pre-bankruptcy-exemption-planning-25279893', '2025-03-20', 'Pre-Bankruptcy Exemption Planning: Ethical Advocacy', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=25279893', 'Store $95.00. From the NACBA store listing. Speakers as listed: Hon. Elizabeth L. Gunn'),
  ('2025-02-20-cannabis-bankruptcy-navigating-the-25149987', '2025-02-20', 'Cannabis & Bankruptcy: Navigating the Legal Gray Areas', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=25149987', 'Store $95.00. From the NACBA store listing. Speakers as listed: Hon. Neil W. Bason'),
  ('2025-01-17-nacba-week-2025-day-24881376', '2025-01-17', 'NACBA Week 2025 Day 5: Resonating with Differing Generations', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=24881376', 'Store $85.00. From the NACBA store listing.'),
  ('2025-01-16-nacba-week-2025-day-24881313', '2025-01-16', 'NACBA Week 2025 Day 4: Creative Strategies for Overcoming Challenges in Consumer Cases', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=24881313', 'Store $85.00. From the NACBA store listing. Speakers as listed: Tara Salinas, Esq.'),
  ('2025-01-15-nacba-week-2025-day-24881229', '2025-01-15', 'NACBA Week 2025 Day 3: Strategic Approaches to Chapter 7 Bankruptcy Settlements', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=24881229', 'Store $85.00. From the NACBA store listing. Speakers as listed: Kara Gendron, Esq.; Luke Homen, Esq.; Nicole Novak, Esq.; Hon. Dan Collins'),
  ('2025-01-14-nacba-week-2025-day-24881082', '2025-01-14', 'NACBA Week 2025 Day 2: Student Loan Forecast and Predictions', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=24881082', 'Store $85.00. From the NACBA store listing. Speakers as listed: Ed Boltz, Esq.; Latife Neu, Esq.'),
  ('2025-01-13-nacba-week-2025-day-24881019', '2025-01-13', 'NACBA Week 2025 Day 1: Strategies for a Profitable Consumer Bankruptcy Firm', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=24881019', 'Store $85.00. From the NACBA store listing. Speakers as listed: Jenny L. Doling, Esq.; Théda Page, Esq.'),
  ('2024-11-14-zombie-mortgages-24554028', '2024-11-14', 'Zombie Mortgages', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=24554028', 'Store $85.00. From the NACBA store listing. Speakers as listed: Brian Flick'),
  ('2024-10-10-issue-preclusion-24449322', '2024-10-10', 'Issue Preclusion', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=24449322', 'Store $95.00. From the NACBA store listing. Speakers as listed: M. Jonathan Hayes, Esq.; Hon. Meredith Jury'),
  ('2024-09-26-talk-softly-and-carry-24328425', '2024-09-26', 'Talk Softly and Carry a Big Stick: Options for Businesses in Financial Distress', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=24328425', 'Store $85.00. From the NACBA store listing.'),
  ('2024-08-22-bk-fee-agreements-fee-23640591', '2024-08-22', 'BK Fee Agreements: Fee Agreement Clauses Every BK Attorney Should Use!', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=23640591', 'Store $85.00. From the NACBA store listing.'),
  ('2024-06-20-seeing-debtors-through-their-23997759', '2024-06-20', 'Seeing Debtors Through Their Darkest Hours: Layoffs, Divorce & Death', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=23997759', 'Store $85.00. From the NACBA store listing.'),
  ('2024-05-16-litigating-bankruptcy-issues-on-23609910', '2024-05-16', 'Litigating Bankruptcy Issues On the Cheap', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=23609910', 'Store $85.00. From the NACBA store listing. Speakers as listed: Stephen E. Berken, Esq.; Randy Nussbaum, Esq.'),
  ('2024-04-04-the-malleable-means-test-23609700', '2024-04-04', 'The Malleable Means Test – Room to Move', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=23609700', 'Store $85.00. From the NACBA store listing. Speakers as listed: Michael Primus, Esq.'),
  ('2024-03-07-2-for-1-eidl-23446467', '2024-03-07', '2 for 1: EIDL Proceeds Usage & Pre-Bankruptcy Planning in Chapter 13', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=23446467', 'Store $85.00. From the NACBA store listing.'),
  ('2024-02-15-cya-from-the-cta-23261037', '2024-02-15', 'CYA from the CTA (Corporate Transparency Act)', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=23261037', 'Store $85.00. From the NACBA store listing.'),
  ('2024-01-18-bankruptcy-ai-how-to-23150514', '2024-01-18', 'Bankruptcy & AI: How to Harness the Power of AI and Limit Risks', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=23150514', 'Store $95.00. From the NACBA store listing. Speakers as listed: Jenny L. Doling, Esq.'),
  ('2023-11-09-litigating-the-fraud-exception-22755462', '2023-11-09', 'Litigating the Fraud Exception to Discharge', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=22755462', 'Store $35.00. From the NACBA store listing. Speakers as listed: Kara Gendron, Esq.; Rashad Blossom, Esq.'),
  ('2023-08-24-comparison-of-chapter-13-22446993', '2023-08-24', 'Comparison of Chapter 13 Flat Fees Across the United States', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=22446993', 'Store $35.00. From the NACBA store listing.'),
  ('2020-11-05-covid-19-forbearance-what-18485532', '2020-11-05', 'COVID-19 Forbearance – What Next!', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=18485532', 'Store $109.00. From the NACBA store listing. Speakers as listed: O. Max Gardner; Jay Patterson'),
  ('2020-08-20-forbearance-cares-act-and-18486036', '2020-08-20', 'Forbearance, CARES Act and Wells Fargo', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=18486036', 'Store $109.00. From the NACBA store listing. Speakers as listed: O. Max Gardner; Thad Bartholow; Karen Kellett; Malissa Giles; Tracy Giles; Abelardo Limon'),
  ('2026-01-01-the-ai-advantage-the-27526935', '2026-01-01', 'The AI Advantage; The Clock Is Ticking; AI & the Future of Bankruptcy Part 2', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=27526935', 'Store $399.00. From the NACBA store listing.  ** PLACEHOLDER DATE — the store does not state when this ran. Part 1 ran 14 May 2026, so Part 2 is later in 2026. Correct before relying on it. **'),
  ('2026-01-01-bankruptcy-toolbox-part-i-26916822', '2026-01-01', 'Bankruptcy Toolbox, Part I', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=26916822', 'Store $135.00. From the NACBA store listing.  ** PLACEHOLDER DATE — the store does not state when this ran. Part II ran 5 Mar 2026, so Part I is earlier. Correct before relying on it. **'),
  ('2026-01-01-escrow-abcs-the-good-27420906', '2026-01-01', 'Escrow ABCs: The Good, Bad, & Ugly', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=27420906', 'Store $135.00. From the NACBA store listing.  ** PLACEHOLDER DATE — the store does not state when this ran. Product ID sits among 2026 items. Correct before relying on it. **'),
  ('2026-01-01-taxes-and-bankruptcy-27154395', '2026-01-01', 'Taxes and Bankruptcy', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=27154395', 'Store $135.00. From the NACBA store listing.  ** PLACEHOLDER DATE — the store does not state when this ran. Product ID sits among 2026 items. Correct before relying on it. **'),
  ('2026-01-01-nacba-bankruptcy-software-bonanza-26875809', '2026-01-01', 'NACBA Bankruptcy Software Bonanza Winter 2026', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=26875809', 'Store $300.00. From the NACBA store listing.  ** PLACEHOLDER DATE — the store does not state when this ran. Titled Winter 2026. Correct before relying on it. **'),
  ('2025-01-01-nacba-bankruptcy-tech-bonanza-26016762', '2025-01-01', 'NACBA Bankruptcy Tech Bonanza 2025', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=26016762', 'Store $150.00. From the NACBA store listing. Speakers as listed: David Chapman; Brian Flick, Esq.  ** PLACEHOLDER DATE — the store does not state when this ran. Titled 2025; day 1 was a Monday 18 August. Correct before relying on it. **'),
  ('2019-01-01-invoking-and-asserting-exemptions-18486267', '2019-01-01', 'Invoking and Asserting Exemptions in Reopened Case', 'paid', true, 'https://nacba.org/store/viewproduct.aspx?ID=18486267', 'Store $35.00. From the NACBA store listing.  ** PLACEHOLDER DATE — the store does not state when this ran. Store says Thursday 24 January with no year; ID neighbours the 2020 uploads. Correct before relying on it. **')
on conflict (slug) do nothing;

-- Already on the schedule for 30 July 2026 — just record where it sells.
update programs
   set store_url = 'https://nacba.org/store/viewproduct.aspx?ID=27665514'
 where event_date = date '2026-07-30' and store_url = '';
