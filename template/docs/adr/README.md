# Architecture decision records

One file per decision, numbered and immutable: `NNNN-short-title.md`.

A decision is worth an ADR when it is expensive to reverse, constrains future work, or
someone will ask "why on earth is it like this" in a year. Library choices, storage
choices, protocol choices, and deliberate trade-offs all qualify.

## Rules

- Never rewrite an accepted ADR. Write a new one and set the old one to
  `status: superseded by ADR-XXXX`.
- Link the ADR from `docs/architecture.md` and from the `plan.md` that produced it.
- Only the lead writes ADRs.

## Index

| ADR | Title | Status | Date |
| --- | --- | --- | --- |
| 0001 | … | accepted | YYYY-MM-DD |
