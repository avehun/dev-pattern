---
name: uninstall
description: Remove dev-pattern from the current repository, undoing exactly what setup changed.
disable-model-invocation: true
---

# Remove dev-pattern from this repository

1. Ask the user whether to keep the knowledge base in `docs/dp/` (the default — it stays
   readable and dev-pattern's hooks are switched off) or delete it as well.
2. Run `dp-uninstall`, adding `--purge-kb` only if the user chose to delete it.
3. Show the output and `git status --short`, so the user sees the repository is back to how it was.
4. If they want the plugin gone from every project, tell them to run `/plugin` and uninstall it there.
