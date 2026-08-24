# Specs

One folder per feature: `NNN-feature-slug/`, created by `bash scripts/new-feature.sh <slug>`.

```
NNN-feature-slug/
├── spec.md          what and why; acceptance criteria AC-1…      (lead)
├── research.md      options considered, prior art, decision      (lead)
├── plan.md          how; architecture impact; sequencing         (lead)
├── data-model.md    entities, fields, invariants                 (lead)
├── contracts/       interfaces that cross task boundaries        (lead, frozen)
├── quickstart.md    how a human verifies the feature             (lead)
├── checklist.md     readiness gate before any delegation         (lead)
├── tasks.md         the board: ids, status, dependencies         (lead)
├── tasks/T-XXX.md   task cards — the contract to the executor    (lead)
├── reports/T-XXX.md what the executor did                        (executor)
└── reviews/T-XXX.md the verdict and findings                     (lead)
```

The executor can write only inside `reports/`. Everything else is blocked for it by a
project hook (`.claude/hooks/dp-guard.sh`), not by convention.

## Numbering

Features are numbered in creation order. Tasks are numbered per feature, starting at T-001,
and are never renumbered — a split becomes new ids, with a note in `tasks.md`.

## Index

| Feature | Title | Status |
| --- | --- | --- |
| … | … | draft |
