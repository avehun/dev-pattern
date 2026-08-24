#!/usr/bin/env bash
# Check that the dev-pattern setup in a project is complete and usable.
#
#   bash scripts/doctor.sh [--dir PROJECT_ROOT]
#
# Exit code 0 = ready, 1 = something needs fixing.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

ROOT="."
while [ $# -gt 0 ]; do
  case "$1" in
    --dir)     ROOT="$2"; shift ;;
    -h|--help) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)         ROOT="$1" ;;
  esac
  shift
done
ROOT="$(cd "$ROOT" && pwd)"

PROBLEMS=0
check_ok()   { dp_ok "$1"; }
check_fail() { dp_err "$1"; PROBLEMS=$((PROBLEMS + 1)); }

dp_info "Checking ${C_BLD}$ROOT${C_OFF}"

# ---- tooling
if command -v git >/dev/null 2>&1; then
  if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    check_ok "git repository"
  else
    check_fail "not a git repository — worktree-isolated delegation and review both need one; run: git init"
  fi
else
  check_fail "git not found"
fi

command -v jq >/dev/null 2>&1 && check_ok "jq installed" || check_fail "jq not found — required by dp-guard.sh and every dp_* helper"

# ---- files
for f in CLAUDE.md docs/constitution.md .claude/settings.json .claude/dp-guard.json; do
  [ -f "$ROOT/$f" ] && check_ok "$f" || check_fail "missing $f — run scripts/init.sh"
done

for f in .claude/commands/dp/onboard.md .claude/commands/dp/feature.md .claude/commands/dp/delegate.md; do
  [ -f "$ROOT/$f" ] && check_ok "$f" || check_fail "missing $f — run scripts/init.sh"
done

for d in .claude/commands/dp .claude/agents .claude/hooks docs/specs docs/.templates docs/knowledge/modules; do
  [ -d "$ROOT/$d" ] && check_ok "$d/" || check_fail "missing $d/ — run scripts/init.sh"
done

# ---- the hook that enforces the executor's boundaries
if [ -f "$ROOT/.claude/hooks/dp-guard.sh" ]; then
  if [ -x "$ROOT/.claude/hooks/dp-guard.sh" ]; then
    check_ok ".claude/hooks/dp-guard.sh is executable"
  else
    check_fail ".claude/hooks/dp-guard.sh exists but is not executable — chmod +x it (or re-run scripts/init.sh)"
  fi
else
  check_fail "missing .claude/hooks/dp-guard.sh — the executor's boundaries would not be enforced at all"
fi

# ---- config validity
if [ -f "$ROOT/.claude/settings.json" ] && command -v jq >/dev/null 2>&1; then
  S="$ROOT/.claude/settings.json"
  jq empty "$S" 2>/dev/null \
    && check_ok ".claude/settings.json is valid JSON" \
    || check_fail ".claude/settings.json is not valid JSON"

  MODEL="$(jq -r '.model // "unset"' "$S" 2>/dev/null)"
  [ "$MODEL" = "opus" ] \
    && check_ok "lead is pinned to opus" \
    || check_fail ".claude/settings.json has model '$MODEL', expected \"opus\" — the lead should not silently run on whatever the user's default is"

  jq -e '.hooks.PreToolUse // empty | length > 0' "$S" >/dev/null 2>&1 \
    && check_ok "PreToolUse hook is registered" \
    || check_fail ".claude/settings.json registers no PreToolUse hook — dp-guard.sh would never run"

  jq -e '.permissions.deny // [] | index("Bash(git push:*)")' "$S" >/dev/null 2>&1 \
    && check_ok "deny Bash(git push:*)" \
    || check_fail "$S must keep 'Bash(git push:*)' denied — publishing is the user's call, not the lead's"
fi

if [ -f "$ROOT/.claude/dp-guard.json" ] && command -v jq >/dev/null 2>&1; then
  jq empty "$ROOT/.claude/dp-guard.json" 2>/dev/null \
    && check_ok ".claude/dp-guard.json is valid JSON" \
    || check_fail ".claude/dp-guard.json is not valid JSON"
fi

# ---- the three executor subagents
for a in dp-implementer dp-fixer dp-test-writer; do
  f="$ROOT/.claude/agents/$a.md"
  if [ ! -f "$f" ]; then
    check_fail "missing .claude/agents/$a.md — the executor cannot be invoked at all"
    continue
  fi
  MODEL="$(dp_fm "$f" model)"
  if [ "$MODEL" = "sonnet" ]; then
    check_ok "$a is loaded (model: sonnet)"
  else
    check_fail "$a.md has model '$MODEL', expected 'sonnet'"
  fi
done

# ---- knowledge base
if [ -f "$ROOT/docs/knowledge/INDEX.md" ]; then
  check_ok "docs/knowledge/INDEX.md exists"
else
  check_fail "missing docs/knowledge/INDEX.md — the lead has nowhere to record what it has already learned; run scripts/init.sh or /dp:onboard"
fi

# ---- onboarding: are the project's own documents filled in?
if [ -f "$ROOT/docs/constitution.md" ]; then
  if dp_not_onboarded "$ROOT"; then
    check_fail "project is not onboarded — docs/constitution.md or docs/stack.md still hold
        template placeholders. Open Claude Code here and say what you want to do; the lead
        reads the codebase, asks you what it cannot work out, and fills them in. Or run
        /dp:onboard directly."
  else
    check_ok "project documents are filled in (autonomy: $(dp_autonomy "$ROOT"))"
  fi

  AUT="$(awk '/^autonomy:[[:space:]]/ { print; exit }' "$ROOT/docs/constitution.md")"
  if [ -n "$AUT" ]; then
    check_ok "delegation policy present"
  else
    check_fail "docs/constitution.md has no 'autonomy:' line — add the Delegation policy
        section from docs/.templates/constitution.md, or the lead cannot know where to stop"
  fi
fi

# ---- board summary
if [ -d "$ROOT/docs/specs" ]; then
  FEATURES="$(find "$ROOT/docs/specs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
  CARDS="$(find "$ROOT/docs/specs" -path '*/tasks/*' -name 'T-*.md' 2>/dev/null | wc -l)"
  dp_dim "    features: $FEATURES   task cards: $CARDS"
fi

echo
if [ "$PROBLEMS" -eq 0 ]; then
  dp_ok "${C_BLD}Ready.${C_OFF}"
  exit 0
fi
dp_err "${C_BLD}$PROBLEMS problem(s) to fix.${C_OFF}"
exit 1
