#!/usr/bin/env bash
# SessionStart: put the rules and the knowledge index into Claude's context, and record the
# working-tree state the Stop hook compares against. Silent in projects without setup.
# Fail-open: any error exits 0 with no output.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh" || exit 0
command -v jq >/dev/null 2>&1 || exit 0

IN="$(cat)"
CWD="$(jq -r '.cwd // empty' <<<"$IN" 2>/dev/null)"
SID="$(jq -r '.session_id // empty' <<<"$IN" 2>/dev/null)"
if [ -n "$CWD" ]; then cd "$CWD" 2>/dev/null || exit 0; fi
dp_active || exit 0

# Baseline for the Stop hook — once per session; resume and compact keep the original.
if SD="$(dp_state_dir)" && [ -n "$SID" ]; then
  mkdir -p "$SD/sessions" 2>/dev/null
  if [ ! -f "$SD/sessions/$SID.base" ]; then
    dp_worktree_tree > "$SD/sessions/$SID.base" 2>/dev/null || rm -f "$SD/sessions/$SID.base"
  fi
fi

# Keep the whole context under Claude Code's 10,000-character limit for hook output.
RULES="$(cat "$(dirname "${BASH_SOURCE[0]}")/../rules.md")" || exit 0
INDEX="$(cat "$(dp_kb_dir)/INDEX.md")"
BUDGET=$(( 9500 - ${#RULES} ))
if [ "${#INDEX}" -gt "$BUDGET" ]; then
  INDEX="${INDEX:0:$BUDGET}
…(index truncated: read docs/dp/knowledge/INDEX.md for the rest, and shorten it)"
fi

CTX="$RULES

## Knowledge index (docs/dp/knowledge/INDEX.md)

$INDEX"
jq -cn --arg c "$CTX" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
exit 0
