# Shared helpers for dev-pattern scripts. Source it; do not execute it.

# Project root: the git top level, or the current directory outside git.
dp_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

# Knowledge base directory (absolute). DP_KB_DIR overrides, relative to the root.
dp_kb_dir() {
  printf '%s/%s\n' "$(dp_root)" "${DP_KB_DIR:-docs/dp/knowledge}"
}

# Per-repo private state, never committed: <git dir>/dp
dp_state_dir() {
  local gd
  gd="$(git rev-parse --absolute-git-dir 2>/dev/null)" || return 1
  printf '%s/dp\n' "$gd"
}

# Print the value of a scalar frontmatter key: dp_fm_get FILE KEY
dp_fm_get() {
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---"  { exit }
    NR > 1 {
      if (index($0, key ":") == 1) {
        v = substr($0, length(key) + 2)
        sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
        print v; exit
      }
    }' "$1"
}

# Print the items of a list frontmatter key, one per line: dp_fm_list FILE KEY
# Accepts both "key: [a, b]" and a block list of "  - a" lines.
dp_fm_list() {
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---"  { exit }
    NR > 1 {
      if (inlist) {
        if ($0 ~ /^[ \t]*-[ \t]+/) { v = $0; sub(/^[ \t]*-[ \t]+/, "", v); sub(/[ \t]+$/, "", v); print v; next }
        inlist = 0
      }
      if (index($0, key ":") == 1) {
        v = substr($0, length(key) + 2); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
        if (v == "") { inlist = 1; next }
        gsub(/^\[|\]$/, "", v); n = split(v, parts, ",")
        for (i = 1; i <= n; i++) { p = parts[i]; sub(/^[ \t]+/, "", p); sub(/[ \t]+$/, "", p); if (p != "") print p }
      }
    }' "$1"
}
