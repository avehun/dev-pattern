#!/usr/bin/env bash
# Offline self-check of the dev-pattern repository. No network, no credentials needed.
#
#   bash scripts/check.sh
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

ROOT="$(dp_root)"
cd "$ROOT"
FAILED=0
pass() { dp_ok "$1"; }
fail() { dp_err "$1"; FAILED=$((FAILED + 1)); }

dp_info "1. Shell scripts parse"
for s in scripts/*.sh scripts/lib/*.sh; do
  bash -n "$s" 2>/dev/null && pass "$s" || fail "$s has a syntax error"
done

dp_info "2. JSON is valid"
if command -v jq >/dev/null 2>&1; then
  while IFS= read -r f; do
    jq empty "$f" 2>/dev/null && pass "$f" || fail "$f is not valid JSON"
  done < <(find template -name '*.json')
else
  dp_warn "jq not installed — skipping"
fi

dp_info "3. Executor is denied the lead's files"
if command -v jq >/dev/null 2>&1; then
  for p in 'docs/**' 'CLAUDE.md' 'AGENTS.md' '.claude/**' '.opencode/**' 'opencode.json'; do
    v="$(jq -r --arg p "$p" '.permission.edit[$p] // "unset"' template/opencode.json)"
    [ "$v" = "deny" ] && pass "edit '$p' = deny" || fail "edit '$p' is '$v', expected deny"
  done
  v="$(jq -r '.permission.edit["docs/specs/*/reports/**"] // "unset"' template/opencode.json)"
  [ "$v" = "allow" ] && pass "executor can write its reports" || fail "reports path is '$v', expected allow"
  for b in 'git commit*' 'git push*' 'git reset*'; do
    v="$(jq -r --arg b "$b" '.permission.bash[$b] // "unset"' template/opencode.json)"
    [ "$v" = "deny" ] && pass "bash '$b' = deny" || fail "bash '$b' is '$v', expected deny"
  done
fi

dp_info "4. Agent definitions have required frontmatter"
for a in template/.opencode/agents/*.md; do
  ok=1
  for k in description mode model; do
    [ -n "$(dp_fm "$a" "$k")" ] || { fail "$a is missing '$k'"; ok=0; }
  done
  m="$(dp_fm "$a" mode)"
  case "$m" in primary|subagent|all) ;; *) fail "$a has mode '$m'"; ok=0 ;; esac
  [ "$ok" = "1" ] && pass "$(basename "$a")"
done

dp_info "5. Claude commands have a description"
for c in template/.claude/commands/dp/*.md; do
  [ -n "$(dp_fm "$c" description)" ] && pass "$(basename "$c")" || fail "$c is missing 'description'"
done

dp_info "6. Artifact templates have frontmatter"
for t in templates/*.md; do
  case "$(basename "$t")" in
    constitution.md|adr.md|task-card.md|executor-report.md|review-report.md|spec.md|plan.md|tasks.md|research.md|data-model.md|quickstart.md|checklist.md)
      head -1 "$t" | grep -q '^---$' && pass "$(basename "$t")" || fail "$t does not start with frontmatter" ;;
  esac
done

dp_info "7. The task card template is complete"
for section in '## Goal' '## Context' '## Files you may touch' '## Step-by-step' \
               '## Acceptance criteria' '## How to verify' '## Out of scope' ; do
  grep -qF "$section" templates/task-card.md && pass "task-card has '$section'" \
    || fail "task-card.md is missing '$section'"
done
for k in id feature status depends_on attempt agent model allowed_paths verify; do
  [ -n "$(dp_fm templates/task-card.md "$k")$(dp_fm_list templates/task-card.md "$k")" ] \
    && pass "task-card frontmatter has '$k'" || fail "task-card.md frontmatter is missing '$k'"
done

dp_info "8. AGENTS.md stays short enough for a weak model"
LINES="$(wc -l < template/AGENTS.md)"
[ "$LINES" -le 110 ] && pass "AGENTS.md is $LINES lines" \
  || fail "AGENTS.md is $LINES lines — keep it under ~100 or free models will drift"

dp_info "9. Relative markdown links resolve"
BROKEN=0
while IFS= read -r f; do
  dir="$(dirname "$f")"
  while IFS= read -r link; do
    case "$link" in
      http*|mailto:*|'#'*|'') continue ;;
    esac
    target="${link%%#*}"
    [ -z "$target" ] && continue
    if [ ! -e "$dir/$target" ] && [ ! -e "$ROOT/$target" ]; then
      dp_err "  $f -> $target"
      BROKEN=$((BROKEN + 1))
    fi
  done < <(grep -oE '\]\([^)]+\)' "$f" | sed 's/^](//; s/)$//')
done < <(find . -name '*.md' -not -path './.git/*' -not -path './templates/*' -not -path './template/*')
[ "$BROKEN" = "0" ] && pass "no broken relative links in docs/ and README" \
  || fail "$BROKEN broken relative link(s)"

dp_info "10. Templates reference only real script names"
while IFS= read -r ref; do
  [ -f "$ref" ] && pass "$ref exists" || fail "referenced but missing: $ref"
done < <(grep -rhoE 'scripts/[a-z-]+\.sh' template templates docs README.md 2>/dev/null | sort -u)

dp_info "11. The lead can run the whole cycle without the user"
for c in onboard feature; do
  f="template/.claude/commands/dp/$c.md"
  [ -f "$f" ] && pass "$c command exists" || fail "missing $f"
done
grep -q '^## Before anything else$' template/CLAUDE.md \
  && pass "CLAUDE.md checks for an un-onboarded project first" \
  || fail "template/CLAUDE.md has no 'Before anything else' section — the lead will start a feature against placeholder gates"
grep -q '^## The user does not run commands$' template/CLAUDE.md \
  && pass "CLAUDE.md routes plain-language requests into the pipeline" \
  || fail "template/CLAUDE.md is missing the routing section"
grep -q '^## Where you stop for the user$' template/CLAUDE.md \
  && pass "CLAUDE.md defines the stop points" \
  || fail "template/CLAUDE.md is missing the autonomy section"

dp_info "12. The constitution carries a delegation policy"
AUT="$(awk '/^autonomy:[[:space:]]/ { sub(/^autonomy:[[:space:]]*/, ""); sub(/[[:space:]]*#.*$/, ""); sub(/[[:space:]]+$/, ""); print; exit }' templates/constitution.md)"
case "$AUT" in
  manual|supervised|auto) pass "autonomy default is '$AUT'" ;;
  *)                      fail "templates/constitution.md has autonomy '$AUT', expected manual|supervised|auto" ;;
