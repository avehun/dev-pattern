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

# The plugin is active in a project only after setup created the knowledge index.
dp_active() {
  [ -f "$(dp_kb_dir)/INDEX.md" ]
}

# Git tree id of the whole working tree as it is on disk right now: tracked changes,
# untracked files, deletions; .gitignore respected. Built in a throwaway index, so the
# real index and the working tree are untouched (it only adds unreachable objects that
# git gc removes).
dp_worktree_tree() {
  local sd tmp tree
  sd="$(dp_state_dir)" || return 1
  mkdir -p "$sd" || return 1
  tmp="$sd/index.tmp.$$"
  cp "$(git rev-parse --path-format=absolute --git-path index)" "$tmp" 2>/dev/null || rm -f "$tmp"
  tree="$(cd "$(dp_root)" && GIT_INDEX_FILE="$tmp" git add -A . >/dev/null 2>&1 \
          && GIT_INDEX_FILE="$tmp" git write-tree 2>/dev/null)"
  rm -f "$tmp"
  [ -n "$tree" ] || return 1
  printf '%s\n' "$tree"
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
