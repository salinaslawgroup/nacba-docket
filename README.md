# NACBA Webinar Docket

A shared tracker for NACBA Education Committee webinar operations. Enter a webinar
date and the system generates every deadline that hangs off it — registration open,
speaker package, materials, run of show, follow-up — with an owner on each one.

Built for the 2026 season: 11 programs, 19 speakers.

## What's in this repository

This repo holds **only the application shell**. No speaker names, no email addresses,
no NACBA data of any kind. Everything is stored in Supabase behind an email sign-in.
That split is deliberate: GitHub Pages serves public sites on the free plan, and the
speaker roster includes federal court and Department of Justice addresses that must
not be publicly readable.

```
index.html         the whole app — no build step, no dependencies to install
db/01_schema.sql   tables, the docket engine, row-level security
db/03_editing.sql  append-only change history
```

`db/02_seed.sql` — the 2026 season — is **git-ignored on purpose**. It carries
speaker contact details, including federal court and Department of Justice
addresses. It is applied directly in Supabase and kept outside this repository.

The Supabase publishable key in `index.html` is safe in public source. It is designed
to ship in browser code; access is controlled by row-level security, not by hiding
the key.

## Setup

**1. Run the SQL.** In the Supabase project's SQL editor, run `db/01_schema.sql`,
then `db/02_seed.sql`, then `db/03_editing.sql`. All three are safe to re-run.

Run the history migration *last* — seeding before it is deliberate, so the initial
import doesn't arrive as 200 log entries.

**2. Add the people who need access.** Nobody sees a single row unless their email is
in `allowed_emails`:

```sql
insert into allowed_emails (email, role, full_name) values
  ('someone@nacba.com', 'coordinator', 'Name Here')
on conflict (email) do update set role = excluded.role;
```

Roles: `admin`, `coordinator`, `moderator`, `marketing`, `emc_chair`, `staff`.
Only `admin` can change the list. Removing someone is a `delete` — they can still
sign in, but see nothing.

**3. Allow the site to receive sign-in links.** In Supabase → Authentication → URL
Configuration, add the published site URL to **Redirect URLs**. Sign-in links fail
silently without this.

**4. Optional but recommended.** In Authentication → Providers → Email, turn off
"Enable sign-ups" once everyone is added. Strangers can otherwise request a link
and create an account — they will see nothing, but there is no reason to allow it.

## How the docket works

`docket_template` holds the 16 canonical deadlines, each as an offset from the event
date. Inserting a program fires a trigger that generates its tasks; adding a speaker
generates their five package items. Adding the 2027 season is one insert per program.

Editing a row in `docket_template` changes the rule for **future** programs only.
Existing tasks are left alone, so a mid-season policy change cannot silently rewrite
history.

The three conflicting materials deadlines in the source documents are resolved here:
materials are **due at T−14**, **overdue at T−7** (the CLE filing cutoff), and the
48-hour item from §6.2 is *QC review complete* — not receipt of materials.

## Deploying

Any static host works; the app is one file. For GitHub Pages: Settings → Pages →
Deploy from branch → `main` / root.

## Moving this to NACBA

Both halves transfer independently.

**The repo:** Settings → Transfer ownership. Free, keeps history, leaves redirects.

**The database:** Supabase can transfer a project between organizations, but don't
depend on it. The durable path is: create a project in NACBA's account, run
`01_schema.sql`, export the tables as CSV from the old project and import them, then
change the two constants at the top of `index.html`. About twenty minutes, and it
works regardless of plan or org membership.

Keeping this in its own Supabase project — never alongside other data — is what makes
that possible.

## Editing

Everything that changes week to week is editable in the app: a program's title,
description, date and note; speakers on a program and their confirmation status;
and the persistent speaker record (firm, email, phone, name pronunciation, and
where the headshot and bio are filed).

**Moving a date is safe.** Tasks store *offsets*, not dates. Due dates are computed
from the program's event date, so changing it shifts the whole docket and every
completed checkbox stays completed.

**Creating a program generates its docket.** Add one with a date and title and its
16 deadlines appear with it. Adding a speaker generates their five package items.

**Every content edit is logged** — which field, old value, new value, who, when —
and shown per program and account-wide. The log is append-only: no policy grants
insert, update, or delete, so it cannot be edited from the app at all. Task
checkboxes and package items are not logged; they already carry their own stamps,
and logging them would bury real edits under routine ticking.

Deleting a speaker from a program removes their package items but leaves the roster
record intact, so their bio and pronunciation survive for the next booking.
