---
description: Research a topic in the codebase and externally, then write research.md
argument-hint: <topic or feature slug>
---

You are the tech lead. Research **$ARGUMENTS** before any design work happens.

## Do this

1. **Search this codebase first.** Find every existing utility, module, pattern, or
   abstraction that already solves part of this. Record where each one lives with a
   `file:line`. A plan that reimplements something already here is a planning failure.
2. **Read the project's own documents:** `docs/constitution.md`, `docs/architecture.md`,
   `docs/stack.md`, and any related ADR in `docs/adr/`.
3. **Research externally only if the decision needs it** — library choice, protocol,
   algorithm, known pitfalls. Prefer official docs. Record the URL and the date checked.
4. **Lay out at least two real options** with honest pros, cons, and cost. If there is
   genuinely only one option, say why the alternatives are excluded.
5. **Recommend one** and say what it means for the plan.

## Output

Write to `docs/specs/<feature>/research.md` using `docs/.templates/research.md`.
If the feature folder does not exist yet, ask the user whether to create it with
`bash scripts/new-feature.sh <slug>` or to keep this as standalone research in
`docs/research/<topic>.md`.

If this research settles an architectural question, also draft an ADR from
`docs/.templates/adr.md` — architecture decisions are yours to record, not to leave implicit.

Do not write any production code in this step.
