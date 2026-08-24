#!/usr/bin/env bash
# Set a task card's status, after validating it's a legal value.
# Reused by /dp:delegate, /dp:review, /dp:accept, and prepare-delegation.sh.
#
#   bash scripts/set-status.sh <T-XXX> <status> [--dir PROJECT_ROOT] [--reason "..."]
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

TASK=""; STATUS=""; ROOT="."; REASON=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dir)     ROOT="$2"; shift ;;
    --reason)  REASON="$2"; shift ;;
    -h|--help) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        dp_die "unknown option: $1" ;;
    *)         if [ -z "$TASK" ]; then TASK="$1"; else STATUS="$1"; fi ;;
  esac
  shift
done
if [ -z "$TASK" ] || [ -z "$STATUS" ]; then
  dp_die "usage: set-status.sh <T-XXX> <status> [--reason '...']"
fi

case "$STATUS" in
  todo|in_progress|in_review|changes_requested|done|blocked|escalated) ;;
  *) dp_die "unknown status '$STATUS' — one of: todo in_progress in_review changes_requested done blocked escalated" ;;
esac

ROOT="$(cd "$ROOT" && pwd)"
CARD="$(dp_find_card "$ROOT" "$TASK")" || dp_die "no task card found for $TASK"

OLD="$(dp_fm "$CARD" status)"
dp_set_fm "$CARD" status "$STATUS"
dp_ok "$TASK: $OLD -> $STATUS${REASON:+  ($REASON)}"
