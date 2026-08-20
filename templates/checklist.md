---
feature: 001-feature-slug
title: Readiness checklist
created: YYYY-MM-DD
---

# Readiness checklist — {{TITLE}}

The lead runs this before delegating anything. A `no` anywhere means the spec is not
ready and the executor would be set up to fail.

## Spec is ready

- [ ] The problem is stated without naming a solution.
- [ ] Every acceptance criterion is observable and testable.
- [ ] Non-goals and out-of-scope are written down.
- [ ] No open question can still change an acceptance criterion.
- [ ] The user has read and confirmed the spec.

## Plan is ready

- [ ] Every reusable thing already in the repo has been found and named (`research.md`).
- [ ] Every new or modified file is listed.
- [ ] Contracts between tasks are written and frozen.
- [ ] The test strategy names actual commands that exist in this project.
- [ ] Risks have mitigations, not just descriptions.

## Decomposition is ready

- [ ] Every acceptance criterion is covered by at least one task.
- [ ] Every task touches <= 3 files and is <= ~200 changed lines.
- [ ] Every task card is self-contained — no card says "see plan.md".
- [ ] Every task card has exactly one `verify` command, and that command exists.
- [ ] Every `allowed_paths` entry is a real path (or a file the task will create).
- [ ] The dependency graph has no cycles and no orphan tasks.
- [ ] Cards that need a weak free model have been written for a weak free model
      (inline context, explicit steps, no exploration).

## Environment is ready

- [ ] `bash scripts/doctor.sh` passes.
- [ ] The repo is on a clean working tree.
- [ ] Quality gates in `docs/constitution.md` run green on `main` right now.