esac
for k in 'executor-model:' 'max-attempts:'; do
  grep -q "^$k" templates/constitution.md && pass "constitution has '$k'" \
    || fail "templates/constitution.md is missing '$k'"
done
grep -q 'dp_not_onboarded' scripts/status.sh && pass "status.sh reports the onboarding state" \
  || fail "scripts/status.sh does not check whether the project is onboarded"
grep -q 'no TTY and --auto was not given' scripts/delegate.sh \
  && pass "delegate.sh refuses to hang without a TTY" \
  || fail "scripts/delegate.sh can block forever when the lead runs it without --auto"


dp_info "13. The lead has the permissions its own pipeline needs"
if command -v jq >/dev/null 2>&1; then
  S=template/.claude/settings.json
  for p in 'Bash(git commit:*)' 'Bash(git switch:*)' 'Bash(git merge:*)' 'Bash(scripts/status.sh:*)'; do
    jq -e --arg p "$p" '.permissions.allow | index($p)' "$S" >/dev/null 2>&1 \
      && pass "allow $p" \
      || fail "$S does not allow '$p' — the lead stalls on a permission prompt mid-pipeline"
  done
  jq -e '.permissions.deny | index("Bash(git push:*)")' "$S" >/dev/null 2>&1 \
    && pass "deny Bash(git push:*)" \
    || fail "$S must keep 'Bash(git push:*)' denied — publishing is the user's call"
  jq -e '.permissions.ask | index("Edit(src/**)")' "$S" >/dev/null 2>&1 \
    && pass "production code edits still ask" \
    || fail "$S no longer asks before the lead edits src/** — that is the human's last look at the code"
fi
echo
if [ "$FAILED" -eq 0 ]; then
  dp_ok "${C_BLD}All checks passed.${C_OFF}"
  exit 0
fi
dp_err "${C_BLD}$FAILED check(s) failed.${C_OFF}"
exit 1
