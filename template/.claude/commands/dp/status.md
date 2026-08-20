---
description: Show the state of every feature and task on the board
---

Show the project's current state.

Collect the raw data:

!`bash scripts/status.sh 2>/dev/null || echo "scripts/status.sh not found"`

Then present it to the user as:

1. **Features** — slug, title, spec status, how many tasks are done out of the total.
2. **Ready to delegate** — cards with `status: todo` whose `depends_on` are all `done`.
   These are the ones the user can start right now.
3. **Awaiting review** — cards with `status: in_review`.
4. **Needs rework** — cards with `status: changes_requested`, with their attempt count.
5. **Blocked or escalated** — cards with `status: blocked` or `escalated`, and why.
   For each, say what you recommend: split the card, rewrite its Context, or take it over.

Finish with one concrete suggestion for the next action.
