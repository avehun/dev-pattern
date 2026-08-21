#!/usr/bin/env bash
# Print the state of every feature and task card.
#
#   bash scripts/status.sh [--dir PROJECT_ROOT] [--plain]
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

ROOT="."
while [ $# -gt 0 ]; do
  case "$1" in
    --dir)     ROOT="$2"; shift ;;
    --plain)   NO_COLOR=1 ;;
    -h|--help) sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)         ROOT="$1" ;;
  esac
  shift
done
ROOT="$(cd "$ROOT" && pwd)"
SPECS="$ROOT/docs/specs"

if dp_not_onboarded "$ROOT"; then
  printf '%sproject not onboarded%s — docs/constitution.md / docs/stack.md still hold\n' "$C_RED" "$C_OFF"
  printf '  template placeholders. Nothing downstream is trustworthy until they are filled\n'
  printf '  in: run /dp:onboard in Claude Code, or just say what you want and the lead will.\n\n'
else
  printf '%sautonomy:%s %s\n' "$C_DIM" "$C_OFF" "$(dp_autonomy "$ROOT")"
fi

if [ ! -d "$SPECS" ]; then
  echo "no docs/specs/ — nothing to report"
  exit 0
fi

READY=(); REVIEW=(); REWORK=(); STUCK=()

status_of() { dp_fm "$1" status; }

for feature in $(find "$SPECS" -mindepth 1 -maxdepth 1 -type d | sort); do
  name="$(basename "$feature")"
  spec="$feature/spec.md"
  spec_status="unknown"
  spec_title=""
  if [ -f "$spec" ]; then
    spec_status="$(dp_fm "$spec" status)"
    spec_title="$(dp_fm "$spec" title)"
  fi

  cards=()
  while IFS= read -r c; do cards+=("$c"); done < <(find "$feature/tasks" -name 'T-*.md' 2>/dev/null | sort)

  total="${#cards[@]}"
  done_n=0
  for c in "${cards[@]}"; do
    [ "$(status_of "$c")" = "done" ] && done_n=$((done_n + 1))
  done

  printf '\n%s%s%s  %s  [spec: %s]  %s/%s tasks done\n' \
    "$C_BLD" "$name" "$C_OFF" "$spec_title" "${spec_status:-unknown}" "$done_n" "$total"

  for c in "${cards[@]}"; do
    id="$(dp_fm "$c" id)"; id="${id:-$(basename "${c%.md}")}"
    st="$(status_of "$c")"
    title="$(dp_fm "$c" title)"
    att="$(dp_fm "$c" attempt)"
    deps="$(dp_fm_list "$c" depends_on | tr '\n' ' ')"

    color="$C_DIM"
    case "$st" in
      todo)               color="$C_OFF" ;;
      in_progress)        color="$C_BLU" ;;
      in_review)          color="$C_YEL" ;;
      changes_requested)  color="$C_YEL" ;;
      blocked|escalated)  color="$C_RED" ;;
      done)               color="$C_GRN" ;;
    esac

    printf '  %s%-18s%s %-10s %s%s\n' "$color" "$st" "$C_OFF" "$id" "$title" \
      "$([ -n "$deps" ] && printf ' %s(needs: %s)%s' "$C_DIM" "${deps% }" "$C_OFF")"

    # is it ready to delegate?
    if [ "$st" = "todo" ]; then
      blocked=0
      for d in $deps; do
        dc="$(dp_find_card "$ROOT" "$d" 2>/dev/null)" || { blocked=1; continue; }
        [ "$(status_of "$dc")" = "done" ] || blocked=1
      done
      [ "$blocked" = "0" ] && READY+=("$id")
    fi
    case "$st" in
      in_review)          REVIEW+=("$id") ;;
      changes_requested)  REWORK+=("$id (attempt ${att:-?})") ;;
      blocked|escalated)  STUCK+=("$id [$st]") ;;
    esac
  done
done

echo
printf '%sReady to delegate:%s %s\n'  "$C_GRN" "$C_OFF" "$([ "${#READY[@]}"  -gt 0 ] && printf '%s ' "${READY[@]}"  || echo '-')"
printf '%sAwaiting review:%s   %s\n'  "$C_YEL" "$C_OFF" "$([ "${#REVIEW[@]}" -gt 0 ] && printf '%s ' "${REVIEW[@]}" || echo '-')"
printf '%sNeeds rework:%s      %s\n'  "$C_YEL" "$C_OFF" "$([ "${#REWORK[@]}" -gt 0 ] && printf '%s; ' "${REWORK[@]}" || echo '-')"
printf '%sBlocked/escalated:%s %s\n'  "$C_RED" "$C_OFF" "$([ "${#STUCK[@]}"  -gt 0 ] && printf '%s; ' "${STUCK[@]}"  || echo '-')"
