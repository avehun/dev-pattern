#!/usr/bin/env bash
# Read-only validation of a task card, then (only on success) the minimal state mutation
# needed before the lead calls the Agent tool itself: bump attempt, set status
# in_progress, write .claude/dp-active-task.json. On failure: prints every reason found
# and mutates nothing.
#
#   bash scripts/prepare-delegation.sh <T-XXX> [--dir PROJECT_ROOT] [--agent NAME]
#
# The Agent-tool call itself (spawning dp-implementer/dp-fixer/dp-test-writer) cannot
# happen inside this script — bash cannot invoke it. The lead does that step itself,
# right after this script exits 0, per .claude/commands/dp/delegate.md.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

TASK=""; ROOT="."; AGENT_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dir)     ROOT="$2"; shift ;;
    --agent)   AGENT_OVERRIDE="$2"; shift ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        dp_die "unknown option: $1" ;;
    *)         TASK="$1" ;;
  esac
  shift
done
if [ -z "$TASK" ]; then dp_die "usage: prepare-delegation.sh <T-XXX> [--agent NAME]"; fi
ROOT="$(cd "$ROOT" && pwd)"

CARD="$(dp_find_card "$ROOT" "$TASK")" || dp_die "no task card found for $TASK under $ROOT/docs/specs/*/tasks/"
FEATURE_DIR="$(dp_feature_dir "$CARD")"
FEATURE="$(basename "$FEATURE_DIR")"
REPORT="$FEATURE_DIR/reports/$TASK.md"
REPORT_REL="${REPORT#"$ROOT"/}"
REVIEW="$FEATURE_DIR/reviews/$TASK.md"

STATUS="$(dp_fm "$CARD" status)"
ATTEMPT="$(dp_fm "$CARD" attempt)"; ATTEMPT="${ATTEMPT:-0}"
VERIFY="$(dp_fm "$CARD" verify)"
if [ -n "$AGENT_OVERRIDE" ]; then AGENT="$AGENT_OVERRIDE"; else AGENT="$(dp_fm "$CARD" agent)"; fi
AGENT="${AGENT:-dp-implementer}"
MAX_ATTEMPTS="$(dp_max_attempts "$ROOT")"

dp_info "Task ${C_BLD}$TASK${C_OFF}  ($FEATURE)"
printf '    card    %s\n' "${CARD#"$ROOT"/}"
printf '    agent   %s\n' "$AGENT"
printf '    status  %s (attempt %s/%s)\n' "$STATUS" "$ATTEMPT" "$MAX_ATTEMPTS"

FAIL=0
fail() { dp_err "$1"; FAIL=1; }

case "$STATUS" in
  todo|changes_requested) ;;
  in_progress) dp_warn "card is already in_progress — a previous run may not have finished" ;;
  in_review)   fail "card is in_review; run /dp:review $TASK first" ;;
  done)        fail "card is already done" ;;
  blocked)     fail "card is blocked; rewrite it before delegating again" ;;
  escalated)   fail "card is escalated; split it or implement it yourself, do not re-delegate as-is" ;;
  *)           fail "unknown status: '$STATUS'" ;;
esac

if [ -z "$VERIFY" ]; then
  fail "card has no 'verify' command — nobody can know when the task is finished"
fi

ALLOWED_PATHS=()
while IFS= read -r p; do
  if [ -n "$p" ]; then ALLOWED_PATHS+=("$p"); fi
done < <(dp_fm_list "$CARD" allowed_paths)
if [ "${#ALLOWED_PATHS[@]}" -eq 0 ]; then
  fail "card has no 'allowed_paths' — the executor would be unbounded"
fi

while IFS= read -r dep; do
  [ -n "$dep" ] || continue
  depcard="$(dp_find_card "$ROOT" "$dep")" || { fail "depends_on $dep — no such card"; continue; }
  depstatus="$(dp_fm "$depcard" status)"
  if [ "$depstatus" != "done" ]; then
    fail "depends_on $dep is '$depstatus', not 'done'"
  fi
