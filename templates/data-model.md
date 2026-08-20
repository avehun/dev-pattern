---
feature: 001-feature-slug
title: Data model
plan: ./plan.md
created: YYYY-MM-DD
---

# Data model — {{TITLE}}

## Entities

### {{Entity}}

| Field | Type | Required | Default | Notes |
| --- | --- | --- | --- | --- |
| `id` | `uuid` | yes | — | primary key |
| … | … | … | … | … |

**Invariants**
- …

**Lifecycle**
- created when …, deleted when …

## Relationships

```
User 1 ──── * Session
```

## Persistence

- Storage: …
- Indexes: …
- Migration: `…` (owned by the lead — executors never write migrations unsupervised)

## Validation rules

| Rule | Enforced where | Error |
| --- | --- | --- |
| … | … | … |
