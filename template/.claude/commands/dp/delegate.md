---
description: Hand a task card to opencode and report what came back
argument-hint: <T-XXX> [--run] [--worktree] [--model provider/model]
---

You are the tech lead. Delegate task **$ARGUMENTS** to the executor.

## First, validate the card

Read the card and confirm — do not delegate if any of these fail:

- `status` is `todo` or `changes_requested`
- every id in `depends_on` has `status: done`
- `allowed_paths` names real, specific files
- the `verify` command exists and runs in this repo
- the Context section is self-contained: no "see plan.md", no "explore the codebase"
- `attempt` is below `max-attempts` from the constitution — at the limit, escalate instead

If the card fails validation, fix the card first. A bad card wastes a full round trip.

## Then hand it off

Read `autonomy` from the Delegation policy in `docs/constitution.md`.

**At `supervised` and `auto` — run it yourself:**

```bash
bash scripts/delegate.sh <T-XXX> --auto [--worktree] [--model …]
```

`--auto` is required here, not optional. Without it `opencode run` blocks waiting for a human
to approve each edit, and in a session you are driving nobody is there to answer — the run
hangs until it is killed. `--auto` does not widen what the executor may do: the `deny` rules
in `opencode.json` still hold, `allowed_paths` still bounds it, and git is still closed to it.

**At `manual` — print it and stop:**

```bash
bash scripts/delegate.sh <T-XXX> --dry-run
```

Show the user the resulting command and a one-line summary of what the task will do, so they
can watch every edit opencode proposes. `--run` in the arguments overrides this for one task.

## After it returns

Report: which files changed (`git diff --stat`), whether the report was written, and the
report's `outcome`. At `manual`, tell the user to run `/dp:review <T-XXX>`. At `supervised` and
`auto`, go straight on to the review yourself.

Do not review the code in this step, and do not fix the executor's work yourself.
