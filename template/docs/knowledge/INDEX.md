---
title: Knowledge index
updated: YYYY-MM-DD
---

# Knowledge index

Read this file FIRST, before any broad exploration — in `/dp:research`, and whenever a task
card's `knowledge_refs` sends you here. It exists so the lead never re-derives from scratch
what it (or a past task) already figured out about this codebase.

One line per entry. Update this table whenever you append to a module file below; never let
it drift from what the module files actually say.

| Topic | Module file | Hook | Updated |
| --- | --- | --- | --- |
| _example — delete this row_ | [modules/example.md](modules/example.md) | one line: the single fact worth remembering | YYYY-MM-DD |

## Rules

- **Consult before exploring.** A grep sweep that re-discovers something already indexed
  here is wasted tokens — read the module file instead.
- **Append, don't rewrite.** Module files grow; new findings go at the bottom of their `Log`
  section so the history reads as a diff.
- **Promote what's general, not what's feature-specific.** A fact true about the module
  regardless of which feature is being built belongs here. Something only true for the
  current feature belongs in that feature's own `research.md`.
- **Every module file needs a row here**, or nobody will find it.
