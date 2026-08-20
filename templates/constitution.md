---
title: Project constitution
version: 1
updated: YYYY-MM-DD
---

# Constitution

The highest-priority rules of this project. **Both agents read this file** — the lead
(Claude Code) and the executor (opencode). When any instruction conflicts with this
file, this file wins. Only the lead edits it, and only with the user's agreement.

Keep it short. A constitution nobody can hold in their head is not enforced.

## Quality gates

Every task is done only when all of these exit 0:

```bash
# lint
<lint command>

# typecheck
<typecheck command>

# test
<test command>

# build
<build command>
```

Never mark work complete with a failing gate. Never disable, skip, or `--force` a gate
to make it pass — if a gate is wrong, that is a separate task for the lead.

## Principles

1. **Reuse before writing.** Search the codebase for an existing utility first.
2. **Smallest change that satisfies the acceptance criteria.** No opportunistic refactors.
3. **Tests come with the code**, in the same task, not "later".
4. **Match the surrounding style** — naming, comment density, error handling, idiom.
5. **No new dependency without an explicit decision** recorded by the lead.
6. **Fail loudly.** No silent `catch {}`, no swallowed errors, no fabricated fallbacks.
7. **Public behaviour changes need a doc change** in the same feature.

## Hard prohibitions

- Never commit secrets, tokens, or `.env` contents.
- Never edit generated files, lockfiles, or migrations by hand unless the task says to.
- Never rewrite git history (`commit --amend`, `rebase`, `reset --hard`, force push).
- Never widen a task's scope to work around a blocker — report `blocked` instead.
- Never delete tests to make a suite pass.

## Stack

- Language / runtime: …
- Framework: …
- Package manager: …
- Test runner: …

Details in `docs/stack.md`. Architecture in `docs/architecture.md`.

## Code conventions

- Files: …
- Naming: …
- Error handling: …
- Logging: …

## Roles

The split of responsibility between the lead and the executor is defined in `CLAUDE.md`
(lead) and `AGENTS.md` (executor) and enforced by permissions in `opencode.json` and
`.claude/settings.json`. Neither agent may reinterpret its own boundaries.
