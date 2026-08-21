#!/usr/bin/env bash
# Hand one task card to opencode.
#
#   bash scripts/delegate.sh <T-XXX> [options]
#
#   --dir PATH        project root (default: current directory)
#   --agent NAME      override the card's agent (implementer | fixer | test-writer)
#   --model M         override the card's model, e.g. opencode/big-pickle
#   --review          also attach the review file (use with --agent fixer)
#   --auto            apply edits without asking (deny rules still apply); required
#                     when there is no TTY, or opencode blocks forever on approval
#   --worktree        run in an isolated git worktree under .worktrees/<T-XXX>
#   --no-branch       do not create a branch; run on the current one
#   --dry-run         print the command and validation result, change nothing
#   --force           delegate even if validation says not to
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

TASK=""; ROOT="."; AGENT=""; MODEL=""; AUTO=0; WORKTREE=0
NO_BRANCH=0; DRY=0; FORCE=0; WITH_REVIEW=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)       ROOT="$2"; shift ;;
    --agent)     AGENT="$2"; shift ;;
    --model)     MODEL="$2"; shift ;;
    --review)    WITH_REVIEW=1 ;;
    --auto)      AUTO=1 ;;
    --worktree)  WORKTREE=1 ;;
    --no-branch) NO_BRANCH=1 ;;
    --dry-run)   DRY=1 ;;
    --force)     FORCE=1 ;;
    -h|--help)   sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)          dp_die "unknown option: $1" ;;
    *)           TASK="$1" ;;
  esac
  shift
done

[ -n "$TASK" ] || dp_die "usage: delegate.sh <T-XXX> [--dry-run]"
ROOT="$(cd "$ROOT" && pwd)"

CARD="$(dp_find_card "$ROOT" "$TASK")" || dp_die "no task card found for $TASK under $ROOT/docs/specs/*/tasks/"
FEATURE_DIR="$(dp_feature_dir "$CARD")"
FEATURE="$(basename "$FEATURE_DIR")"
REPORT="$FEATURE_DIR/reports/$TASK.md"
REVIEW="$FEATURE_DIR/reviews/$TASK.md"

STATUS="$(dp_fm "$CARD" status)"
ATTEMPT="$(dp_fm "$CARD" attempt)"; ATTEMPT="${ATTEMPT:-0}"
VERIFY="$(dp_fm "$CARD" verify)"
if [ -z "$AGENT" ]; then AGENT="$(dp_fm "$CARD" agent)"; fi
AGENT="${AGENT:-implementer}"
if [ -z "$MODEL" ]; then MODEL="$(dp_fm "$CARD" model)"; fi

dp_info "Task ${C_BLD}$TASK${C_OFF}  ($FEATURE)"
printf '    card    %s\n' "${CARD#"$ROOT"/}"
printf '    agent   %s\n' "$AGENT"
printf '    model   %s\n' "${MODEL:-<opencode default>}"
printf '    status  %s (attempt %s)\n' "$STATUS" "$ATTEMPT"
printf '    policy  autonomy: %s\n' "$(dp_autonomy "$ROOT")"

# ---------------------------------------------------------------- policy
AUTONOMY="$(dp_autonomy "$ROOT")"
MAX_ATTEMPTS="$(dp_max_attempts "$ROOT")"

if [ "$AUTONOMY" = "manual" ] && [ "$AUTO" = "1" ] && [ "$FORCE" = "0" ]; then
  dp_die "constitution says 'autonomy: manual' but --auto was given.
        In manual mode the user watches every edit opencode proposes.
        Change the Delegation policy in docs/constitution.md, or pass --force."
fi

# ---------------------------------------------------------------- validation
FAIL=0
fail() { dp_err "$1"; FAIL=1; }

case "$STATUS" in
  todo|changes_requested|blocked) ;;
  in_progress) dp_warn "card is already in_progress — a previous run may not have finished" ;;
  in_review)   fail "card is in_review; run /dp:review $TASK first" ;;
  done)        fail "card is already done" ;;
  *)           fail "unknown status: '$STATUS'" ;;
esac

[ -n "$VERIFY" ] || fail "card has no 'verify' command — the executor cannot know when it is finished"

if [ -z "$(dp_fm_list "$CARD" allowed_paths)" ]; then
  fail "card has no 'allowed_paths' — the executor would be unbounded"
fi

while IFS= read -r dep; do
  [ -n "$dep" ] || continue
  depcard="$(dp_find_card "$ROOT" "$dep")" || { fail "depends_on $dep — no such card"; continue; }
  depstatus="$(dp_fm "$depcard" status)"
  [ "$depstatus" = "done" ] || fail "depends_on $dep is '$depstatus', not 'done'"
done < <(dp_fm_list "$CARD" depends_on)

if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ] 2>/dev/null; then
  fail "attempt is $ATTEMPT of $MAX_ATTEMPTS — escalate instead: split the card, rewrite its Context, or implement it yourself"
fi

# ignore HTML comments — authoring notes are allowed to mention what not to write
CARD_BODY="$(sed 's/<!--.*-->//g' "$CARD" | awk '/<!--/{c=1} !c{print} /-->/{c=0}')"
if printf '%s' "$CARD_BODY" | grep -qiE '\bsee (plan|spec|architecture)\.md\b|explore the (codebase|repo)'; then
  dp_warn "card tells the executor to look elsewhere for context — free models will fail on this"
fi

if [ "$WITH_REVIEW" = "1" ] && [ ! -f "$REVIEW" ]; then
  fail "--review given but $REVIEW does not exist"
fi

