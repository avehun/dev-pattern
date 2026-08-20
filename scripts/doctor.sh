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
if command -v opencode >/dev/null 2>&1; then
  check_ok "opencode installed ($(opencode --version 2>/dev/null | head -1))"
else
  check_fail "opencode not found — install it from https://opencode.ai"
fi

if command -v git >/dev/null 2>&1; then
  if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    check_ok "git repository"
  else
    check_fail "not a git repository — review has no diff to read; run: git init"
  fi
else
  check_fail "git not found"
fi

command -v jq >/dev/null 2>&1 && check_ok "jq installed" || dp_warn "jq not found (optional, used by checks)"

# ---- credentials
if command -v opencode >/dev/null 2>&1; then
  CREDS="$(timeout 30 opencode auth list 2>/dev/null | grep -oE '[0-9]+ credential' | head -1)"
  case "$CREDS" in
    ""|"0 credential") check_fail "opencode has no credentials — run: opencode auth login" ;;
    *)                 check_ok "opencode credentials: $CREDS" ;;
  esac
fi

# ---- files
for f in CLAUDE.md AGENTS.md opencode.json docs/constitution.md; do
  [ -f "$ROOT/$f" ] && check_ok "$f" || check_fail "missing $f — run scripts/init.sh"
done

for d in .claude/commands/dp .opencode/agents docs/specs docs/.templates; do
  [ -d "$ROOT/$d" ] && check_ok "$d/" || check_fail "missing $d/ — run scripts/init.sh"
done

# ---- config validity
if [ -f "$ROOT/opencode.json" ] && command -v jq >/dev/null 2>&1; then
  jq empty "$ROOT/opencode.json" 2>/dev/null \
    && check_ok "opencode.json is valid JSON" \
    || check_fail "opencode.json is not valid JSON"

  for path in 'docs/**' 'CLAUDE.md' '.claude/**'; do
    v="$(jq -r --arg p "$path" '.permission.edit[$p] // "unset"' "$ROOT/opencode.json" 2>/dev/null)"
    [ "$v" = "deny" ] \
      && check_ok "executor denied edit access to $path" \
      || check_fail "opencode.json does not deny edit on $path — the executor could rewrite the lead's documents"
  done
fi

if [ -f "$ROOT/.claude/settings.json" ] && command -v jq >/dev/null 2>&1; then
  jq empty "$ROOT/.claude/settings.json" 2>/dev/null \
    && check_ok ".claude/settings.json is valid JSON" \
    || check_fail ".claude/settings.json is not valid JSON"
fi

# ---- agents visible to opencode
if command -v opencode >/dev/null 2>&1; then
  AGENTS_OUT="$( (cd "$ROOT" && timeout 60 opencode agent list 2>/dev/null) | grep -E '^[a-z-]+ \(' || true)"
  for a in implementer fixer test-writer; do
    if printf '%s\n' "$AGENTS_OUT" | grep -q "^$a "; then
      check_ok "agent '$a' is loaded"
    else
      check_fail "agent '$a' is not loaded — check .opencode/agents/$a.md"
    fi
  done
fi

# ---- constitution actually filled in
if [ -f "$ROOT/docs/constitution.md" ]; then
  if grep -q '<lint command>\|<test command>\|<build command>' "$ROOT/docs/constitution.md"; then
    check_fail "docs/constitution.md still has placeholder quality gates — fill them in before delegating"
  else
    check_ok "quality gates in docs/constitution.md are filled in"
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
