---
description: Create a feature folder and write spec.md (what and why)
argument-hint: <feature slug, e.g. token-refresh>
---

You are the tech lead. Write the specification for **$ARGUMENTS**.

## Do this

1. Create the feature folder:

   !`bash scripts/new-feature.sh "$ARGUMENTS" 2>&1 | tail -20`

2. Fill `spec.md` from the template already placed there. Rules:
   - **What and why only.** No implementation choices — those go in `plan.md`.
   - Every acceptance criterion must be observable and testable, written as
     `Given … when … then …`, and given an ID (`AC-1`, `AC-2`, …). Tasks and reviews
     reference these IDs, so vague criteria break the whole downstream process.
   - Write the non-goals and out-of-scope sections. They are not filler; they are what
     stops the executor from inventing work.
3. **Ask the user everything you are unsure about, in one batch**, using the question tool.
   Do not guess at requirements. Record anything still unresolved under Open questions.
4. Set `status: ready` only when no open question can still change an acceptance criterion.

## Then

Show the user the acceptance criteria and confirm them before moving on to `/dp:plan`.
A spec the user has not read is not a spec.
