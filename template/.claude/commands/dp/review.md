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
| Only `allowed_paths` touched | compare `git diff --name-only` (in the executor's worktree) against the card |
| No new dependencies | check manifests and lockfiles in the diff |
| Nothing under `docs/`, `.claude/` except the report | `git diff --name-only` — the project hook (`.claude/hooks/dp-guard.sh`) should already have blocked any attempt, but check the diff anyway |
| No git history changes | `git log` unchanged, no new commits from the executor — it cannot run git at all |

## 4. Check the acceptance criteria

Each `AC-n` from `spec.md`: met or not met, with a `file:line` as evidence. No hand-waving.

## 5. Review the code

Correctness first: wrong logic, unhandled errors, off-by-one, races, missing null checks.
Then: did it reuse what already exists, do the tests actually assert behaviour, does it
match the surrounding style, is there dead or speculative code.

## 6. Promote what's durable

Did this task surface a fact about a module that is true regardless of this feature — a
gotcha, a reusable helper, a wrong assumption in an existing `docs/knowledge/modules/*.md`?
Append it there (or create the file from `docs/.templates/knowledge-module.md` if the module
has none yet) and update `docs/knowledge/INDEX.md`. This is separate from, and in addition
to, the feature-scoped review file below — durable findings belong in the knowledge base so
the next task on this module does not rediscover them.

## 7. Write the verdict

Write `docs/specs/<feature>/reviews/$ARGUMENTS.md` from `docs/.templates/review-report.md`.

Verdict is one of:

- **approved** — gates green, all AC met, scope clean → tell the user to run `/dp:accept`.
- **changes_requested** — write numbered findings the executor can act on precisely: file,
  line, what is wrong, what to do instead. Then re-delegate to the fixer:
  `bash scripts/prepare-delegation.sh $ARGUMENTS --agent dp-fixer`, then call the Agent tool
  yourself with `subagent_type: "dp-fixer"`, `isolation: "worktree"`, and both the card and
  this review file in the prompt — per `/dp:delegate.md`.
- **escalate** — `attempt` reached `max-attempts`, or the card itself was the problem. Say
  which, then either split the card into smaller ones or implement it yourself and record
  why in `tasks.md`.

Update the card's `status` to match your verdict.