done < <(dp_fm_list "$CARD" depends_on)

if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ] 2>/dev/null; then
  fail "attempt is $ATTEMPT of $MAX_ATTEMPTS — escalate instead: split the card, rewrite its Context, or implement it yourself"
fi

# ignore HTML comments — authoring notes are allowed to mention what not to write
CARD_BODY="$(sed 's/<!--.*-->//g' "$CARD" | awk '/<!--/{c=1} !c{print} /-->/{c=0}')"
if printf '%s' "$CARD_BODY" | grep -qiE '\bsee (plan|spec|architecture)\.md\b|explore the (codebase|repo)'; then
  fail "card tells the executor to look elsewhere for context — point at a file:line or a docs/knowledge/modules/*.md entry instead"
fi

case "$AGENT" in
  dp-implementer|dp-test-writer) ;;
  dp-fixer)
    if [ ! -f "$REVIEW" ]; then
      fail "agent is dp-fixer but no review found at ${REVIEW#"$ROOT"/}"
    fi
    ;;
  *) fail "unknown agent '$AGENT' — must be dp-implementer, dp-fixer, or dp-test-writer" ;;
esac

# soft check: warn, do not fail, if a knowledge_ref points at a file that doesn't exist —
# a stale reference is a card-authoring bug, not grounds to block delegation
while IFS= read -r kr; do
  [ -n "$kr" ] || continue
  if [ ! -f "$ROOT/$kr" ]; then
    dp_warn "knowledge_refs entry '$kr' does not exist"
  fi
done < <(dp_fm_list "$CARD" knowledge_refs)

if [ "$FAIL" = "1" ]; then
  dp_err "validation failed for $TASK — nothing was changed"
  exit 1
fi
dp_ok "card validated"

# ---------------------------------------------------------- mutate, only past this point
dp_set_fm "$CARD" attempt "$((ATTEMPT + 1))"
dp_set_fm "$CARD" status in_progress
mkdir -p "$FEATURE_DIR/reports"
mkdir -p "$ROOT/.claude"

# isolation:"worktree" checks out a real, separate git worktree from a commit — it does
# NOT see uncommitted changes in this working tree. Commit everything pending outside
# .claude/ (this card's own status/attempt bump above, plus any other planning artifacts
# the lead has not yet committed) so the executor's worktree actually contains the card
# it is about to be handed. .claude/ itself is excluded on purpose: dp-active-task.json is
# written below, after this commit, and must never be committed — it is transient local
# process state, not a repo artifact.
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  if [ -n "$(git -C "$ROOT" status --porcelain -- ':!.claude' 2>/dev/null)" ]; then
    git -C "$ROOT" add -A -- ':!.claude'
    git -C "$ROOT" commit -q -m "$TASK: prepare for delegation"
    dp_ok "committed pending changes so the executor's worktree can see them"
  fi
else
  dp_warn "not a git repository — isolation:\"worktree\" will not work; delegate without it"
fi

AP_JSON="$(printf '%s\n' "${ALLOWED_PATHS[@]}" | jq -R . | jq -s .)"
jq -n \
  --arg task_id "$TASK" --arg feature "$FEATURE" --arg report_path "$REPORT_REL" \
  --arg agent "$AGENT" --arg delegated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson allowed_paths "$AP_JSON" \
  '{task_id:$task_id, feature:$feature, agent:$agent, allowed_paths:$allowed_paths, report_path:$report_path, delegated_at:$delegated_at}' \
  > "$ROOT/.claude/dp-active-task.json"

echo
dp_ok "$TASK ready — attempt $((ATTEMPT + 1))/$MAX_ATTEMPTS, agent $AGENT"
printf 'card=%s\n'   "${CARD#"$ROOT"/}"
printf 'report=%s\n' "$REPORT_REL"
printf 'agent=%s\n'  "$AGENT"
