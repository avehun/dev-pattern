#!/usr/bin/env bash
# Stop: block the end of a turn while this session changed code but no documentation.
#
#   documentation   *.md, *.mdx, *.rst, docs/**, doc/** — except docs/dp/plans/**
#   ignored         lockfiles, .claude/**, .gitignore
#   code            everything else
#
# Changes are measured against the working-tree state recorded at session start, so work
# that was already uncommitted before the session does not count. A waiver written by
# `dp-docs-waive` for the exact current tree lets the turn end. After 3 blocks in a row the
# hook lets go and warns the user, so a stuck session can never loop forever.
# Fail-open: any error exits 0.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh" || exit 0
command -v jq >/dev/null 2>&1 || exit 0

MAX_BLOCKS=3

IN="$(cat)"
CWD="$(jq -r '.cwd // empty' <<<"$IN" 2>/dev/null)"
SID="$(jq -r '.session_id // empty' <<<"$IN" 2>/dev/null)"
if [ -n "$CWD" ]; then cd "$CWD" 2>/dev/null || exit 0; fi
dp_active || exit 0
[ -n "$SID" ] || exit 0
SD="$(dp_state_dir)" || exit 0
BASE="$(cat "$SD/sessions/$SID.base" 2>/dev/null)" || exit 0
[ -n "$BASE" ] || exit 0
NOW="$(dp_worktree_tree)" || exit 0
COUNT_FILE="$SD/sessions/$SID.blocks"

pass() { rm -f "$COUNT_FILE"; exit 0; }

if [ "$BASE" = "$NOW" ]; then pass; fi

code=() docs=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in
    docs/dp/plans/*) continue ;;
    *.md|*.mdx|*.rst|docs/*|doc/*) docs=1; continue ;;
    .claude/*|.gitignore|*.lock|package-lock.json|pnpm-lock.yaml|go.sum|bun.lockb) continue ;;
  esac
  code+=("$f")
done < <(git diff --name-only "$BASE" "$NOW" 2>/dev/null)

if [ "${#code[@]}" -eq 0 ] || [ "$docs" = "1" ]; then pass; fi

WAIVER="$SD/waivers/$NOW"
if [ -f "$WAIVER" ]; then
  rm -f "$COUNT_FILE"
  jq -cn --arg r "$(cat "$WAIVER")" '{systemMessage: ("dev-pattern: docs update waived — " + $r)}'
  exit 0
fi

n=$(( $(cat "$COUNT_FILE" 2>/dev/null || echo 0) + 1 ))
if [ "$n" -gt "$MAX_BLOCKS" ]; then
  rm -f "$COUNT_FILE"
  jq -cn --arg m "dev-pattern: code changed but no docs were updated, and Claude did not resolve it after $MAX_BLOCKS reminders. Check the docs yourself." \
    '{systemMessage: $m}'
  exit 0
fi
printf '%s\n' "$n" > "$COUNT_FILE"

list="$(printf -- '- %s\n' "${code[@]:0:15}")"
if [ "${#code[@]}" -gt 15 ]; then list="$list
- … and $(( ${#code[@]} - 15 )) more"; fi

jq -cn --arg l "$list" '{decision: "block", reason: ("dev-pattern: this session changed code but no documentation:\n" + $l + "\n\nBefore finishing: update the project docs this change affects and the knowledge modules in docs/dp/knowledge/ that cover these files (`dp-kb-stale` lists stale ones). If no doc truly needs a change, run `dp-docs-waive \"<reason>\"` and tell the user the reason.")}'
exit 0
