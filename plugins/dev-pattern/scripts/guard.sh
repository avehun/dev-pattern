#!/usr/bin/env bash
# PreToolUse guard for the dev-pattern subagents. It never touches the main session's own
# tool calls or any other agent.
#
#   researcher  may write only inside the knowledge base (allowed even in plan mode)
#               and run only read-only Bash commands from an allow-list.
#   worker      may not edit docs/, .claude/, CLAUDE.md, .git/ or dependency manifests,
#               and may not run state-changing git or package-install commands.
#
# Fail-open: if anything here breaks (no jq, bad input), the hook exits 0 and Claude Code's
# normal permission flow applies. Exit 2 with a message on stderr denies the call.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh" || exit 0
command -v jq >/dev/null 2>&1 || exit 0

IN="$(cat)"
AGENT="$(jq -r '.agent_type // empty' <<<"$IN" 2>/dev/null)" || exit 0
case "$AGENT" in
  dev-pattern:researcher|researcher) ROLE=researcher ;;
  dev-pattern:worker|worker)         ROLE=worker ;;
  *) exit 0 ;;
esac

TOOL="$(jq -r '.tool_name // empty' <<<"$IN")"
CWD="$(jq -r '.cwd // empty' <<<"$IN")"
ROOT="$(cd "${CWD:-.}" 2>/dev/null && dp_root)" || exit 0
KB_REL="${DP_KB_DIR:-docs/dp/knowledge}"

deny()  { printf 'dev-pattern guard: %s\n' "$1" >&2; exit 2; }
allow() {
  jq -cn --arg r "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow", permissionDecisionReason: $r}}'
  exit 0
}

# Repo-relative path of an edited file, or empty when it is outside the repo or uses "..".
rel_path() {
  local f="$1"
  case "$f" in
    */../*|*/..|../*|..) return 0 ;;
  esac
  case "$f" in
    "$ROOT"/*) printf '%s' "${f#"$ROOT"/}" ;;
    /*)        ;;
    *)         printf '%s' "${f#./}" ;;
  esac
}

# ---------------------------------------------------------------------------- file edits
case "$TOOL" in
  Edit|Write|MultiEdit|NotebookEdit)
    FILE="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$IN")"
    [ -n "$FILE" ] || exit 0
    REL="$(rel_path "$FILE")"

    if [ "$ROLE" = "researcher" ]; then
      case "$REL" in
        "$KB_REL"/*.md) allow "researcher writing the knowledge base" ;;
      esac
      deny "the researcher may write only $KB_REL/*.md, not '$FILE'."
    fi

    # worker
    if [ -z "$REL" ]; then
      deny "'$FILE' is outside the repository or uses '..'; the worker edits only files in this repo."
    fi
    for pat in 'docs/*' '.claude/*' 'CLAUDE.md' '*/CLAUDE.md' '.git/*' \
               'package.json' 'package-lock.json' 'pnpm-lock.yaml' 'yarn.lock' 'bun.lockb' \
               'Cargo.toml' 'Cargo.lock' 'go.mod' 'go.sum' 'Gemfile' 'Gemfile.lock' \
               'pyproject.toml' 'poetry.lock' 'uv.lock' 'requirements*.txt' 'composer.json' 'composer.lock'; do
      # shellcheck disable=SC2254
      case "$REL" in
        $pat) deny "'$REL' belongs to the lead (matches '$pat'). Report it as blocked instead." ;;
      esac
    done
    exit 0
    ;;
esac

# --------------------------------------------------------------------------------- Bash
[ "$TOOL" = "Bash" ] || exit 0
CMD="$(jq -r '.tool_input.command // empty' <<<"$IN")"
[ -n "$CMD" ] || exit 0

# Commands are split naively on ; && || | — quoting is not parsed. That is why the researcher
# gets an allow-list (anything unrecognised is denied) rather than a block-list.
segments() { sed -E 's/(&&|\|\||;|\|)/\n/g' <<<"$CMD" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | awk 'NF'; }

# researcher: read-only commands only — plan mode does not stop file writes made through Bash,
# so this is what keeps its writes inside the knowledge base.
if [ "$ROLE" = "researcher" ]; then
  RO='git log, git show, git diff, git blame, git ls-files, git rev-parse, git status, dp-kb-stale, cat, head, tail, wc, ls, grep, pwd, cd'
  case "$CMD" in
    *'>'*|*'<'*|*'`'*|*'$('*|*'--output'*)
      deny "the researcher may not use redirection, substitution or --output in Bash. Read with Read/Grep/Glob; write the knowledge base with Write/Edit." ;;
  esac
  while IFS= read -r seg; do
    case "$seg" in
      *'&'*) deny "the researcher may not run background commands." ;;
      'git log'|'git log '*|'git show'|'git show '*|'git diff'|'git diff '*|'git blame '*) ;;
      'git ls-files'|'git ls-files '*|'git rev-parse '*|'git status'|'git status '*) ;;
      'dp-kb-stale'|'dp-kb-stale '*|'cat '*|'head '*|'tail '*|'wc '*|'ls'|'ls '*|'grep '*|'pwd'|'cd '*) ;;
      *) deny "'$seg' is not a read-only command the researcher may run ($RO). Read with Read/Grep/Glob; write the knowledge base with Write/Edit." ;;
    esac
  done < <(segments)
  allow "read-only command for the researcher"
fi

# worker: no state-changing git, no dependency installs
while IFS= read -r seg; do
  for p in 'git commit' 'git push' 'git checkout' 'git switch' 'git reset' 'git rebase' \
           'git stash' 'git merge' 'git cherry-pick' 'git tag' 'git branch -d' 'git branch -D' \
           'git clean' 'git restore' 'git rm' 'git mv' 'git add' \
           'npm install' 'npm i ' 'npm add' 'pnpm add' 'pnpm install' 'yarn add' 'yarn install' \
           'pip install' 'pip3 install' 'poetry add' 'uv add' 'cargo add' 'go get' 'go install' \
           'bundle add' 'composer require'; do
    case "$seg" in
      "$p"*) deny "'$seg' is for the lead only (blocked prefix '$p')." ;;
    esac
  done
done < <(segments)
exit 0
