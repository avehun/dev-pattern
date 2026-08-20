---
id: T-001
feature: 001-feature-slug
title: Short imperative title
status: todo            # todo | in_progress | in_review | changes_requested | done | blocked | escalated
depends_on: []          # e.g. [T-001, T-002] — all must be `done` before delegation
attempt: 0              # incremented by scripts/delegate.sh; attempt >= 2 triggers escalation
agent: implementer      # implementer | test-writer | fixer
model: opencode/big-pickle
allowed_paths:          # the ONLY files the executor may create or modify
  - src/example/file.ts
  - src/example/file.test.ts
verify: "npm test -- src/example"   # exactly one command; must exit 0 when the task is done
---

<!--
  AUTHORING RULES (lead only — delete this comment in real cards if you want):
  - A card is a CONTRACT. It must be self-contained: never point the executor at another document for context.
  - Target: <= 3 files, <= ~200 changed lines. If bigger, split into more cards.
  - Paste every signature, type, and example the executor needs directly into Context.
  - Exactly one verify command. If you cannot name one, the task is not ready.
  - See docs/task-cards.md in the dev-pattern repo for the full checklist.
-->

## Goal

<!-- One or two sentences. What will exist after this task that does not exist now? -->

## Context

<!--
  Everything the executor needs, INLINE. No exploration allowed.
  Include: existing signatures it must call, types it must satisfy, an example of the
  surrounding code style, relevant constants, and the exact error/behaviour today.
-->

```ts
// existing code the task builds on — paste it, do not reference it
```

## Files you may touch

| File | Action | Notes |
| --- | --- | --- |
| `src/example/file.ts` | modify | add the new method only |
| `src/example/file.test.ts` | create | unit tests for the new method |

Touching anything outside this table is a failed task.

## Step-by-step

1. …
2. …
3. …

## Acceptance criteria

- [ ] **AC-1** (from `spec.md`): …
- [ ] **AC-2** (from `spec.md`): …
- [ ] All existing tests still pass.

## How to verify

```bash
npm test -- src/example
```

The command above must exit with code 0. Do not declare the task finished before it does.

## Out of scope — do NOT

- Do not add, upgrade, or remove dependencies.
- Do not refactor code outside `allowed_paths`.
- Do not edit anything under `docs/`, `.claude/`, `.opencode/`, `CLAUDE.md`, `AGENTS.md`.
- Do not run `git commit`, `git push`, or any branch operation.
- Do not "improve" unrelated code you happen to read.

## When you are done

Write your report to `docs/specs/001-feature-slug/reports/T-001.md` using the structure in
`AGENTS.md`, then stop. Do not start another task.

## If you get stuck

If a step is ambiguous or the verify command cannot pass for a reason outside `allowed_paths`:
stop, write the report with `outcome: blocked`, and state exactly what is missing.
Never guess, never widen the scope to work around it.