if [ "$FAIL" = "1" ]; then
  if [ "$FORCE" = "1" ]; then
    dp_warn "validation failed — continuing because of --force"
  else
    dp_die "validation failed; fix the card (or pass --force)"
  fi
else
  dp_ok "card validated"
fi

# ---------------------------------------------------------------- workspace
RUNDIR="$ROOT"
BRANCH="task/$TASK"
IN_GIT=0
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then IN_GIT=1; fi

if [ "$IN_GIT" = "0" ]; then
  dp_warn "not a git repository — the executor's changes will not be isolated and review has no diff"
elif [ "$NO_BRANCH" = "1" ]; then
  dp_dim "    branch  <current> (--no-branch)"
elif [ "$WORKTREE" = "1" ]; then
  RUNDIR="$ROOT/.worktrees/$TASK"
  if [ "$DRY" = "0" ]; then
    if [ -d "$RUNDIR" ]; then
      dp_dim "    reusing worktree $RUNDIR"
    else
      git -C "$ROOT" worktree add -b "$BRANCH" "$RUNDIR" >/dev/null 2>&1 \
        || git -C "$ROOT" worktree add "$RUNDIR" "$BRANCH" >/dev/null
      dp_ok "worktree .worktrees/$TASK on $BRANCH"
    fi
  else
    dp_dim "    worktree .worktrees/$TASK on $BRANCH (would be created)"
  fi
else
  if [ "$DRY" = "0" ]; then
    if git -C "$ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
      git -C "$ROOT" switch "$BRANCH" >/dev/null 2>&1 || dp_die "cannot switch to $BRANCH"
    else
      git -C "$ROOT" switch -c "$BRANCH" >/dev/null 2>&1 || dp_die "cannot create $BRANCH (uncommitted changes?)"
    fi
    dp_ok "on branch $BRANCH"
  else
    dp_dim "    branch  $BRANCH (would be created)"
  fi
fi

# ---------------------------------------------------------------- the prompt
CARD_REL="${CARD#"$ROOT"/}"
REPORT_REL="${REPORT#"$ROOT"/}"
REVIEW_REL="${REVIEW#"$ROOT"/}"

if [ "$WITH_REVIEW" = "1" ]; then
  PROMPT="Rework task $TASK.

The task card is $CARD_REL and the review with the findings is $REVIEW_REL (both attached).

Fix ONLY the numbered findings in the review. Do not change anything else.
Stay inside the card's allowed_paths. Do not add dependencies. Do not run git.
Then run: $VERIFY
Repeat until it exits 0, and run the quality gates in docs/constitution.md.
Finally append an '## Attempt' section to $REPORT_REL saying what you changed for each
finding, with file and line. Then stop."
else
  PROMPT="Implement task $TASK.

The task card is $CARD_REL (attached). Read all of it before you touch anything.

Change only the files in the card's allowed_paths. Do not add, remove, or upgrade any
dependency. Do not edit anything under docs/ except your report. Do not run git.
Follow the card's Step-by-step in order, write the tests it asks for, then run:
  $VERIFY
Repeat until it exits 0, then run the quality gates in docs/constitution.md.

Write your report to $REPORT_REL in the format described in AGENTS.md, including the real
output and exit code of the verify command. If the card is ambiguous or you cannot finish
inside allowed_paths, stop after two attempts and write the report with outcome: blocked.
Then stop — do not start another task."
fi

CMD=(opencode run --dir "$RUNDIR" --agent "$AGENT")
if [ -n "$MODEL" ]; then CMD+=(--model "$MODEL"); fi
if [ "$AUTO" = "1" ]; then CMD+=(--auto); fi
CMD+=(-f "$CARD")
if [ "$WITH_REVIEW" = "1" ]; then CMD+=(-f "$REVIEW"); fi
CMD+=(--title "$TASK $(dp_fm "$CARD" title)")
CMD+=("$PROMPT")

if [ "$DRY" = "1" ]; then
  echo
  dp_info "Command (dry run — nothing was changed):"
  echo
  printf '%q ' "${CMD[@]}"
  echo; echo
  dp_dim "  Run it yourself, or re-run this script without --dry-run."
  exit 0
fi

if [ ! -t 0 ] && [ "$AUTO" = "0" ]; then
  dp_die "no TTY and --auto was not given — opencode would block forever waiting for
        someone to approve each edit. Pass --auto (the deny rules in opencode.json still
        apply), or run this command in a terminal yourself."
fi

dp_require_cmd opencode "Install it from https://opencode.ai, then run: opencode auth login"

# ---------------------------------------------------------------- run
mkdir -p "$FEATURE_DIR/reports"
dp_set_fm "$CARD" status in_progress
dp_set_fm "$CARD" attempt "$((ATTEMPT + 1))"

echo
dp_info "Running opencode (agent: $AGENT)…"
echo
set +e
"${CMD[@]}"
RC=$?
set -e
echo

if [ "$RC" -ne 0 ]; then
  dp_set_fm "$CARD" status blocked
  dp_die "opencode exited with code $RC — card marked 'blocked'"
fi

dp_set_fm "$CARD" status in_review
dp_ok "opencode finished; card is now 'in_review'"

if [ -f "$REPORT" ]; then
  OUTCOME="$(dp_fm "$REPORT" outcome)"
  dp_ok "report written: ${REPORT_REL}  (outcome: ${OUTCOME:-unset})"
else
  dp_warn "no report at $REPORT_REL — the executor skipped step 7"
fi

if [ "$IN_GIT" = "1" ]; then
  echo
  dp_info "Changed files:"
  git -C "$RUNDIR" --no-pager diff --stat || true
  git -C "$RUNDIR" --no-pager status --short || true
fi

echo
dp_dim "  Next: /dp:review $TASK in Claude Code."
