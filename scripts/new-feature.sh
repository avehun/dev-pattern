#!/usr/bin/env bash
# Create a feature folder from the artifact templates.
#
#   bash scripts/new-feature.sh <slug> [--dir PROJECT_ROOT] [--title "Human title"]
#
# Creates docs/specs/NNN-slug/ with spec.md, research.md, plan.md, data-model.md,
# contracts/, quickstart.md, checklist.md, tasks.md and the tasks/ reports/ reviews/ dirs.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

SLUG=""
ROOT="."
TITLE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)     ROOT="$2"; shift ;;
    --title)   TITLE="$2"; shift ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        dp_die "unknown option: $1" ;;
    *)         SLUG="$1" ;;
  esac
  shift
done

[ -n "$SLUG" ] || dp_die "usage: new-feature.sh <slug> [--dir PROJECT_ROOT]"
ROOT="$(cd "$ROOT" && pwd)"

# normalise the slug: lowercase, non-alphanumerics to dashes
SLUG="$(printf '%s' "$SLUG" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
[ -n "$SLUG" ] || dp_die "slug is empty after normalisation"
[ -n "$TITLE" ] || TITLE="$(printf '%s' "$SLUG" | tr '-' ' ')"

TPL="$ROOT/docs/.templates"
[ -d "$TPL" ] || TPL="$(dp_root)/templates"
[ -d "$TPL" ] || dp_die "no templates found (looked in $ROOT/docs/.templates)"

SPECS="$ROOT/docs/specs"
mkdir -p "$SPECS"

# next free three-digit number
NUM=1
while [ -n "$(find "$SPECS" -maxdepth 1 -type d -name "$(printf '%03d' "$NUM")-*" 2>/dev/null)" ]; do
  NUM=$((NUM + 1))
done
ID="$(printf '%03d' "$NUM")"
FEATURE="$ID-$SLUG"
DIR="$SPECS/$FEATURE"

if [ -e "$DIR" ]; then dp_die "already exists: $DIR"; fi

TODAY="$(date +%Y-%m-%d)"
mkdir -p "$DIR/contracts" "$DIR/tasks" "$DIR/reports" "$DIR/reviews"

render() {  # render TEMPLATE_NAME DEST
  sed -e "s|001-feature-slug|$FEATURE|g" \
      -e "s|{{TITLE}}|$TITLE|g" \
      -e "s|YYYY-MM-DD|$TODAY|g" \
      "$TPL/$1" > "$DIR/$2"
}

render spec.md        spec.md
render research.md    research.md
render plan.md        plan.md
render data-model.md  data-model.md
render quickstart.md  quickstart.md
render checklist.md   checklist.md
render tasks.md       tasks.md
render contracts/README.md contracts/README.md

# a placeholder so the empty dirs survive git
for d in tasks reports reviews; do
  [ -e "$DIR/$d/.gitkeep" ] || : > "$DIR/$d/.gitkeep"
done

dp_ok "Created ${C_BLD}docs/specs/$FEATURE${C_OFF}"
echo
printf '  %s\n' "docs/specs/$FEATURE/spec.md          <- fill this in first (what and why)"
printf '  %s\n' "docs/specs/$FEATURE/research.md      <- options and prior art"
printf '  %s\n' "docs/specs/$FEATURE/plan.md          <- how; after the spec is ready"
printf '  %s\n' "docs/specs/$FEATURE/tasks/           <- task cards go here"
echo
dp_dim "  Next: /dp:spec $SLUG in Claude Code, or edit spec.md directly."
printf '%s\n' "$DIR"
