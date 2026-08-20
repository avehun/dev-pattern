---
description: Hand a task card to opencode (prints the command; add --run to execute it)
argument-hint: <T-XXX> [--run] [--auto] [--worktree] [--model provider/model]
---

You are the tech lead. Delegate task **$ARGUMENTS** to the executor.

## First, validate the card

Read the card and confirm — do not delegate if any of these fail:

- `status` is `todo` or `changes_requested`
- every id in `depends_on` has `status: done`
- `allowed_paths` names real, specific files
- the `verify` command exists and runs in this repo
- the Context section is self-contained: no "see plan.md", no "explore the codebase"
- `attempt < 2` — at 2, escalate instead (split the card or implement it yourself)

If the card fails validation, fix the card first. A bad card wastes a full round trip.

## Then hand it off

Default is **semi-automatic**: print the exact command and let the user run it, so they
see every edit opencode proposes.

```bash
bash scripts/delegate.sh <T-XXX> --dry-run
```

Show the user the resulting command and a one-line summary of what the task will do.

**If the user passed `--run`**, execute the delegation yourself:

```bash
bash scripts/delegate.sh <T-XXX> [--auto] [--worktree] [--model …]
```

`--auto` lets opencode apply edits without asking. It is still bounded by the `deny` rules
in `opencode.json`, but the user should have chosen it deliberately — never add it yourself.

## After it returns

Report: which files changed (`git diff --stat`), whether the report was written, and the
report's `outcome`. Then tell the user to run `/dp:review <T-XXX>`.

Do not review the code in this step, and do not fix the executor's work yourself.
