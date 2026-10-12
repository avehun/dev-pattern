---
name: knowledge
description: How to read and write the project knowledge base in docs/dp/knowledge/. Use before exploring unfamiliar code, and whenever you add or update a knowledge module.
---

# Project knowledge base

`docs/dp/knowledge/` is the project's durable memory: what has already been worked out
about this codebase, so nobody explores the same code twice.

## Reading

1. Read `docs/dp/knowledge/INDEX.md`. Open only the modules whose topic or keywords match.
2. Run `dp-kb-stale`. A stale module describes files that changed after `verified_at`:
   trust its *Decisions*, re-check its *Map* and *Contracts* against the code.
3. Explore the code only for what the index does not answer.

## What belongs in a module

Write what grep cannot give back quickly:

- where things live and how they connect (`file:line` map)
- contracts and invariants callers rely on
- gotchas: what surprised you, what is easy to break
- decisions: why it is built this way

Do not copy code, restate what one file read would show, or record task-specific
details. A finding belongs here only if it would still help a different task in the same code.

## Writing

- One topic per file: `docs/dp/knowledge/<topic>.md`, from the template at
  `${CLAUDE_PLUGIN_ROOT}/templates/kb-module.md`. Under ~80 lines; split if it grows.
- The file holds the **current state**, not a log. Rewrite sections that are wrong;
  git keeps the history.
- `covers:` lists the directories and files the module describes. `dp-kb-stale` uses it,
  so keep it accurate and narrow.
- Set `verified_at:` to `git rev-parse --short HEAD` at the moment you checked the notes
  against the code, and `updated:` to today's date.
- Every module has exactly one row in `INDEX.md`: topic, file link, 3–6 keywords someone
  would search for, and the verified date. Keep each row on one line; the index is loaded
  into every session, so it must stay short.
