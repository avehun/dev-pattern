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
for s in scripts/*.sh scripts/lib/*.sh template/.claude/hooks/*.sh; do
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

dp_info "3. dp-guard.sh actually enforces the executor's boundaries (live synthetic test)"
HOOK="$ROOT/template/.claude/hooks/dp-guard.sh"
if [ -x "$HOOK" ]; then
  T="$(mktemp -d)"
  mkdir -p "$T/.claude" "$T/src" "$T/docs"
  cat > "$T/.claude/dp-active-task.json" <<'JSON'
{"task_id":"T-CHECK","feature":"check","agent":"dp-implementer","allowed_paths":["src/allowed.ts"],"report_path":"docs/report.md","delegated_at":"2026-01-01T00:00:00Z"}
JSON
  echo '{"extra_deny": ["legacy/**"]}' > "$T/.claude/dp-guard.json"

  assert_hook() {  # assert_hook LABEL PAYLOAD EXPECT_EXIT
    local label="$1" payload="$2" expect="$3" got
    got="$(CLAUDE_PROJECT_DIR="$T" bash -c "cd '$T' && echo '$payload' | bash '$HOOK' >/dev/null 2>&1; echo \$?")"
    [ "$got" = "$expect" ] && pass "$label (exit $got)" || fail "$label — expected exit $expect, got $got"
  }

  assert_hook "lead's own call (no agent_type) always passes through" \
    '{"tool_name":"Edit","tool_input":{"file_path":"docs/constitution.md"}}' 0

  assert_hook "executor blocked from docs/**" \
    '{"agent_type":"dp-implementer","tool_name":"Edit","tool_input":{"file_path":"docs/constitution.md"}}' 2

  assert_hook "executor blocked from CLAUDE.md" \
    '{"agent_type":"dp-implementer","tool_name":"Edit","tool_input":{"file_path":"CLAUDE.md"}}' 2

  assert_hook "executor allowed its own report path (exception inside docs/**)" \
    "{\"agent_type\":\"dp-implementer\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$T/docs/report.md\"}}" 0

  assert_hook "executor allowed a file in allowed_paths" \
    "{\"agent_type\":\"dp-implementer\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$T/src/allowed.ts\"}}" 0

  assert_hook "executor blocked from a file NOT in allowed_paths" \
    "{\"agent_type\":\"dp-implementer\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$T/src/other.ts\"}}" 2

  assert_hook "executor blocked from an extra_deny path" \
    "{\"agent_type\":\"dp-implementer\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$T/legacy/old.ts\"}}" 2

  assert_hook "executor blocked from git commit" \
    '{"agent_type":"dp-implementer","tool_name":"Bash","tool_input":{"command":"git commit -m x"}}' 2

  assert_hook "executor blocked from git push hidden in a compound command" \
    '{"agent_type":"dp-fixer","tool_name":"Bash","tool_input":{"command":"echo hi && git push origin main"}}' 2

  assert_hook "executor allowed to run tests" \
    '{"agent_type":"dp-implementer","tool_name":"Bash","tool_input":{"command":"npm test -- src/foo"}}' 0

  rm -rf "$T"
else
  fail ".claude/hooks/dp-guard.sh is missing or not executable — cannot run the live synthetic test"
fi

dp_info "4. Executor subagents have required frontmatter and run on sonnet"
for a in template/.claude/agents/*.md; do
  ok=1
  for k in name description model tools; do
    [ -n "$(dp_fm "$a" "$k")" ] || { fail "$a is missing '$k'"; ok=0; }
  done
  m="$(dp_fm "$a" model)"
  [ "$m" = "sonnet" ] || { fail "$a has model '$m', expected 'sonnet'"; ok=0; }
  [ "$ok" = "1" ] && pass "$(basename "$a")"
done

dp_info "5. Claude commands have a description"
for c in template/.claude/commands/dp/*.md; do
  [ -n "$(dp_fm "$c" description)" ] && pass "$(basename "$c")" || fail "$c is missing 'description'"
done

dp_info "6. Artifact templates have frontmatter"
for t in templates/*.md; do
  case "$(basename "$t")" in
    constitution.md|adr.md|task-card.md|executor-report.md|review-report.md|spec.md|plan.md|tasks.md|research.md|data-model.md|quickstart.md|checklist.md|knowledge-module.md)
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
AGENT_DEFAULT="$(dp_fm templates/task-card.md agent)"
case "$AGENT_DEFAULT" in
  dp-implementer|dp-fixer|dp-test-writer) pass "task-card agent default is '$AGENT_DEFAULT'" ;;
  *) fail "task-card.md agent default is '$AGENT_DEFAULT', expected a dp-* subagent name" ;;
esac

dp_info "8. Relative markdown links resolve"
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

dp_info "9. Templates reference only real script names"
while IFS= read -r ref; do
  [ -f "$ref" ] && pass "$ref exists" || fail "referenced but missing: $ref"
done < <(grep -rhoE 'scripts/[a-z-]+\.sh' template templates docs README.md 2>/dev/null | sort -u)

dp_info "10. No leftover references to opencode"
HITS=0
while IFS= read -r f; do
  while IFS= read -r line; do
    dp_err "  $f: $line"
    HITS=$((HITS + 1))
  done < <(grep -in 'opencode\|AGENTS\.md\|\.opencode/' "$f" 2>/dev/null)
done < <(find template templates docs README.md CLAUDE.md scripts -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' \) 2>/dev/null | grep -v '/check\.sh$')
[ "$HITS" = "0" ] && pass "no references to opencode, AGENTS.md, or .opencode/ remain" \
  || fail "$HITS leftover opencode reference(s) — this repo no longer uses opencode"

dp_info "11. The lead can run the whole cycle without the user"
for c in onboard feature delegate; do
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
grep -q "add -A -- ':!.claude'" scripts/prepare-delegation.sh \
  && pass "prepare-delegation.sh commits pending changes before delegating" \
  || fail "scripts/prepare-delegation.sh does not commit before delegating — isolation:\"worktree\" only sees committed state, this was confirmed to break real delegation"

dp_info "13. The lead has the permissions its own pipeline needs"
if command -v jq >/dev/null 2>&1; then
  S=template/.claude/settings.json
  MODEL="$(jq -r '.model // "unset"' "$S")"
  [ "$MODEL" = "opus" ] && pass "lead pinned to opus" || fail "$S has model '$MODEL', expected \"opus\""

  jq -e '.hooks.PreToolUse // empty | length > 0' "$S" >/dev/null 2>&1 \
    && pass "PreToolUse hook registered" \
    || fail "$S registers no PreToolUse hook — dp-guard.sh would never run"

  for p in 'Bash(git commit:*)' 'Bash(git switch:*)' 'Bash(git merge:*)' \
           'Bash(scripts/prepare-delegation.sh:*)' 'Bash(scripts/set-status.sh:*)' 'Bash(scripts/status.sh:*)'; do
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

dp_info "14. The knowledge base exists and is wired into the pipeline"
[ -f template/docs/knowledge/INDEX.md ] && pass "template/docs/knowledge/INDEX.md exists" \
  || fail "missing template/docs/knowledge/INDEX.md"
[ -f templates/knowledge-module.md ] && pass "templates/knowledge-module.md exists" \
  || fail "missing templates/knowledge-module.md"
for c in research onboard review accept; do
  grep -qi 'knowledge' "template/.claude/commands/dp/$c.md" \
    && pass "$c.md references the knowledge base" \
    || fail "template/.claude/commands/dp/$c.md never mentions docs/knowledge/ — findings will not accumulate"
done

echo
if [ "$FAILED" -eq 0 ]; then
  dp_ok "${C_BLD}All checks passed.${C_OFF}"
  exit 0
fi
dp_err "${C_BLD}$FAILED check(s) failed.${C_OFF}"
exit 1
