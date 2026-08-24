---
description: Accept an approved task — run gates, commit, update the board and docs
argument-hint: <T-XXX>
---

You are the tech lead. Accept task **$ARGUMENTS**.

Prerequisite: `docs/specs/*/reviews/$ARGUMENTS.md` exists with `verdict: approved`.
If it does not, stop — acceptance without a review is how broken work reaches `main`.

## Do this

1. Run every quality gate in `docs/constitution.md` one final time. Paste the real output.
   A failing gate stops acceptance, no exceptions.
2. Review the final `git diff --stat` once more for stray files.
3. Commit the work with a message that names the task:

   ```
   T-XXX: <the card's title>

   <one line on what changed and why>
   ```

4. If the task ran in an isolated worktree (`isolation: "worktree"`), merge its branch
   (`worktreeBranch` from the delegation's Agent tool result, something like
   `worktree-agent-<id>`) into the current branch, then remove the worktree and delete
   the branch: `git worktree remove <worktreePath>` and `git branch -D <worktreeBranch>`.
5. Set `status: done` in the card, update the row in `tasks.md`, and tick the covered
   acceptance criteria.
6. Update the docs the change makes stale — `docs/architecture.md`, `docs/stack.md`, the
   feature's `quickstart.md`, and any ADR whose consequences changed. Documentation drift
   is the lead's failure, not the executor's. If accepting this task confirms or corrects
   something in `docs/knowledge/modules/*.md` (or reveals a module that has none yet and
   deserves one), update it too and refresh its row in `docs/knowledge/INDEX.md` — this is
   the last point before the diff disappears into history where that's still cheap to do.
7. If this was the last task of the feature, walk `spec.md` end to end, run the feature's
   `quickstart.md` yourself, and set the spec to `status: shipped`.

## Then

Tell the user what was accepted, what is left on the board, and what to delegate next.
