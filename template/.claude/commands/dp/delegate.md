---
description: Hand a task card to a dp-implementer/dp-fixer/dp-test-writer subagent and report what came back
argument-hint: <T-XXX> [--agent dp-fixer]
---

You are the tech lead. Delegate task **$ARGUMENTS** to the executor.

## 1. Validate and prepare

```bash
bash scripts/prepare-delegation.sh <T-XXX> [--agent dp-fixer]
```

This checks the card (status, `depends_on` all `done`, `allowed_paths` and `verify` present,
`attempt` below `max-attempts`, no "see plan.md"-style hand-waving), and — only if everything
passes — bumps `attempt`, sets `status: in_progress`, **commits any pending changes outside
`.claude/`** (the card's own status/attempt bump, and anything else of yours not yet
committed — the executor's worktree is a real `git worktree` and only ever sees committed
state), and writes `.claude/dp-active-task.json`, the pointer the permission hook reads to
know this task's `allowed_paths`.

Exit 1 → fix what it names and stop. Nothing was changed.

## 2. Call the Agent tool yourself

Bash cannot do this part. Use the agent from step 1's output (`dp-implementer` for a normal
task, `dp-fixer` when reworking a `changes_requested` card — attach the review too):

```
Agent({
  subagent_type: "dp-implementer",          # or dp-fixer, or dp-test-writer per the card
  isolation: "worktree",
  prompt: "Implement task T-XXX. The task card is docs/specs/<feature>/tasks/T-XXX.md.
           Read all of it before you touch anything, then follow it exactly."
})
```

For `dp-fixer`, mention the review file too: "...and the review with the findings is
`docs/specs/<feature>/reviews/T-XXX.md` (also read it)."

Independent, ready cards → call the Agent tool **multiple times in the same message**; they
run in parallel. Run `scripts/prepare-delegation.sh` for each one first — every card needs
its own commit and its own `dp-active-task.json`, so delegate them one at a time through
step 1, and only batch the step-2 Agent calls together once all of them are ready.

`docs/`, `.claude/`, `CLAUDE.md`, dependency manifests, and anything outside the card's
`allowed_paths` are blocked for the subagent by a project hook
(`.claude/hooks/dp-guard.sh`) — this is enforced independently of what the card says, not a
convention the executor could talk itself out of.

## 3. Don't trust the result — look yourself

The tool result names the worktree: `worktreePath` and `worktreeBranch`. Use them directly.

```bash
git -C <worktreePath> diff --stat
git -C <worktreePath> status --short
```

Compare the changed files against the card's `allowed_paths` yourself. Read the subagent's
own summary as a claim, not a fact — the same principle as reading its report during review.

## 4. Record the handoff

```bash
bash scripts/set-status.sh <T-XXX> in_review
```

Then tell the user (if anyone's watching): what changed, whether a report was written, and
what its `outcome` field says. Go straight on to `/dp:review <T-XXX>` — do not review the
code in this step, and do not fix the executor's work yourself here.
