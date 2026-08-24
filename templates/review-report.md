---
task: T-001
feature: 001-feature-slug
reviewer: lead
attempt: 1
verdict: changes_requested   # approved | changes_requested | escalate
date: YYYY-MM-DD
---

# Review — T-001

## Verdict

**{{approved | changes_requested | escalate}}** — one-sentence reason.

## Verification run

```bash
$ npm test -- src/example
```

```
<paste the actual output tail>
```

- Verify command exit code: `0` / `1`
- Quality gates (`docs/constitution.md`): pass / fail

## Acceptance criteria

| AC | Status | Evidence |
| --- | --- | --- |
| AC-1 | met / not met | `src/…:42` |
| AC-2 | met / not met | test `…` |

## Scope compliance

| Check | Result |
| --- | --- |
| Only `allowed_paths` touched | yes / no — list strays |
| No new dependencies | yes / no |
| No edits under `docs/`, `.claude/` | yes / no |
| No git history changes | yes / no |

## Findings

> Numbered, specific, and each one fixable inside `allowed_paths`.
> The fixer agent gets this list verbatim, so write it for a weak model:
> file, line, what is wrong, what to do instead.

1. **`src/example/file.ts:57`** — … → change to …
2. **`src/example/file.test.ts`** — missing a case for … → add a test that …

## Rework instructions

If `changes_requested`: fix **only** the findings above. Do not refactor anything else.
Re-run `npm test -- src/example`. Append to the existing report, do not rewrite it.

## Escalation

If `escalate`: attempt count reached the limit. Reason:
<!-- card was too big / context was insufficient / model cannot handle this / contract was wrong -->
Lead action: <!-- split into T-00x + T-00y | rewrite Context | implement directly -->
