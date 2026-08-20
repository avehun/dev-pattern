#!/usr/bin/env bash
# Shared helpers for dev-pattern scripts.
# Source this, do not execute it:  . "$(dirname "$0")/lib/common.sh"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'
  C_BLU=$'\033[34m'; C_DIM=$'\033[2m'; C_BLD=$'\033[1m'; C_OFF=$'\033[0m'
else
  C_RED=''; C_GRN=''; C_YEL=''; C_BLU=''; C_DIM=''; C_BLD=''; C_OFF=''
fi

dp_info() { printf '%s\n' "${C_BLU}==>${C_OFF} $*"; }
dp_ok()   { printf '%s\n' "${C_GRN}  ok${C_OFF} $*"; }
dp_warn() { printf '%s\n' "${C_YEL}  ! ${C_OFF} $*" >&2; }
dp_err()  { printf '%s\n' "${C_RED}  x ${C_OFF} $*" >&2; }
dp_die()  { dp_err "$*"; exit 1; }
dp_dim()  { printf '%s\n' "${C_DIM}$*${C_OFF}"; }

# dp_root — directory of the dev-pattern repo itself (the parent of scripts/)
dp_root() { cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd; }

# dp_frontmatter FILE — print the YAML frontmatter block (without the --- fences)
dp_frontmatter() {
  awk 'NR==1 && $0 != "---" { exit }
       NR==1 { next }
       /^---[[:space:]]*$/ { exit }
       { print }' "$1" 2>/dev/null
}

# dp_fm FILE KEY — print a scalar frontmatter value (quotes and trailing comments stripped)
dp_fm() {
  dp_frontmatter "$1" | awk -v k="$2" '
    $0 ~ "^"k":" {
      sub(/[[:space:]]+#.*$/, "")
      sub("^"k":[[:space:]]*", "")
      gsub(/^"|"$/, "")
      gsub(/^'\''|'\''$/, "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }'
}

# dp_fm_list FILE KEY — print list items, one per line.
# Handles both  key: [a, b]  and the block form with "  - a" lines.
dp_fm_list() {
  dp_frontmatter "$1" | awk -v k="$2" '
    $0 ~ "^"k":" {
      line = $0
      sub(/[[:space:]]+#.*$/, "", line)
      sub("^"k":[[:space:]]*", "", line)
      if (line ~ /^\[/) {                       # inline array
        gsub(/^\[|\][[:space:]]*$/, "", line)
        n = split(line, a, /,/)
        for (i = 1; i <= n; i++) {
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", a[i])
          gsub(/^"|"$/, "", a[i])
          if (a[i] != "") print a[i]
        }
        exit
      }
      if (line != "") { print line; exit }      # scalar written where a list was expected
      block = 1; next                           # block form follows
    }
    block && /^[[:space:]]*-[[:space:]]*/ {
      item = $0
      sub(/[[:space:]]+#.*$/, "", item)
      sub(/^[[:space:]]*-[[:space:]]*/, "", item)
      gsub(/^"|"$/, "", item)
      sub(/[[:space:]]+$/, "", item)
      if (item != "") print item
      next
    }
    block && /^[^[:space:]]/ { exit }'
}

# dp_set_fm FILE KEY VALUE — replace a scalar value inside the frontmatter only
dp_set_fm() {
  local file="$1" key="$2" value="$3" tmp
  tmp="$(mktemp)"
  awk -v k="$key" -v v="$value" '
    NR==1 && $0=="---" { infm=1; print; next }
    infm && /^---[[:space:]]*$/ { infm=0; print; next }
    infm && $0 ~ "^"k":" {
      comment = ""
      if (match($0, /[[:space:]]+#.*$/)) comment = substr($0, RSTART, RLENGTH)
      print k": "v comment
      done_it = 1
      next
    }
    { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# dp_find_card PROJECT_ROOT TASK_ID — echo the path to a task card, or fail
dp_find_card() {
  local root="$1" id="$2" hit
  hit="$(find "$root/docs/specs" -type f -path '*/tasks/*' -name "$id.md" 2>/dev/null | head -1)"
  [ -n "$hit" ] || return 1
  printf '%s\n' "$hit"
}

# dp_feature_dir CARD_PATH — the docs/specs/NNN-slug directory owning a card
dp_feature_dir() { dirname "$(dirname "$1")"; }

# dp_require_cmd NAME HINT
dp_require_cmd() {
  command -v "$1" >/dev/null 2>&1 || dp_die "'$1' is not installed. $2"
}

# dp_confirm PROMPT — returns 0 on yes; auto-yes when DP_YES=1
dp_confirm() {
  [ "${DP_YES:-0}" = "1" ] && return 0
  local reply
  printf '%s [y/N] ' "$1"
  read -r reply </dev/tty || return 1
  case "$reply" in [yY]*) return 0 ;; *) return 1 ;; esac
}
