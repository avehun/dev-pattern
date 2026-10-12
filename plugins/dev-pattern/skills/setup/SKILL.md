---
name: setup
description: Set dev-pattern up in the current repository (knowledge base, plan mode by default, Opus as the main model).
disable-model-invocation: true
---

# Set up dev-pattern in this repository

1. Check this is a git repository (`git rev-parse --show-toplevel`). If not, say that
   dev-pattern needs git and stop.
2. Ask the user which mode they want (one question, with AskUserQuestion when available):
   - **shared** — settings in `.claude/settings.json`, `docs/dp/` committed; teammates get
     the same workflow.
   - **local** — settings in `.claude/settings.local.json`, `docs/dp/` hidden through
     `.git/info/exclude`; nothing reaches the repository.
3. Run `dp-setup --mode <mode> --dry-run` and show the user its output.
4. If it reports a key marked `!` (an existing value differs), ask whether to override those
   keys. Then run `dp-setup --mode <mode>`, adding `--force` only if the user agreed.
5. Report what changed, and tell the user to start a new session so the hooks load.
   Mention `/dev-pattern:uninstall` undoes it exactly.
