---
description: Load and execute a task card by id, e.g. /task T-003
agent: implementer
---

Execute task card `$ARGUMENTS`.

The card is at `docs/specs/*/tasks/$ARGUMENTS.md`. Find it with:

!`find docs/specs -name "$ARGUMENTS.md" -path "*/tasks/*"`

Read that file completely before doing anything, then follow the loop in `AGENTS.md`:
stay inside `allowed_paths`, run the card's `verify` command until it exits 0, write the
report to the feature's `reports/$ARGUMENTS.md`, and stop.
