---
feature: 001-feature-slug
title: Research
status: draft          # draft | done
created: YYYY-MM-DD
---

# Research — {{TITLE}}

> Written by the lead **before** `plan.md`. The executor never researches;
> whatever it needs to know is copied into its task card.

## Question

<!-- What decision does this research unblock? -->

## What already exists in this codebase

| Thing | Where | Reusable? |
| --- | --- | --- |
| … | `src/…:12` | yes — call it directly |
| … | `src/…` | no — wrong abstraction, see below |

> Prefer reuse. A task that reimplements something already in the repo is a
> planning failure, not an executor failure.

## Options considered

### Option A — …

- **How it works:** …
- **Pros:** …
- **Cons:** …
- **Cost:** …

### Option B — …

…

## Decision

**Chosen: Option _** — because …

Rejected because: …

## External references

| Source | Why it matters | Checked |
| --- | --- | --- |
| <https://…> | … | YYYY-MM-DD |

## Consequences for the plan

- …
