---
title: Architecture
updated: YYYY-MM-DD
---

# Architecture

The lead owns this file and keeps it current at every `/dp:accept`. The executor reads it
but never edits it.

## System overview

<!-- One paragraph: what this system is and what it does. -->

```
<a diagram: boxes and arrows, or a mermaid block>
```

## Modules

| Module | Responsibility | Entry point | Depends on |
| --- | --- | --- | --- |
| … | … | `src/…` | … |

## Data flow

<!-- Trace one important request or job end to end, with file:line anchors. -->

1. …
2. …

## Boundaries

- What is allowed to depend on what, and what must never depend on what.
- Where the seams are — the places a feature can be added without touching everything.

## Cross-cutting concerns

| Concern | How it is handled | Where |
| --- | --- | --- |
| Configuration | … | `…` |
| Errors | … | `…` |
| Logging | … | `…` |
| Auth | … | `…` |
| Persistence | … | `…` |

## Decisions

Architectural decisions live in `docs/adr/`. This file describes the result;
the ADRs describe why.

| ADR | Decision | Status |
| --- | --- | --- |
| [ADR-0001](./adr/0001-example.md) | … | accepted |

## Known debt

| Debt | Impact | Where |
| --- | --- | --- |
| … | … | `…` |
