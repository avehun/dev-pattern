#!/usr/bin/env bash
# Install the dev-pattern workflow into a project.
#
#   bash scripts/init.sh [TARGET_DIR] [--force] [--dry-run]
#
# Existing files are never overwritten. When a file already exists, the incoming
# version is written next to it as <name>.dev-pattern.<ext> and reported, so you can
# merge it by hand. --force overwrites instead.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="."
FORCE=0
DRY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --force)   FORCE=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        dp_die "unknown option: $1" ;;
    *)         TARGET="$1" ;;
  esac
  shift
done

[ -d "$TARGET" ] || dp_die "target directory does not exist: $TARGET"
TARGET="$(cd "$TARGET" && pwd)"
[ "$TARGET" != "$SRC" ] || dp_die "refusing to install dev-pattern into itself"

MERGE_LIST=()

# place SRC_FILE at REL_PATH inside the target
place() {
  local src="$1" rel="$2"
  local dst="$TARGET/$rel"
  if [ -e "$dst" ] && [ "$FORCE" = "0" ]; then
    local alt base ext
    base="${rel%.*}"; ext="${rel##*.}"
    if [ "$base" = "$rel" ]; then alt="$rel.dev-pattern"; else alt="$base.dev-pattern.$ext"; fi
    if [ "$DRY" = "1" ]; then
      dp_warn "exists: $rel  -> would write $alt"
    else
      mkdir -p "$(dirname "$TARGET/$alt")"
      cp "$src" "$TARGET/$alt"
      dp_warn "exists: $rel  -> wrote $alt (merge by hand)"
    fi
    MERGE_LIST+=("$rel")
    return
  fi
  if [ "$DRY" = "1" ]; then
    dp_dim "    + $rel"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    dp_dim "    + $rel"
  fi
}

# copy every file under SRC_DIR to REL_DIR, preserving structure
place_tree() {
  local srcdir="$1" reldir="$2"
  local f rel
  while IFS= read -r f; do
    rel="${f#"$srcdir"/}"
    place "$f" "${reldir:+$reldir/}$rel"
  done < <(find "$srcdir" -type f | sort)
}

dp_info "Installing dev-pattern into ${C_BLD}$TARGET${C_OFF}"
if [ "$DRY" = "1" ]; then dp_warn "dry run — nothing will be written"; fi

dp_info "Agent instructions and configuration"
place "$SRC/template/CLAUDE.md"   "CLAUDE.md"
place "$SRC/template/.claude/settings.json" ".claude/settings.json"
place "$SRC/template/.claude/dp-guard.json" ".claude/dp-guard.json"

dp_info "Claude Code commands (the lead)"
place_tree "$SRC/template/.claude/commands" ".claude/commands"

dp_info "Executor subagents (dp-implementer, dp-fixer, dp-test-writer — both lead and executor are Claude Code, on different models)"
place_tree "$SRC/template/.claude/agents" ".claude/agents"

dp_info "Permission hook (enforces the executor's boundaries)"
place "$SRC/template/.claude/hooks/dp-guard.sh" ".claude/hooks/dp-guard.sh"

dp_info "Project documentation skeleton"
place_tree "$SRC/template/docs" "docs"
place "$SRC/templates/constitution.md" "docs/constitution.md"

dp_info "Artifact templates (docs/.templates)"
place_tree "$SRC/templates" "docs/.templates"

dp_info "Workflow scripts"
for s in lib/common.sh new-feature.sh prepare-delegation.sh set-status.sh doctor.sh status.sh; do
  place "$SRC/scripts/$s" "scripts/$s"
done

if [ "$DRY" = "0" ]; then
  mkdir -p "$TARGET/docs/specs" "$TARGET/docs/adr" "$TARGET/docs/knowledge/modules"
  chmod +x "$TARGET"/scripts/*.sh 2>/dev/null || true
  chmod +x "$TARGET"/.claude/hooks/*.sh 2>/dev/null || true
fi

echo
dp_ok "Installed."

if [ "${#MERGE_LIST[@]}" -gt 0 ]; then
  echo
  dp_warn "These files already existed and were written alongside as *.dev-pattern.*:"
  for m in "${MERGE_LIST[@]}"; do printf '        %s\n' "$m"; done
  dp_warn "Merge them by hand, then delete the .dev-pattern copies."
fi

cat <<EOF

${C_BLD}Next step${C_OFF}
  Open Claude Code in this directory and say what you want to build.

  ${C_BLU}claude${C_OFF}
  > I need to add <the thing you want>

  The lead will notice the project is not onboarded yet, read the codebase, ask you what it
  cannot work out on its own, and fill in ${C_BLU}docs/constitution.md${C_OFF}, ${C_BLU}docs/stack.md${C_OFF},
  ${C_BLU}docs/architecture.md${C_OFF}, ${C_BLU}docs/glossary.md${C_OFF} and the initial
  ${C_BLU}docs/knowledge/${C_OFF} entries — then get on with the feature. You never have to edit
  those by hand, and you never have to run a command again. Both roles are Claude Code: the
  lead runs on Opus (pinned in ${C_BLU}.claude/settings.json${C_OFF}), the executor on Sonnet
  (${C_BLU}.claude/agents/dp-implementer.md${C_OFF} and friends) — no separate install, no
  separate login.

${C_DIM}  Optional
    bash scripts/doctor.sh    checks the install; /dp:onboard re-runs the interview${C_OFF}
EOF
