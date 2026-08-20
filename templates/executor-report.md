---
task: T-001
feature: 001-feature-slug
agent: implementer
model: opencode/big-pickle
attempt: 1
outcome: done          # done | blocked | partial
date: YYYY-MM-DD
---

# Report — T-001

## What I changed

| File | Action | Summary |
| --- | --- | --- |
| `src/example/file.ts` | modified | added `refresh()` |
| `src/example/file.test.ts` | created | 4 unit tests |

No other files were touched.

## Verify command

```bash
$ npm test -- src/example
```

```
<paste the last ~20 lines of real output, including the exit status>
```

Exit code: `0`

## Acceptance criteria

- [x] **AC-1** — met, see `src/example/file.ts:57`
- [x] **AC-2** — met, covered by test `refreshes an expired token`

## Decisions I had to make

<!-- Anything the card did not specify and you chose yourself. If this list is long,
     the card was underspecified — say so, the lead needs to know. -->

- …

## Problems

<!-- Anything that failed, was confusing, or is still wrong. Be honest —
     a hidden problem becomes a rejected review. -->

- none

## Blocked on (only if outcome: blocked)

- **What I need:** …
- **Why I cannot do it inside `allowed_paths`:** …
