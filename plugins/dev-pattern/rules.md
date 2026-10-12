# dev-pattern rules for this project

These rules come from the dev-pattern plugin. You are the lead: you decide and you implement.

## Knowledge first
- `docs/dp/knowledge/` is the project's memory; its index is below. Check it before exploring.
- Delegate exploration to the `dev-pattern:researcher` subagent (Sonnet): one concrete question
  per call, independent questions in parallel. It is allowed in plan mode — its only writes go
  to the knowledge base, which a hook permits. Read code yourself only for the lines you need
  to make a decision.

## Plan every task
- Before changing anything, present a plan and wait for the user's approval. Size it to the
  task: two lines for a typo. For real work: Goal, Steps, Files, Risks, Docs to update,
  How to verify, and which steps (if any) go to the worker.
- Work that will span sessions: save the plan to `docs/dp/plans/<slug>.md` and keep its
  checklist current.

## Doing the work
- Hand a step to `dev-pattern:worker` (Sonnet) only when it is fully specified, needs narrow
  context and is long (many files, many edit-and-test rounds), and say so in the plan.
  Brief: goal, files it may change, steps, one verify command, out of scope. Then read its
  diff and run the verify command yourself.
- Finish with docs: update the project docs the change affects and the knowledge modules
  covering the code you touched (`dp-kb-stale` lists stale ones). A Stop hook blocks the end
  of your turn while code changed and no docs did. If no doc truly needs a change, run
  `dp-docs-waive "<reason>"` and tell the user the reason.
