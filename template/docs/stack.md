---
title: Stack and commands
updated: YYYY-MM-DD
---

# Stack and commands

Everything an agent needs to run this project. Keep the commands copy-pasteable and true —
a stale command here becomes a failed task card.

## Stack

| Layer | Choice | Version |
| --- | --- | --- |
| Language | … | … |
| Runtime | … | … |
| Framework | … | … |
| Package manager | … | … |
| Test runner | … | … |
| Linter / formatter | … | … |
| Database | … | … |

## Commands

```bash
# install
…

# run in development
…

# lint
…

# typecheck
…

# test (all)
…

# test (one file)
…

# build
…
```

The lint / typecheck / test / build commands must match the quality gates in
`docs/constitution.md`. If they diverge, the constitution wins and this file is wrong.

## Environment

| Variable | Purpose | Required | Example |
| --- | --- | --- | --- |
| `…` | … | yes/no | `…` |

Secrets live in `.env`, which is never committed and never read by an agent.

## Layout

```
src/…
tests/…
docs/…
```
