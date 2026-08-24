---
title: Knowledge base
updated: YYYY-MM-DD
---

# Knowledge base

`docs/knowledge/` is the project's persistent, cross-feature memory. It exists so the lead
never re-derives from scratch something it (or a past task) already worked out about this
codebase — the single biggest lever for keeping token spend down as the project grows.

## The two-tier split

- **`docs/specs/<feature>/research.md`** — ephemeral, feature-scoped. What this particular
  feature needed to investigate. Written once, read a few times, then mostly forgotten.
- **`docs/knowledge/`** — durable, project-scoped. What's true about a module regardless of
  which feature is being built. Written once, appended to forever, read at the start of
  every research step and every task that touches that module.

A finding belongs in the knowledge base if it would still be true for a completely different
feature touching the same code. If it's only true because of what this feature happens to
need, it stays in that feature's own `research.md`.

## Shape

```
docs/knowledge/
├── INDEX.md              read FIRST, always — one line per entry, cheap to scan
└── modules/
    └── <name>.md         cumulative notes on one module — appended to, never rewritten
```

`INDEX.md` is intentionally short. It exists so the lead can decide what's already known
without opening every module file — only the ones actually relevant get opened. A module
file's `Log` section is chronological so its history reads as a diff, the same reason
`docs/adr/` entries are never edited after being accepted.

## When it gets written

- **`/dp:onboard`** seeds it from the initial codebase snapshot — every module traced deeply
  enough to be worth remembering gets a file here, not just a row in `architecture.md`.
- **`/dp:research`** reads `INDEX.md` before any exploration and only investigates gaps; at
  the end, it promotes anything durable it found, beyond what the feature itself needed.
- **`/dp:review` and `/dp:accept`** promote findings that surface during review or
  acceptance and are true beyond the one task — a gotcha, a wrong assumption in an existing
  module file, a contract nobody had written down.

## How task cards use it

A card can list `knowledge_refs:` — paths into `docs/knowledge/modules/`. Point the executor
there instead of re-explaining something already documented. This is the direct token
saving at the task level: the executor is a real Claude Code agent with Read/Grep/Glob in
this repository, so a pointer costs a fraction of what pasting the same content into every
card that touches that module would cost, repeated across every future task.

## Keeping it honest

- Update `INDEX.md`'s date whenever you touch the module file it points to. A stale index
  entry is worse than no entry — it sends the next reader to something out of date without
  warning.
- Append, don't rewrite. If something in a module file turns out to be wrong, add a new Log
  entry correcting it rather than silently editing the old one away.
- A module file with no `INDEX.md` row will not be found. Every file needs its row.
