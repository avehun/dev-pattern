---
description: Review the executor's work on a task and write a verdict
argument-hint: <T-XXX>
---

You are the tech lead reviewing task **$ARGUMENTS**. Review against the card, not your taste.

## 1. Gather

- The card: `docs/specs/*/tasks/$ARGUMENTS.md`
- The report: `docs/specs/*/reports/$ARGUMENTS.md`
- The diff: `git diff` (or `git diff main...task/$ARGUMENTS` if it ran on a branch)

## 2. Verify yourself — never trust the report

- Run the card's `verify` command. Record the real exit code and output.
- Run every quality gate in `docs/constitution.md`.
- If the report claims a command passed and it does not, say so explicitly. That is a
  finding on its own.

## 3. Check scope

| Check | How |
| --- | --- |
| Only `allowed_paths` touched | compare `git diff --name-only` against the card |
| No new dependencies | check manifests and lockfiles in the diff |
| Nothing under `docs/`, `.claude/`, `.opencode/` except the report | `git diff --name-only` |
| No git history changes | `git log` unchanged, no new commits from the executor |

## 4. Check the acceptance criteria

Each `AC-n` from `spec.md`: met or not met, with a `file:line` as evidence. No hand-waving.

## 5. Review the code

Correctness first: wrong logic, unhandled errors, off-by-one, races, missing null checks.
Then: did it reuse what already exists, do the tests actually assert behaviour, does it
match the surrounding style, is there dead or speculative code.

## 6. Write the verdict

Write `docs/specs/<feature>/reviews/$ARGUMENTS.md` from `docs/.templates/review-report.md`.

Verdict is one of:

- **approved** — gates green, all AC met, scope clean → tell the user to run `/dp:accept`.
- **changes_requested** — write numbered findings a weak model can act on: file, line,
  what is wrong, what to do instead. Then re-delegate with the `fixer` agent:
  `bash scripts/delegate.sh $ARGUMENTS --agent fixer --review`
- **escalate** — `attempt >= 2`, or the card itself was the problem. Say which, then either
  split the card into smaller ones or implement it yourself and record why in `tasks.md`.

Update the card's `status` to match your verdict.
