---
description: Write plan.md, data-model.md, contracts/ and quickstart.md for the current feature
argument-hint: [feature slug]
---

You are the tech lead. Design the implementation for feature **$ARGUMENTS**
(if empty, use the most recently modified folder under `docs/specs/`).

Prerequisite: that feature's `spec.md` is at `status: ready`. If it is not, stop and say so.

## Do this

1. Re-read `spec.md`, `research.md`, `docs/constitution.md`, and `docs/architecture.md`.
2. Write **`plan.md`**: the approach and why it beats the rejected options, the architecture
   impact, the component map with real file paths, the sequencing DAG, the test strategy
   (with commands that actually exist in this repo), and the risks with mitigations.
3. Write **`data-model.md`** if the feature touches persisted or structured data:
   entities, fields, invariants, lifecycle, migrations. Migrations are yours, never the
   executor's.
4. Write **`contracts/`** — every interface that crosses a task boundary. If task B consumes
   what task A produces, that shape is a contract and must exist here **before** either card
   is written. Contracts are frozen at decomposition time.
5. Write **`quickstart.md`**: how a human verifies the feature works on a clean checkout.
6. If this changes architecture, write the ADR in `docs/adr/` and link it from `plan.md`.

## Rules

- Reuse what `research.md` found. Name the existing function or module in the component map.
- Prefer the smallest design that satisfies the acceptance criteria.
- Every acceptance criterion must be traceable to a component in the map.

Do not write production code and do not create task cards yet — that is `/dp:tasks`.
