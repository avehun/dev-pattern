---
id: T-001
feature: 001-feature-slug
title: Short imperative title
status: todo            # todo | in_progress | in_review | changes_requested | done | blocked | escalated
depends_on: []          # e.g. [T-001, T-002] — all must be `done` before delegation
attempt: 0              # incremented by prepare-delegation.sh; at max-attempts (constitution) it escalates
agent: dp-implementer   # dp-implementer | dp-test-writer | dp-fixer
model: sonnet
allowed_paths:          # the ONLY files the executor may create or modify
  - src/example/file.ts
  - src/example/file.test.ts
verify: "npm test -- src/example"   # exactly one command; must exit 0 when the task is done
knowledge_refs:          # optional — docs/knowledge/modules/*.md the executor should read first
  - docs/knowledge/modules/example.md
---

<!--
  AUTHORING RULES (lead only — delete this comment in real cards if you want):
  - A card is a CONTRACT. It must be self-contained: the executor never explores beyond
    what the card, its knowledge_refs, and its file:line pointers give it.
  - Target: <= 3 files, <= ~200 changed lines. If bigger, split into more cards.
  - The executor is a real Claude Code agent with Read/Grep/Glob in this repo — point it at
    file:line instead of pasting content it can read itself. Inline only what it cannot
    discover by reading: a decision, an external constraint, expected behaviour not visible
    in the code. Pasting something it could read is wasted tokens, not extra safety.
  - Exactly one verify command. If you cannot name one, the task is not ready.
  - See docs/task-cards.md in the dev-pattern repo for the full checklist.
-->

## Goal

<!-- One or two sentences. What will exist after this task that does not exist now? -->

## Context

<!--
  Point precisely at what the executor needs: file:line + one line on why it matters.
  Reference docs/knowledge/modules/*.md via knowledge_refs above instead of re-explaining
  something already documented there. Inline only what reading the file would not reveal.
-->

- `src/example/file.ts:12` — existing `Example` class the new method extends
- see `docs/knowledge/modules/example.md` for the module's overall contract, if it exists

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
- Do not edit anything under `docs/`, `.claude/`, `CLAUDE.md` — blocked by a project hook.
- Do not run `git commit`, `git push`, or any branch operation — blocked the same way.
- Do not "improve" unrelated code you happen to read.
- Do not explore the repository beyond this card's pointers and `knowledge_refs`.

## When you are done

Write your report to `docs/specs/001-feature-slug/reports/T-001.md` using the structure in
your subagent's own instructions, then stop. Do not start another task.

## If you get stuck

If a step is ambiguous or the verify command cannot pass for a reason outside `allowed_paths`:
stop, write the report with `outcome: blocked`, and state exactly what is missing.
Never guess, never widen the scope to work around it.
