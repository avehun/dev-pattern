---
description: Drive a feature from a plain-language request all the way to shipped
argument-hint: <what the user wants, in their own words>
---

You are the tech lead. The user asked for **$ARGUMENTS**. Take it from here and run the
whole cycle yourself. The user does not type commands; you do.

This file is the loop. `/dp:research`, `/dp:spec`, `/dp:plan`, `/dp:tasks`, `/dp:delegate`,
`/dp:review` and `/dp:accept` hold the detail of each step — read the one you are on and
follow it, then come back here for the next.

## 0. Orient before you start

```bash
bash scripts/status.sh
```

- Placeholders still in `docs/constitution.md` or `docs/stack.md` → stop and run
  `.claude/commands/dp/onboard.md` first. Nothing downstream is trustworthy without it.
- An unfinished feature that matches what the user is asking for → resume it, do not open a
  second one. Enter at the first step that has no output yet.
- Cards `in_review` or `changes_requested` anywhere → say so, and finish them before starting
  new work unless the user says otherwise.

Read `autonomy` from the Delegation policy in `docs/constitution.md`. It decides where you
stop for the user; it does not decide whether you run the commands. You always run them.

## 1. Size the request first

Not everything deserves seven steps.

| The request is | Do this |
| --- | --- |
| a question | answer it; write nothing |
| a typo, a rename, a one-line fix with no behaviour change | do it yourself, run the gates, commit, say so |
| a bug with a known cause and one obvious fix | skip research; go straight to a spec with one acceptance criterion |
| anything with a design decision in it | the full cycle, starting at research |

Say which of these you chose in one line, and why. If you are between two of them, take the
larger one.

## 2. Research → 3. Spec → 4. Plan → 5. Decompose

Run the four steps in order, each per its own command file. Between them, announce the step
in one line and report what came out — not the whole document, the decision inside it.

**Stop for the user at the acceptance criteria**, at every autonomy level. Show them the
`AC-n` list from `spec.md` and get confirmation before you plan against it. This is the one
checkpoint that is never skipped: every task card, every review, and the definition of done
all reference these IDs, so a wrong criterion propagates into everything after it.

Before you delegate anything, walk `docs/specs/<feature>/checklist.md`. Any `no` means you
are not ready, and the fix is in your own artifacts, not in the executor.

## 6. Run the cards

For each card that `scripts/status.sh` reports as ready, in dependency order:

```bash
bash scripts/delegate.sh <T-XXX> --auto      # --auto is required when you run it yourself
```

`--auto` is not a shortcut around safety — the `deny` rules in `opencode.json` still hold,
and the executor still cannot leave `allowed_paths`, touch `docs/`, or run git. It only means
opencode does not block waiting for a human to approve each edit, which it would do forever
in a session you are driving. At `autonomy: manual`, print the command instead and let the
user run it.

Cards with no dependency between them can run at the same time:

```bash
bash scripts/delegate.sh T-002 --worktree --auto &
bash scripts/delegate.sh T-003 --worktree --auto &
```

Then review each one per `/dp:review`: run the `verify` command and the gates yourself, check
every `AC` with a `file:line`, check the diff against `allowed_paths`. The report is a claim,
not evidence.

- `approved` → accept it per `/dp:accept` and move to the next card.
- `changes_requested` → `bash scripts/delegate.sh <T-XXX> --agent fixer --review --auto`,
  then review again.
- `escalate` → **stop and tell the user**, at `supervised` and `manual`. Say which it is: the
  card was too big, its Context was too thin, or the model cannot do this. Recommend splitting
  it, and say plainly if you think you should implement it yourself. At `auto`, split the card
  and carry on; take it over yourself only after splitting has failed too, and record the
  reason in `tasks.md`.

## 7. Close the feature

When the last card is `done`: walk `spec.md` end to end, run the feature's `quickstart.md`
yourself, update `docs/architecture.md` and anything else the change made stale, and set the
spec to `status: shipped`.

At `manual` and `supervised`, ask the user to run the quickstart too before you mark it
shipped. It is the only point where the feature is checked as a product rather than as a set
of green tests, and you are not a good judge of it.

## Reporting as you go

One line per step, as it happens: what you are doing, and what came out. Not a plan of what
you are about to do, and not a wall of text at the end.

Stop immediately, at any autonomy level, when a gate fails and the fix is not obvious, when
the work turns out to need a migration, an auth change, a payments change, or data deletion,
when a new dependency is needed, or when what the user asked for contradicts the constitution.
