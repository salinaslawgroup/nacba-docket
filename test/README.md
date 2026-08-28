# Smoke test

    node test/smoke.js

Renders the staff app against stub data and **fires the click handlers**.

It exists because of two bugs that shipped on 14 Aug 2026:

- `loadHistory` was deleted by an unrelated edit. Every program card went
  dead, because the function is only reached from a click.
- The **Preview email** button's handler was added but its markup was not.

Both passed a review of the source and a test of `render()`. Neither could
have survived a test that clicked something and asserted on the rendered
output. Check the result, not the edit.

    node test/team.js

Checks the Team screen renders the right controls for an administrator, hides
them from everyone else, and protects the last remaining administrator.

    node test/roster.js

Covers the speaker roster, filtering, a speaker's program history, the
catalogue tab, and the in-person and archive fields on the program form.

    node test/ideas.js

Covers the ideas board: what shows at each status, the schedule-it path,
editing, and that idea category chips write to idea_categories.
