---
feature: 001-feature-slug
title: Task index
plan: ./plan.md
created: YYYY-MM-DD
---

# Tasks — {{TITLE}}

Cards live in `./tasks/T-XXX.md`. Executor reports land in `./reports/T-XXX.md`.
Review verdicts land in `./reviews/T-XXX.md`. This file is the index; the card is
the source of truth for a task's `status`.

## Board

| ID | Title | Agent | Depends on | Status |
| --- | --- | --- | --- | --- |
| [T-001](./tasks/T-001.md) | … | implementer | — | todo |
| [T-002](./tasks/T-002.md) | … | implementer | — | todo |
| [T-003](./tasks/T-003.md) | … | test-writer | T-001 | todo |

## Order of execution

Tasks with no unmet `depends_on` may run in any order, one at a time (or in parallel —
delegate each with `isolation: "worktree"` and issue their Agent tool calls together).

1. **Wave 1 (parallel):** T-001, T-002
2. **Wave 2:** T-003
3. **Wave 3:** T-004

## Coverage check

Every acceptance criterion in `spec.md` must be claimed by at least one task.

| AC | Covered by |
| --- | --- |
| AC-1 | T-001, T-003 |
| AC-2 | T-002 |

## Notes

- Escalations, splits, and abandoned cards are recorded here with a one-line reason.
