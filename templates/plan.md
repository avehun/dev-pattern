---
feature: 001-feature-slug
title: Implementation plan
status: draft          # draft | ready
spec: ./spec.md
created: YYYY-MM-DD
---

# Plan — {{TITLE}}

> **How.** Requires `spec.md` at `status: ready`.

## Approach

<!-- 1–3 paragraphs. The chosen design in prose, and why it beats the alternatives
     recorded in research.md. Link the ADR if this decision is architectural. -->

## Architecture impact

- **New modules:** …
- **Modified modules:** …
- **Deleted / deprecated:** …
- **ADR needed?** yes → `docs/adr/NNNN-….md` / no

## Component map

| Component | Responsibility | Files |
| --- | --- | --- |
| … | … | `src/…` |

## Data and contracts

- Entities and invariants: see `./data-model.md`
- Interfaces between tasks: see `./contracts/`

Contracts are frozen before decomposition. If a task needs a contract change,
it comes back to the lead — the executor never redesigns an interface.

## Sequencing

```
T-001 ──► T-003 ──► T-005
T-002 ──┘          │
T-004 ─────────────┘
```

## Test strategy

| Level | What it covers | Where |
| --- | --- | --- |
| Unit | … | `…` |
| Integration | … | `…` |
| E2E / manual | … | `./quickstart.md` |

Quality gates for every task in this feature (must match `docs/constitution.md`):

```bash
# lint
# typecheck
# test
```

## Risks

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| … | low/med/high | low/med/high | … |

## Rollout

- Migration steps: …
- Feature flag: …
- Rollback: …
