#!/usr/bin/env bash
# PreToolUse guard for dev-pattern executor subagents (dp-implementer, dp-fixer,
# dp-test-writer). No-ops instantly for the lead's own top-level tool calls and for any
# other subagent — it only ever restricts the three names below.
#
# NEEDS EMPIRICAL VERIFICATION AGAINST A LIVE CLAUDE CODE INSTALL BEFORE TRUSTING:
#   - exact field name `agent_type` in the PreToolUse stdin payload
#   - `tool_input.file_path` for Edit/Write/MultiEdit, `tool_input.command` for Bash
#   - whether exit code 2 is honored when the *effective* permissionMode is acceptEdits
#     or bypassPermissions (docs suggest hook "deny" may be bypassed there — if so, this
#     guard provides no protection under those modes; never run the lead with
#     --dangerously-skip-permissions, and keep subagent permissionMode: auto)
set -uo pipefail

IN="$(cat)"
AGENT_TYPE="$(jq -r '.agent_type // empty' <<<"$IN" 2>/dev/null)"

case "$AGENT_TYPE" in
  dp-implementer|dp-fixer|dp-test-writer) ;;
  *) exit 0 ;;   # not one of our executors (includes the lead: agent_type absent) — no-op
esac

TOOL="$(jq -r '.tool_name // empty' <<<"$IN")"

# Two different roots, because isolation:"worktree" runs the executor in a REAL git
# worktree (Claude Code's own, under .claude/worktrees/agent-<id>/ in the main checkout,
# or wherever the harness places it) — a separate absolute path from the main checkout:
#   STATE_ROOT — where the lead's process state lives (.claude/dp-active-task.json,
#                .claude/dp-guard.json). This state is written by the lead in the MAIN
#                checkout and is never per-worktree, so it must resolve there even when
#                this hook fires for a tool call happening inside an isolated worktree.
#   FILE_ROOT  — the root the EDITED FILE's path should be made relative to, so it can be
#                compared against allowed_paths (which are plain repo-relative paths like
#                "src/foo.ts"). This must be the CURRENT worktree's own top level, not the
#                main checkout — otherwise a path like <main>/.claude/worktrees/agent-x/
#                docs/specs/.../reports/T-001.md relativizes against the main checkout as
#                ".claude/worktrees/agent-x/docs/specs/.../reports/T-001.md", which starts
#                with ".claude/" and trips the static deny list before ever reaching the
#                report-path exemption. Empirically confirmed via a live subagent run.
STATE_ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
FILE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "$STATE_ROOT")"
GUARD_CFG="$STATE_ROOT/.claude/dp-guard.json"
ACTIVE="$STATE_ROOT/.claude/dp-active-task.json"

deny() { printf 'dp-guard: %s\n' "$1" >&2; exit 2; }

# ---------------------------------------------------------------- Edit / Write / MultiEdit
case "$TOOL" in
  Edit|Write|MultiEdit|NotebookEdit)
    FILE="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$IN")"
    [ -n "$FILE" ] || exit 0   # cannot determine a path — nothing to restrict on

    case "$FILE" in
      "$FILE_ROOT"/*) REL="${FILE#"$FILE_ROOT"/}" ;;
      /*)             REL="$FILE" ;;      # outside this worktree's root entirely
      *)              REL="$FILE" ;;      # already relative
    esac

    # 0. exact allow: this task's OWN report file, per the active-task pointer.
    #    Checked first because the report legitimately lives under docs/**.
    if [ -f "$ACTIVE" ]; then
      REPORT_PATH="$(jq -r '.report_path // empty' "$ACTIVE")"
      if [ -n "$REPORT_PATH" ] && [ "$REL" = "$REPORT_PATH" ]; then
        exit 0
      fi
    fi

    # 1. static deny list — never editable by any executor, ever
    STATIC_DENY=(
      'docs/**' '.claude/**' 'CLAUDE.md' '.git/**'
      'package.json' 'package-lock.json' 'pnpm-lock.yaml' 'yarn.lock'
      'Cargo.toml' 'Cargo.lock' 'go.mod' 'go.sum'
      'pyproject.toml' 'poetry.lock' 'uv.lock' 'requirements.txt'
    )
    for pat in "${STATIC_DENY[@]}"; do
      case "$REL" in
        $pat) deny "'$REL' matches the static deny list ('$pat'). docs/, .claude/, CLAUDE.md, git internals and dependency manifests/lockfiles are never editable by an executor subagent." ;;
      esac
    done

    # 2. project-editable extra deny list (.claude/dp-guard.json, seeded by onboarding)
    if [ -f "$GUARD_CFG" ]; then
      while IFS= read -r pat; do
        [ -n "$pat" ] || continue
        case "$REL" in
          $pat) deny "'$REL' matches an extra_deny rule ('$pat') in .claude/dp-guard.json." ;;
        esac
      done < <(jq -r '.extra_deny[]? // empty' "$GUARD_CFG")
    fi

    # 3. this task's allowed_paths, via the active-task pointer — fail closed if absent
    if [ ! -f "$ACTIVE" ]; then
      deny "no active task is registered (.claude/dp-active-task.json is missing). Refusing every edit until scripts/prepare-delegation.sh has run for a task."
    fi

    MATCH=0
    while IFS= read -r ap; do
      [ -n "$ap" ] || continue
      if [ "$REL" = "$ap" ]; then MATCH=1; break; fi
    done < <(jq -r '.allowed_paths[]? // empty' "$ACTIVE")

    if [ "$MATCH" = "0" ]; then
      TID="$(jq -r '.task_id // "?"' "$ACTIVE")"
      AP="$(jq -c '.allowed_paths // []' "$ACTIVE")"
      deny "'$REL' is not in $TID's allowed_paths ($AP) and is not $TID's report file."
    fi
    exit 0
    ;;
esac

# ---------------------------------------------------------------------------------- Bash
if [ "$TOOL" = "Bash" ]; then
  CMD="$(jq -r '.tool_input.command // empty' <<<"$IN")"
  [ -n "$CMD" ] || exit 0

  DENY_PREFIXES=(
    'git commit' 'git push' 'git checkout' 'git switch' 'git reset' 'git rebase'
    'git stash' 'git merge' 'git cherry-pick' 'git tag' 'git branch -d' 'git branch -D'
    'npm install' 'npm i ' 'npm add' 'pnpm add' 'pnpm install' 'yarn add' 'yarn install'
    'pip install' 'pip3 install' 'poetry add' 'cargo add' 'go get' 'go install'
    'bundle add' 'composer require'
  )

  # split on ; && || | (naive — does not parse quoting; a `bash -c "..."` wrapper can
  # still evade this — a known, documented residual gap, not solved here)
  while IFS= read -r seg; do
    seg="$(printf '%s' "$seg" | sed -E 's/^[[:space:]]+//')"
    [ -n "$seg" ] || continue
    for p in "${DENY_PREFIXES[@]}"; do
      case "$seg" in
        "$p"*) deny "command segment '$seg' starts with a blocked prefix ('$p'). State-changing git and dependency-install commands are for the lead only." ;;
      esac
    done
  done < <(printf '%s\n' "$CMD" | sed -E 's/(&&|\|\||;|\|)/\n/g')
  exit 0
fi

exit 0   # Read/Grep/Glob/etc. — no path or state risk, always allowed
