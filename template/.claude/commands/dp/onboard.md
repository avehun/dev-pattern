---
description: Read the codebase, interview the user, and fill in the project's own documents
argument-hint: [--recheck]
---

You are the tech lead, and this project has just installed dev-pattern. The documents that
every later step depends on — the constitution, the stack, the architecture — are still
templates. Fill them in yourself. The user should not have to edit a single one by hand.

Everything you write here becomes the `verify` command in task cards and the gates in
review. A wrong value is not a cosmetic problem: it produces failed tasks for weeks.

**The rule that governs this whole command: never write a command you have not run, and
never write a fact you have not read.** If you could not verify it, ask or leave it out.

## 1. Take a snapshot of the repository

Read, do not guess:

| Look at | For |
| --- | --- |
| `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle*`, `Gemfile`, `composer.json`, `*.csproj` | language, framework, scripts |
| lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `poetry.lock`, `uv.lock`) | the package manager, unambiguously |
| `tsconfig.json`, `.eslintrc*`, `eslint.config.*`, `ruff.toml`, `.golangci.yml`, `.prettierrc*` | lint and typecheck configuration |
| `Makefile`, `justfile`, `Taskfile.yml` | the commands the team actually uses |
| `.github/workflows/`, `.gitlab-ci.yml`, `.circleci/` | **the most reliable source of gates** — what CI runs is what must pass |
| `docker-compose*`, `Dockerfile`, `.env.example` | services and required environment |
| `README`, `CONTRIBUTING` | conventions someone already wrote down |
| the top two levels of the source tree | layout, entry points, module boundaries |
| `git log --oneline -30` | commit message conventions |

If the repository is empty or nearly so, say so and run the interview alone — a greenfield
project has answers but no evidence.

## 2. Derive the quality gates, then prove them

From the snapshot, assemble candidates for lint, typecheck, test, and build.

**Run every candidate.** Record the real exit code.

- Exits 0 → it goes into `docs/constitution.md` verbatim.
- Fails → do not silently drop it and do not silently keep it. The repository being red is
  information the user needs. Bring it to the interview: keep it as a gate and fix the
  repository first, or leave it out for now.
- Does not exist (no typecheck in a JavaScript project without TypeScript) → leave the gate
  out. An invented gate is worse than a missing one.

## 3. Map the modules

Fill `docs/architecture.md` to the depth you can actually verify:

- the module table — module, responsibility, entry point, dependencies, with real paths,
- one important request or job traced end to end, with `file:line` anchors,
- the boundaries: what may depend on what,
- cross-cutting concerns you found in the code — configuration, errors, logging, auth,
  persistence — each with the file that implements it.

Whatever you did not open, list under `## Not yet mapped`. That section is honest and it is
useful: you will fill it in as features touch those areas. An invented module table is not.

For every module you traced deeply enough to be worth remembering, also write
`docs/knowledge/modules/<name>.md` (from `docs/.templates/knowledge-module.md`) with the
same file:line map at greater depth, and add its row to `docs/knowledge/INDEX.md`. This is
what lets the next research step skip re-deriving what you already worked out today — see
`docs/knowledge-base.md`. Link it from the architecture table's `Deep dive` column.

Fill `docs/glossary.md` from the domain type and entity names you saw — the words that
appear in both the code and the way the team talks about the product.

## 4. Interview the user

Use the question tool, in batches, up to four questions per call. Pre-fill every option with
what you found, so the user is confirming rather than composing.

**Do not ask what the repository already answered.** A question whose answer is in
`package.json` is a wasted turn and it costs you the user's attention for the questions that
matter.

Cover:

1. **Gates** — which of the commands you ran are mandatory, and what to do about any that
   currently fail.
2. **Autonomy** — `manual`, `supervised`, or `auto`. Explain the three stop points concretely
   (confirming acceptance criteria, an escalation, the final quickstart), and that at every
   level you still stop for failing gates, migrations, auth, payments, data deletion, and new
   dependencies. Default to `supervised`.
3. **Off-limits areas** — legacy directories, generated code, vendored code, anything the
   executor must never touch beyond the standing rules (`docs/`, `.claude/`, `CLAUDE.md`,
   dependency manifests, git). These become `extra_deny` entries in `.claude/dp-guard.json`.
4. **What is not visible in the code** — domain terms you could not infer, conventions the
   team follows but never wrote down, things that broke before and must not break again.

## 5. Write the documents

| File | What goes in |
| --- | --- |
| `docs/constitution.md` | the proven gates, the Delegation policy block, conventions taken from the code that is actually there |
| `docs/stack.md` | the stack table and every command, copy-pasteable and verified |
| `docs/architecture.md` | the module map from step 3, plus `## Not yet mapped` |
| `docs/glossary.md` | domain terms and their type names |
| `docs/knowledge/modules/*.md`, `docs/knowledge/INDEX.md` | deep-dive notes from step 3 |
| `CLAUDE.md` → `## Project specifics` | how to run the app, entry points, the non-obvious conventions you will rely on every session |
| `.claude/dp-guard.json` | project-specific `extra_deny` paths from the interview |

Leave no placeholder behind. `<lint command>`, `<provider/model>`, and bare `…` are the
markers that say "not onboarded", and every later session checks for them.

Do not weaken the executor's existing boundaries: `docs/`, `CLAUDE.md`, `.claude/`,
dependency manifests, and git are blocked for it by a project hook
(`.claude/hooks/dp-guard.sh`), not by convention. You may only add to `.claude/dp-guard.json`'s
`extra_deny`, never touch the hook itself or narrow what it already blocks.

## 6. Prove it

Run `bash scripts/doctor.sh` and show the output as it is. Fix what it reports.

## If the project is already onboarded

With `--recheck`, or when the documents are already filled in: read what is there, compare
it against the repository as it is now, and report the drift — a gate that no longer runs, a
module that moved, a stack version that changed. Propose the diff and apply it once the user
agrees. Do not overwrite what a human wrote.

## Then

Tell the user, in their language: which gates are now mandatory, what autonomy level is set,
what you could not determine. Then tell them the part that matters — from here they describe
what they want in plain words and you run everything else.
