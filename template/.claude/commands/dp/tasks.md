---
description: Decompose the plan into self-contained task cards for the executor
argument-hint: [feature slug]
---

You are the tech lead. Decompose feature **$ARGUMENTS** into task cards
(if empty, use the most recently modified folder under `docs/specs/`).

Prerequisite: `plan.md` exists and its contracts are written. If not, stop and say so.

## Do this

1. Break the plan into tasks where **each task is one card that a weak free model can
   finish without asking anything**.
2. For each task write `tasks/T-XXX.md` from `docs/.templates/task-card.md`.
3. Write the index `tasks.md`: the board, the execution waves, and the AC coverage table.

## The rules that make a card work

Cards are executed by free models with short attention and no repository context.
Every one of these is a hard requirement:

- **<= 3 files and <= ~200 changed lines.** If a task is bigger, split it.
- **Self-contained Context.** Paste the actual signatures, types, constants, error
  messages, and a style example directly into the card. Never write "see plan.md",
  "look at the existing implementation", or "follow the pattern in the codebase".
- **`allowed_paths` lists exact files.** No globs. Include files the task will create.
- **Exactly one `verify` command**, and it must already run in this repo. Test it yourself.
- **Explicit "Out of scope — do NOT".** Silence gets filled with invention.
- **Acceptance criteria by ID** (`AC-1`), copied from `spec.md`, so review is mechanical.
- **`depends_on`** lists only real dependencies — over-serialising wastes wall-clock time.
- Assign `agent:` — `implementer` for code, `test-writer` for test-only tasks.

## Then check yourself

Walk `checklist.md` in the feature folder. Specifically verify:

- every acceptance criterion in `spec.md` is claimed by at least one task,
- no card references another document for context it needs,
- the dependency graph has no cycles,
- every `verify` command exists.

Report the board to the user and tell them which tasks are ready to delegate.
